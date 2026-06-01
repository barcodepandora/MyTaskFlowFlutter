import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
