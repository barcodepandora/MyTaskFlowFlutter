# ADR-001: Clean Architecture como estructura del proyecto

- **Estado**: Aceptado
- **Fecha**: 2026-06-01
- **Fase**: 0 — Fundación

## Contexto

Se necesita una estructura de carpetas que permita:
- Crecer por fases sin romper código existente.
- Cambiar la fuente de datos (in-memory → Firestore) sin tocar la lógica de negocio.
- Probar cada capa de forma aislada.
- Incorporar nuevos features (tasks, perfil, settings) sin crear acoplamiento entre ellos.

Las alternativas evaluadas fueron:

| Opción | Descripción |
|--------|-------------|
| **MVC flat** | Una carpeta por tipo (models/, views/, controllers/). Simple al inicio, difícil de escalar. |
| **Feature-first flat** | Una carpeta por feature sin capas internas. Fácil al inicio, los tests se vuelven difíciles de aislar. |
| **Clean Architecture** | Tres capas explícitas (domain, data, presentation) por feature. Más boilerplate inicial, máxima testeabilidad. |

## Decisión

Se adopta **Clean Architecture** con organización **feature-first**:

```
lib/features/<feature>/
  domain/        ← entidades, repositorios abstractos, use cases
  data/          ← modelos, datasources concretos, providers de DI
  presentation/  ← páginas, widgets, notifiers, estados
```

La capa **domain** no importa nada de Flutter ni de paquetes externos. Es Dart puro, testeable sin framework.

Los repositorios son **interfaces en domain** e **implementaciones en data**, lo que permite sustituir `InMemoryTaskDatasource` por `FirestoreTaskDatasource` en Phase 3 sin modificar un solo use case.

## Consecuencias

**Positivas:**
- Los use cases y entidades son portables: no dependen de Flutter, Firebase ni Riverpod.
- Cambiar el backend (Firestore, REST, SQLite) solo requiere una nueva implementación de datasource.
- Los tests de dominio son rápidos: sin mocks de Firebase, sin `WidgetTester`.
- Cada feature es autocontenida; incorporar `profile/` o `settings/` no afecta a `tasks/`.

**Negativas / trade-offs:**
- Más archivos y carpetas para features simples.
- Requiere disciplina del equipo para no saltar capas (e.g., no llamar al datasource directo desde la UI).
- El mapeo domain entity ↔ data model añade conversión explícita (`fromEntity` / `toEntity`).
