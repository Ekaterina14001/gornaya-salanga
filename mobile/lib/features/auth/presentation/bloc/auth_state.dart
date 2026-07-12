part of 'auth_bloc.dart';

final class PendingRegistration extends Equatable {
  const PendingRegistration({
    required this.email,
    required this.password,
    required this.phone,
  });

  final String email;
  final String password;
  final String phone;

  @override
  List<Object?> get props => [email, password, phone];
}

enum AuthStatus { unknown, authenticated, unauthenticated }

final class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.isLoading = false,
    this.errorMessage,
    this.pendingRegistration,
  });

  const AuthState.unknown() : this();

  const AuthState.authenticated()
      : this(status: AuthStatus.authenticated);

  const AuthState.unauthenticated()
      : this(status: AuthStatus.unauthenticated);

  final AuthStatus status;
  final bool isLoading;
  final String? errorMessage;
  final PendingRegistration? pendingRegistration;

  AuthState copyWith({
    AuthStatus? status,
    bool? isLoading,
    String? errorMessage,
    PendingRegistration? pendingRegistration,
    bool clearError = false,
    bool clearPendingRegistration = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pendingRegistration: clearPendingRegistration
          ? null
          : (pendingRegistration ?? this.pendingRegistration),
    );
  }

  @override
  List<Object?> get props => [status, isLoading, errorMessage, pendingRegistration];
}
