# ADR-004: `AuthNotifier.updateUser()` para sincronizar estado auth tras actualizar perfil

**Estado:** Aceptado  
**Fecha:** 2026-06-02  
**Fase:** Phase 5 — Profile & Settings MVP  
**Tags:** state-management, riverpod, cross-feature, auth, profile, sync

---

## Contexto

`AuthNotifier` mantiene el estado de autenticación (`AuthAuthenticated`, `AuthUnauthenticated`). El `AuthUser` dentro de `AuthAuthenticated` contiene `displayName`. Cuando el usuario actualiza su nombre en `ProfilePage`, `AuthNotifier` no se entera automáticamente — solo lo haría si Firebase re-emite el stream de auth, lo cual no ocurre solo por `updateDisplayName`.

El problema: tras guardar el nombre, `ProfileAvatar` (que lee de `authNotifierProvider`) seguiría mostrando las iniciales del nombre anterior hasta el próximo restart.

La pregunta fue: **¿cómo sincronizar `AuthNotifier` con el `AuthUser` actualizado que retorna `ProfileNotifier`?**

## Decisión

### Método `updateUser(AuthUser)` en `AuthNotifier` + `ref.listen` en `ProfilePage`

```dart
// AuthNotifier — método de sincronización
void updateUser(AuthUser user) {
  state = AuthAuthenticated(user);
}
```

`ProfilePage` escucha el estado de `profileNotifierProvider` y llama a `updateUser` cuando hay éxito:

```dart
ref.listen<ProfileState>(profileNotifierProvider, (_, next) {
  if (next is ProfileUpdated) {
    _nameController.text = next.user.displayName ?? '';
    ref.read(authNotifierProvider.notifier).updateUser(next.user);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil actualizado')),
    );
  }
});
```

La sincronización ocurre en el widget, no en el notifier — `ProfileNotifier` no conoce a `AuthNotifier`.

## Consecuencias

### Positivas

- **Actualización inmediata**: el avatar y cualquier widget que lea `authNotifierProvider` refleja el nombre nuevo en el mismo frame, sin esperar a Firebase ni a un nuevo login.
- **`ProfileNotifier` no acopla a `AuthNotifier`**: la capa de presentación hace la coordinación entre notifiers via `ref.listen`. Los notifiers permanecen independientes y testeables por separado.
- **Método mínimo y explícito**: `updateUser` es una mutación de estado directa — no hay lógica de negocio, solo asignar `AuthAuthenticated(user)`. Cualquier lector del test entiende inmediatamente qué hace.

### Negativas / Trade-offs

- **La sincronización vive en el widget**: si en el futuro se añade otra pantalla que también pueda actualizar el perfil (ej. un onboarding), habrá que recordar añadir el mismo `ref.listen` en esa pantalla también. Alternativa futura: un `ref.listen` en el nivel del router o en un `AppShell` que siempre esté activo.
- **`AuthNotifier` ahora tiene un método que no es auth puro**: `updateUser` es una mutación de estado que viene del dominio de perfil. Si el equipo decide que `AuthNotifier` solo debe reaccionar a eventos Firebase, este método viola esa separación.

## Alternativas consideradas

| Alternativa | Descartada porque |
|---|---|
| `ProfileNotifier` inyecta `AuthNotifier` en su constructor | Crea acoplamiento directo entre notifiers de features distintas; dificulta los tests unitarios |
| Escuchar `authStateChanges()` de Firebase | No emite nuevos eventos solo por `updateDisplayName`; requeriría hacer sign-out y sign-in para actualizar |
| `ref.invalidate(authNotifierProvider)` desde `ProfilePage` | Destruye y recrea el notifier, perdiendo el estado de carga de tareas pendientes y causando un rebuild total |
| `ChangeNotifier` compartido como bus de eventos | Introduce una capa de coordinación global no trivial; overkill para sincronizar un único campo |
