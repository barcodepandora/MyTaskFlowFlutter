import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.uid,
    required this.email,
    this.displayName,
  });

  factory AuthUser.empty() => const AuthUser(uid: '', email: '');

  final String uid;
  final String email;
  final String? displayName;

  bool get isAuthenticated => uid.isNotEmpty;

  @override
  List<Object?> get props => [uid];
}
