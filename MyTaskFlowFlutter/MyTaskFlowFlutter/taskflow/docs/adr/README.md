# Architecture Decision Records (ADRs)

Registro de decisiones arquitectónicas del proyecto TaskFlow Flutter.
Cada ADR documenta **qué** se decidió, **por qué**, y cuáles son las **consecuencias**.

## Índice

| # | Decisión | Estado | Fase |
|---|----------|--------|------|
| [ADR-001](ADR-001-clean-architecture.md) | Clean Architecture como estructura del proyecto | Aceptado | 0 |
| [ADR-002](ADR-002-riverpod-state-management.md) | Flutter Riverpod como solución de estado | Aceptado | 0 |
| [ADR-003](ADR-003-dartz-either-error-handling.md) | dartz Either<Failure, T> para manejo de errores | Aceptado | 0 |
| [ADR-004](ADR-004-gorouter-navigation.md) | GoRouter para navegación declarativa | Aceptado | 0 |
| [ADR-005](ADR-005-tdd-methodology.md) | TDD como metodología de desarrollo | Aceptado | 0 |
| [ADR-006](ADR-006-inmemory-datasources-phased-backend.md) | Datasources in-memory en Phases 1-2, Firebase en Phase 3+ | Aceptado | 0 |
| [ADR-007](ADR-007-sealed-classes-state.md) | Sealed classes para representación de estado | Aceptado | 1 |
| [ADR-008](ADR-008-firebase-as-backend-platform.md) | Firebase como plataforma de backend | Aceptado (pendiente Phase 3) | 0 |

## Cómo agregar un ADR

1. Copia la plantilla de cualquier ADR existente.
2. Nómbralo `ADR-NNN-descripcion-corta.md`.
3. Completa las secciones: Contexto, Decisión, Consecuencias.
4. Actualiza este índice.

## Estados posibles

- **Propuesto** — en discusión, no implementado.
- **Aceptado** — decisión tomada e implementada (o lista para implementarse).
- **Deprecado** — ya no aplica pero se conserva por historial.
- **Reemplazado por ADR-NNN** — una decisión posterior lo sustituyó.
