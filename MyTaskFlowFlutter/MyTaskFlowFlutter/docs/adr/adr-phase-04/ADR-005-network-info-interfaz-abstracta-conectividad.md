# ADR-005: `NetworkInfo` — interfaz abstracta para verificar conectividad

**Estado:** Aceptado  
**Fecha:** 2026-06-01  
**Fase:** Phase 4 — Backend Integration MVP  
**Tags:** infrastructure, network, testability, abstraction, connectivity-plus

---

## Contexto

Con Firebase como backend real, las operaciones pueden fallar por falta de conexión. La detección temprana de "sin red" permite retornar un `NetworkFailure` antes de intentar la llamada a Firestore/Auth, en lugar de esperar el timeout del SDK.

La librería `connectivity_plus` ofrece `Connectivity.checkConnectivity()` que retorna una lista de `ConnectivityResult`. El reto: ¿cómo integrar esta dependencia de plataforma de forma testeable?

## Decisión

### Interfaz abstracta `NetworkInfo` + implementación `ConnectivityNetworkInfo`

```dart
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class ConnectivityNetworkInfo implements NetworkInfo {
  const ConnectivityNetworkInfo(this._connectivity);
  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return ConnectivityNetworkInfo(Connectivity());
});
```

La interfaz expone solo `isConnected` — una pregunta booleana. Los datasources que la necesiten la reciben por inyección de dependencias vía Riverpod.

La condición `results.any((r) => r != ConnectivityResult.none)` cubre el caso multi-interfaz de `connectivity_plus` v6+: el dispositivo puede tener WiFi Y datos activos simultáneamente; basta con que una interfaz esté activa.

## Consecuencias

### Positivas

- **Testabilidad total**: en los tests se inyecta una implementación fake:
  ```dart
  class FakeNetworkInfo implements NetworkInfo {
    FakeNetworkInfo({required this.isConnected});
    @override
    final Future<bool> isConnected;
  }
  ```
  Sin esto, `connectivity_plus` requeriría un device/emulator real.
- **Indirección ante cambio de librería**: si `connectivity_plus` se reemplaza por otra librería o la API del plugin cambia, solo se modifica `ConnectivityNetworkInfo`.
- **Interfaz mínima**: exponer solo `isConnected` (bool) en lugar de los `ConnectivityResult` crudos evita que los datasources tomen decisiones sobre el tipo de conexión (WiFi vs. datos) — responsabilidad de la capa de infraestructura.

### Negativas / Trade-offs

- **`NetworkInfo` no está integrado aún en los datasources**: en Phase 4, `FirebaseTaskDatasource` no llama a `networkInfoProvider` antes de operar. La comprobación real de red depende del manejo de errores del SDK. La interfaz existe como preparación para offline-first — es deuda técnica documentada.
- **`connectivity_plus` puede reportar "conectado" sin acceso real a internet**: el plugin detecta si hay una interfaz de red activa, no si hay conectividad real a los servidores. Para una verificación real sería necesario un ping o la respuesta del servidor.

## Alternativas consideradas

| Alternativa | Descartada porque |
|---|---|
| Usar `Connectivity` directamente en el datasource | Imposible de mockear sin un device; los tests unitarios fallarían |
| No implementar `NetworkInfo` en Phase 4 | Los datasources Firebase no tendrían forma de distinguir error de red de error de servidor |
| `NetworkInfo` con métodos adicionales (tipo de conexión, stream) | Overengineering para el MVP; la única pregunta que los datasources necesitan responder es "¿hay red?" |

## Deuda técnica generada

Integrar `networkInfoProvider` en `FirebaseTaskDatasource` y `RemoteAuthDatasource`: antes de cada operación, verificar `await ref.read(networkInfoProvider).isConnected`; si es `false`, retornar `Left(NetworkFailure())` sin llamar al SDK.
