# ADR-002: Flutter Riverpod como solución de estado

- **Estado**: Aceptado
- **Fecha**: 2026-06-01
- **Fase**: 0 — Fundación

## Contexto

La app necesita:
- Estado global de autenticación accesible desde cualquier widget.
- Estado local de features (lista de tareas, filtros, formulario).
- Inyección de dependencias sin un contenedor externo.
- Testabilidad: poder sobreescribir providers en tests sin infraestructura adicional.

Las alternativas evaluadas:

| Solución | Por qué se descartó |
|----------|---------------------|
| **BLoC / flutter_bloc** | Verboso (Events, States, Bloc, BlocProvider, BlocBuilder). Buen estándar corporativo, pero overhead alto para este proyecto. |
| **GetX** | Gestión de estado + routing + DI en un solo paquete. Mezcla responsabilidades, dificulta testing, bindings mágicos. |
| **Provider (package)** | Precursor de Riverpod, sin compile-time safety. Depreciado en proyectos nuevos por el propio autor. |
| **setState / ValueNotifier** | Solo adecuado para estado local trivial; no resuelve DI ni estado global. |
| **Riverpod v2** | **Seleccionado.** |

## Decisión

Se usa **Flutter Riverpod v2** con `NotifierProvider` y `StateNotifier`-style notifiers.

Patrones adoptados:
- `NotifierProvider` para estado mutable con lógica (AuthNotifier, TasksNotifier).
- `Provider` para dependencias puras (repositorios, use cases).
- `ProviderScope` en `main.dart` como raíz de inyección de dependencias.
- Overrides de providers en tests con `ProviderContainer` sin levantar la app completa.

Se prefiere **sin** `riverpod_generator` (anotaciones `@riverpod`) en esta fase para mantener el código explícito y fácil de leer para desarrolladores nuevos al proyecto.

## Consecuencias

**Positivas:**
- DI sin `get_it` ni `injectable`; los providers de Riverpod son el grafo de dependencias.
- Testing limpio: `ProviderContainer(overrides: [...])` sustituye cualquier dependencia.
- Reactive: la UI recompila solo los widgets que leen providers afectados.
- Compile-time safety: Riverpod detecta providers no declarados en tiempo de compilación.

**Negativas / trade-offs:**
- Curva de aprendizaje para desarrolladores que vienen de BLoC o Provider.
- Migrar de Riverpod v2 a v3 (cuando se publique estable) requerirá refactor moderado.
- Sin `riverpod_generator`, los providers se declaran manualmente; mayor boilerplate que la versión con anotaciones.
