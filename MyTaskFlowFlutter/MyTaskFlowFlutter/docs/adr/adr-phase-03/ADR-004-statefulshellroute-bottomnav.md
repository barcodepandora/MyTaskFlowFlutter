# ADR-004: `StatefulShellRoute.indexedStack` para navegación con BottomNavigationBar

**Estado:** Aceptado  
**Fecha:** 2026-06-01  
**Fase:** Phase 3 — Dashboard & Search/Filter MVP  
**Tags:** navigation, gorouter, shell-route, bottom-nav, state-preservation

---

## Contexto

Phase 3 añade una `BottomNavigationBar` con tres tabs: **Inicio** (`/home`), **Tareas** (`/tasks`) y **Perfil** (`/profile`). Esto introduce tres decisiones de navegación:

1. **¿Cómo integrar la barra con GoRouter** sin romper la lógica de deep links existente (`/tasks/:id/edit`)?
2. **¿Cómo preservar el estado de cada tab** cuando el usuario cambia entre ellos (ej. lista scrolleada, filtro activo)?
3. **¿Dónde vive el `Scaffold` de la barra?** ¿En cada página individualmente, o en un shell compartido?

## Decisión

### `StatefulShellRoute.indexedStack` con `AppShell` como builder

GoRouter provee `StatefulShellRoute.indexedStack`, que mantiene el árbol de widgets de cada branch vivo mientras el usuario navega entre tabs (equivalente a `IndexedStack`), sin recrear el estado al cambiar de tab.

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) =>
      AppShell(navigationShell: navigationShell),
  branches: [
    StatefulShellBranch(routes: [
      GoRoute(path: '/home', builder: (_, _) => const DashboardPage()),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(
        path: '/tasks',
        builder: (_, _) => const TaskListPage(),
        routes: [/* /tasks/create, /tasks/:id, /tasks/:id/edit */],
      ),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(path: '/profile', builder: (_, _) => const ProfilePlaceholderPage()),
    ]),
  ],
),
```

`AppShell` es un `StatelessWidget` que recibe el `StatefulNavigationShell` y lo usa como cuerpo del `Scaffold`, delegando la gestión de índice al propio GoRouter:

```dart
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: const [ /* Inicio, Tareas, Perfil */ ],
      ),
    );
  }
}
```

El parámetro `initialLocation: index == navigationShell.currentIndex` en `goBranch` implementa el comportamiento estándar de iOS/Android: tocar el tab activo navega a la raíz de ese branch (equivalente a pop-to-root).

### Redirección post-login a `/home`

El guard de autenticación en `_RouterNotifier.redirect()` se actualiza:

```dart
if (isAuthenticated && isLoginRoute) return '/home';  // era '/tasks'
```

`/home` es la raíz de la shell autenticada y la pantalla principal de la app.

## Consecuencias

### Positivas

- **Estado preservado entre tabs**: si el usuario scrollea la lista de tareas hasta la mitad y cambia al Dashboard, al volver a Tareas la posición se conserva. `StatefulShellRoute` logra esto sin código adicional.
- **Deep links siguen funcionando**: `/tasks/seed-1/edit` abre directamente el formulario de edición. GoRouter resuelve el branch correcto (el de `/tasks`) y apila las rutas dentro de él. La shell se monta automáticamente alrededor.
- **`AppShell` stateless y testeable**: no tiene estado propio; `navigationShell.currentIndex` actúa como la única fuente de verdad para el tab activo. Los tests de `AppShell` solo necesitan verificar que `goBranch()` se llama con el índice correcto.
- **Separación limpia de responsabilidades**: cada `StatefulShellBranch` encapsula su propia pila de navegación. Las rutas de una branch no interfieren con las otras.

### Negativas / Trade-offs

- **`StatefulShellRoute` es específico de GoRouter**: si en el futuro se migra a otro router (Navigator 2.0 manual, auto_route), la lógica de branch necesita reescribirse. Dado que GoRouter es la elección del proyecto desde Phase 0 ([ADR-003 Phase 0](../adr-phase-00/ADR-003-gorouter-navigation.md)), esto es un riesgo asumido a nivel de proyecto, no de esta fase.
- **`IndexedStack` mantiene todos los tabs en memoria**: las tres subtrees de widgets están activos simultáneamente. Para 3 tabs con UIs ligeras (sin videos, sin streams pesados) el overhead es negligible. Si en fases futuras se añaden tabs con recursos pesados, se podría explorar `lazy` loading de branches.
- **El auth guard redirige a `/home` (no a `/tasks`)**: existe un caso edge donde un deeplink externo a `/tasks` en estado no autenticado pasa por el guard, que redirige a `/login`, y al autenticarse redirige a `/home` en lugar de al `/tasks` original. Para Phase 3 esto es aceptable; se registra como mejora pendiente para Phase 4 con el parámetro `?redirect=` en la URL de login.

## Relación con ADRs previas

- [Phase 0 — ADR-003](../adr-phase-00/ADR-003-gorouter-navigation.md): la elección de GoRouter como router del proyecto habilita `StatefulShellRoute` sin dependencia adicional.
- [Phase 1 — ADR-006](../adr-phase-01/ADR-006-gorouter-auth-guard.md): el guard de autenticación basado en `_RouterNotifier` se mantiene sin cambios; solo se actualiza el destino post-login.

## Alternativas consideradas

| Alternativa | Descartada porque |
|---|---|
| `ShellRoute` simple (sin `Stateful`) | No preserva el estado de los tabs al cambiar; cada tab reconstruye desde cero al volver |
| `IndexedStack` manual en `AppShell` con `GoRouter` plano | Requiere gestión manual del índice activo y pierde el soporte de deep links dentro de cada branch |
| `PageView` con `PageController` | No compatible con deep links ni con el sistema de `GoRouterState`; estado del route queda desincronizado |
| `BottomNavigationBar` en cada página individual | El `Scaffold` se duplica; no hay preservación de estado entre páginas; el `currentIndex` debe sincronizarse manualmente |
