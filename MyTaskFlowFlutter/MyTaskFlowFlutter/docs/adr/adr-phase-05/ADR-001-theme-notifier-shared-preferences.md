# ADR-001: `ThemeNotifier` con `SharedPreferences` para persistencia del tema

**Estado:** Aceptado  
**Fecha:** 2026-06-02  
**Fase:** Phase 5 — Profile & Settings MVP  
**Tags:** theme, state-management, riverpod, shared-preferences, settings

---

## Contexto

Phase 5 añade selección de tema (Claro / Sistema / Oscuro). El tema elegido debe persistir entre sesiones — si el usuario selecciona Oscuro, debe seguir en Oscuro al relanzar la app.

La pregunta fue: **¿cómo integrar `SharedPreferences` con Riverpod de forma testeable?**

`SharedPreferences` requiere `await` para inicializarse (`SharedPreferences.getInstance()`), pero los providers de Riverpod son síncronos por defecto. Además, los tests no deben depender del sistema de archivos real.

## Decisión

### `sharedPreferencesProvider` como provider base con throw + override en `main` y tests

```dart
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);
```

En `main.dart`, se resuelve antes de `runApp`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const TaskFlowApp(),
    ),
  );
}
```

`ThemeNotifier` lee el valor inicial de forma síncrona en el constructor:

```dart
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier(this._prefs) : super(_load(_prefs));

  static ThemeMode _load(SharedPreferences prefs) {
    return switch (prefs.getString('theme_mode')) {
      'light'  => ThemeMode.light,
      'dark'   => ThemeMode.dark,
      _        => ThemeMode.system,
    };
  }
}
```

## Consecuencias

### Positivas

- **Sin `FutureProvider` ni `AsyncValue`**: la inicialización async ocurre en `main`, antes de que cualquier widget se construya. El provider es síncrono en toda la app.
- **Testeable**: los tests inyectan `SharedPreferences.setMockInitialValues({})` y pasan el fake via `overrideWithValue`, igual que en producción.
- **Fail-fast**: si alguien usa `sharedPreferencesProvider` sin override (ej. en un test nuevo que olvidó el setup), lanza `UnimplementedError` inmediatamente — no un bug silencioso.
- **Patrón reutilizable**: cualquier otro servicio que requiera async init (SQLite, Hive) puede seguir el mismo patrón: provider con throw + override en main.

### Negativas / Trade-offs

- **`main` se vuelve `async`**: `WidgetsFlutterBinding.ensureInitialized()` es requerido antes de cualquier `await`. Tests que usen `TaskFlowApp` directamente deben proveer el override o fallarán.
- **El estado inicial depende del estado de `SharedPreferences` en el momento del boot**: si las prefs están corruptas o vacías, el tema cae a `ThemeMode.system` — comportamiento correcto pero implícito.

## Alternativas consideradas

| Alternativa | Descartada porque |
|---|---|
| `FutureProvider<SharedPreferences>` | Fuerza a que toda la app espere `AsyncValue.loading` al arrancar — splash de carga innecesario |
| `StateProvider<ThemeMode>` sin persistencia | El tema se resetea a `system` en cada restart — mala UX |
| Hive como alternativa a SharedPreferences | Overkill para un único valor string; SharedPreferences es suficiente y ya es dependencia del proyecto |
| Leer prefs dentro del `ThemeNotifier` con `await` | `StateNotifier` no puede ser async en el constructor; requeriría un método `init()` separado con estado intermedio |
