import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/features/auth/data/models/auth_user_model.dart';
import 'package:taskflow/features/auth/domain/entities/auth_user.dart';

void main() {
  group('AuthUserModel', () {
    const testJson = {
      'uid': 'uid-123',
      'email': 'test@taskflow.com',
      'displayName': 'Test User',
    };

    const testModel = AuthUserModel(
      uid: 'uid-123',
      email: 'test@taskflow.com',
      displayName: 'Test User',
    );

    test('fromJson constructs AuthUserModel correctly', () {
      final result = AuthUserModel.fromJson(testJson);
      expect(result.uid, 'uid-123');
      expect(result.email, 'test@taskflow.com');
      expect(result.displayName, 'Test User');
    });

    test('toJson serializes correctly', () {
      final json = testModel.toJson();
      expect(json, testJson);
    });

    test('fromJson handles null displayName', () {
      final result = AuthUserModel.fromJson({
        'uid': 'uid-1',
        'email': 'a@b.com',
      });
      expect(result.displayName, isNull);
    });

    test('AuthUserModel is subclass of AuthUser', () {
      expect(testModel, isA<AuthUser>());
    });

    test('toEntity returns AuthUser with same data', () {
      final entity = testModel.toEntity();
      expect(entity, isA<AuthUser>());
      expect(entity.uid, testModel.uid);
      expect(entity.email, testModel.email);
      expect(entity.displayName, testModel.displayName);
    });
  });
}
