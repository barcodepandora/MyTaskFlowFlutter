import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/features/auth/domain/entities/auth_user.dart';

void main() {
  group('AuthUser', () {
    test('two AuthUsers with same uid are equal regardless of email', () {
      const user1 = AuthUser(uid: 'uid-123', email: 'a@test.com');
      const user2 = AuthUser(uid: 'uid-123', email: 'b@test.com');
      expect(user1, equals(user2));
    });

    test('AuthUser.empty has empty uid', () {
      final user = AuthUser.empty();
      expect(user.uid, isEmpty);
    });

    test('isAuthenticated returns false when uid is empty', () {
      final user = AuthUser.empty();
      expect(user.isAuthenticated, isFalse);
    });

    test('isAuthenticated returns true when uid is not empty', () {
      const user = AuthUser(uid: 'uid-123', email: 'test@test.com');
      expect(user.isAuthenticated, isTrue);
    });

    test('supports displayName nullable', () {
      const user = AuthUser(uid: 'uid-1', email: 'e@e.com', displayName: 'Eva');
      expect(user.displayName, 'Eva');

      const noName = AuthUser(uid: 'uid-2', email: 'e@e.com');
      expect(noName.displayName, isNull);
    });
  });
}
