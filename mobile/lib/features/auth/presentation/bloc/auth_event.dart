part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

final class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.phone,
    required this.firstName,
    required this.lastName,
  });

  final String email;
  final String password;
  final String phone;
  final String firstName;
  final String lastName;

  @override
  List<Object?> get props => [email, password, phone, firstName, lastName];
}

final class AuthVerifyRequested extends AuthEvent {
  const AuthVerifyRequested({required this.phone, required this.code});

  final String phone;
  final String code;

  @override
  List<Object?> get props => [phone, code];
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
