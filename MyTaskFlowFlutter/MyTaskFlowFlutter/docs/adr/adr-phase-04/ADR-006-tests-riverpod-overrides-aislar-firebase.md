# ADR-006: Tests con Riverpod `overrides` para aislar Firebase en la suite de tests

**Estado:** Aceptado  
**Fecha:** 2026-06-01  
**Fase:** Phase 4 — Backend Integration MVP  
**Tags:** testing, riverpod, firebase, isolation, overrides, smoke-test

---

## Contexto

Al conectar Firebase como backend real (`Firebase.initializeApp` en `main.dart`), la suite de tests existente dejó de funcionar: los tests de widgets y smoke tests llaman a `pumpWidget(TaskFlowApp(...))`, que ahora intenta conectarse a Firebase en el constructor.

En CI (y en la mayoría de entornos de desarrollo), Firebase no está inicializado ni configurado. La pregunta fue: **¿cómo ejecutar la suite sin romper el contrato de tests rápidos que no requieren backend?**

## Decisión

### `ProviderScope` con `overrides` en los tests que usan `TaskFlowApp`

En lugar de mover la inicialización de Firebase, se reemplaza la implementación de los providers en los tests:

```dart
// smoke_test.dart / widget_test.dart
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        LocalAuthDatasource(),      // fake sin Firebase
      ),
      taskRepositoryProvider.overrideWithValue(
        InMemoryTaskDatasource(),   // fake sin Firestore
      ),
      sharedPreferencesProvider.overrideWithValue(
        await SharedPreferences.getInstance(),
      ),
    ],
    child: const TaskFlowApp(),
  ),
);
```

Los tests de unidad de dominio y presentación no usan `TaskFlowApp` y no requieren overrides — no cambian.

Los tests de integración reales (que sí llaman a Firebase) corren en un entorno separado que sí tiene Firebase inicializado — no están incluidos en la suite de `flutter test` estándar del MVP.

## Consecuencias

### Positivas

- **Zero cambios al código de producción**: `main.dart` y los providers reales no cambian. Solo los archivos de test añaden `overrides`.
- **Tests rápidos se mantienen rápidos**: `LocalAuthDatasource` e `InMemoryTaskDatasource` son síncronos en memoria — sin red, sin latencia.
- **El mecanismo de override es nativo de Riverpod**: no requiere librerías adicionales de mocking. `overrideWithValue` es la forma canónica de inyectar dependencias en tests con Riverpod.
- **Evidencia de que la arquitectura es testeable**: que se pueda reemplazar `RemoteAuthDatasource` con `LocalAuthDatasource` sin modificar `AuthNotifier` ni la UI confirma que el contrato `AuthRepository` está correctamente abstraído.

### Negativas / Trade-offs

- **El test de humo no detecta regresiones de Firebase**: si `RemoteAuthDatasource` introduce un bug, los smoke tests no lo capturan — están usando el fake. Se necesitan tests de integración con Firebase emulador para cobertura completa.
- **Mantenimiento de overrides**: si se añaden nuevos providers con dependencias externas (SQLite, push notifications), hay que recordar añadirlos a los overrides de los tests afectados.
- **Los fakes deben mantenerse en sincronía**: `LocalAuthDatasource` e `InMemoryTaskDatasource` deben implementar todos los métodos nuevos que se añadan a sus interfaces, o los tests de compilación fallarán.

## Alternativas consideradas

| Alternativa | Descartada porque |
|---|---|
| `Firebase.initializeApp()` en el `setUp` de tests | Requiere credenciales reales o `firebase_core_platform_interface` mock — setup complejo para un smoke test |
| `mockito`/`mocktail` para mocks generados | Los fakes ya existían de fases anteriores; mocks generados añaden complejidad sin beneficio adicional en este contexto |
| Separar `TaskFlowApp` de la inicialización de Firebase | Cambia el código de producción para acomodar tests — inversión del principio; los tests deben adaptarse al código, no al revés |
| Tests de widgets que no usen `TaskFlowApp` | Dejarían de ejercitar el router, el ProviderScope real y el tema — reducen la cobertura del smoke test |
