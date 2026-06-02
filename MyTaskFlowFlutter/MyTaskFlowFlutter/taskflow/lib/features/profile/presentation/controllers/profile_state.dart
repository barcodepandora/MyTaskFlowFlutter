import 'package:equatable/equatable.dart';
import 'package:taskflow/features/auth/domain/entities/auth_user.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();

  @override
  List<Object?> get props => [];
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();

  @override
  List<Object?> get props => [];
}

class ProfileUpdated extends ProfileState {
  const ProfileUpdated(this.user);

  final AuthUser user;

  @override
  List<Object?> get props => [user];
}

class ProfileError extends ProfileState {
  const ProfileError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
