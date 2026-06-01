import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskflow/core/network/network_info.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late MockConnectivity mockConnectivity;
  late ConnectivityNetworkInfo networkInfo;

  setUp(() {
    mockConnectivity = MockConnectivity();
    networkInfo = ConnectivityNetworkInfo(mockConnectivity);
  });

  group('isConnected', () {
    test('returns true when WiFi is available', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      expect(await networkInfo.isConnected, isTrue);
    });

    test('returns true when mobile data is available', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.mobile]);

      expect(await networkInfo.isConnected, isTrue);
    });

    test('returns true when ethernet is available', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.ethernet]);

      expect(await networkInfo.isConnected, isTrue);
    });

    test('returns false when no connection', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);

      expect(await networkInfo.isConnected, isFalse);
    });

    test('returns true when at least one result is not none', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none, ConnectivityResult.wifi]);

      expect(await networkInfo.isConnected, isTrue);
    });
  });
}
