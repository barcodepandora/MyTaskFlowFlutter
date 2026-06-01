# ADR-005: TDD (Test-Driven Development) como metodología

- **Estado**: Aceptado
- **Fecha**: 2026-06-01
- **Fase**: 0 — Fundación

## Contexto

El proyecto se construye por fases autónomas. Cada fase entrega un MVP funcional que la siguiente fase extiende. Sin una red de seguridad de tests, cada nueva fase corre el riesgo de romper el comportamiento ya entregado.

Se necesita:
- Verificar que cada use case tiene el comportamiento correcto antes de integrarlo con la UI.
- Hacer refactoring seguro al cambiar datasources (in-memory → Firestore).
- Documentar el comportamiento esperado de cada componente como especificación ejecutable.

## Decisión

Se adopta **TDD** con el ciclo **Red → Green → Refactor** para toda lógica de negocio y estado. La cobertura mínima esperada por feature:

| Capa | Qué se testa | Herramientas |
|------|-------------|--------------|
| Domain (entities, use cases) | Lógica pura, validaciones, comportamiento de errores | `flutter_test`, `mockito` |
| Data (datasources, models) | Serialización, operaciones CRUD, manejo de errores de storage | `flutter_test`, mocks de repositorio |
| Presentation (notifiers, páginas) | Transiciones de estado, interacciones de usuario, renders | `flutter_test`, `WidgetTester`, `ProviderContainer` |

Convenciones de test:
- Un archivo de test por archivo de producción, espejando la estructura de `lib/`.
- Tests nombrados en español descriptivo: `'debe retornar TaskValidationFailure cuando el título está vacío'`.
- `test_helpers.dart` centraliza builders reutilizables para `ProviderScope` y entidades de prueba.

Los tests de integración E2E se difieren a fases posteriores.

## Consecuencias

**Positivas:**
- Al cambiar `InMemoryTaskDatasource` por `FirestoreTaskDatasource` en Phase 3, los tests de use cases verifican que el comportamiento no cambió.
- Los tests son la documentación viva del contrato de cada componente.
- Se detectan regresiones inmediatamente al correr `flutter test` en CI.

**Negativas / trade-offs:**
- Velocidad de desarrollo inicial más lenta: escribir el test antes del código requiere más tiempo por feature.
- Los tests de presentación (`WidgetTester`) son frágiles ante cambios de UI; deben testar comportamiento, no estructura del árbol de widgets.
- Mantener mocks actualizados cuando cambian las interfaces es un overhead recurrente.
