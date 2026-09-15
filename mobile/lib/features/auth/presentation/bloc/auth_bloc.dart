import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/auth/biometric_service.dart';
import '../../data/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({AuthRepository? authRepository, BiometricService? biometricService})
      : _authRepository = authRepository ?? AuthRepository(),
        _biometric = biometricService ?? BiometricService(),
        super(const AuthState.unknown()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthVerifyRequested>(_onVerifyRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthBiometricUnlockRequested>(_onBiometricUnlockRequested);
    on<AuthBiometricEnabled>(_onBiometricEnabled);
  }

  final AuthRepository _authRepository;
  final BiometricService _biometric;
  String? _pendingBioEmail;
  String? _pendingBioPassword;

  Future<bool> isBiometricAlreadyEnabled() => _authRepository.isBiometricEnabled();

  ({String email, String password})? takePendingBiometricOffer() {
    final email = _pendingBioEmail;
    final password = _pendingBioPassword;
    _pendingBioEmail = null;
    _pendingBioPassword = null;
    if (email == null || email.isEmpty || password == null || password.isEmpty) {
      return null;
    }
    return (email: email, password: password);
  }

  void _rememberBiometricOffer(String email, String password) {
    _pendingBioEmail = email;
    _pendingBioPassword = password;
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final hasSession = await _authRepository.hasStoredSession();
      final biometricOn = await _authRepository.isBiometricEnabled();
      final canBiometric = biometricOn && await _biometric.canUse();
      if (hasSession && !canBiometric) {
        emit(const AuthState.authenticated());
        return;
      }
      emit(
        const AuthState.unauthenticated().copyWith(
          showBiometricLogin: canBiometric,
        ),
      );
    } catch (_) {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      if (await _authRepository.isBiometricEnabled()) {
        await _authRepository.enableBiometric(
          email: event.email,
          password: event.password,
        );
      } else {
        _rememberBiometricOffer(event.email, event.password);
      }
      emit(const AuthState.authenticated());
    } on DioException catch (e) {
      emit(
        AuthState.unauthenticated().copyWith(
          isLoading: false,
          errorMessage: _mapDioError(e),
          showBiometricLogin: state.showBiometricLogin,
        ),
      );
    } catch (e) {
      emit(
        AuthState.unauthenticated().copyWith(
          isLoading: false,
          errorMessage: e.toString(),
          showBiometricLogin: state.showBiometricLogin,
        ),
      );
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true, clearPendingRegistration: true));
    try {
      await _authRepository.register(
        email: event.email,
        password: event.password,
        phone: event.phone,
        firstName: event.firstName,
        lastName: event.lastName,
      );
      if (await _authRepository.isBiometricEnabled()) {
        await _authRepository.enableBiometric(
          email: event.email,
          password: event.password,
        );
      } else {
        _rememberBiometricOffer(event.email, event.password);
      }
      emit(const AuthState.authenticated());
    } on DioException catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: _mapDioError(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onVerifyRequested(
    AuthVerifyRequested event,
    Emitter<AuthState> emit,
  ) async {
    final pending = state.pendingRegistration;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _authRepository.verify(phone: event.phone, code: event.code);
      if (pending != null) {
        await _authRepository.login(
          email: pending.email,
          password: pending.password,
        );
        emit(const AuthState.authenticated());
        return;
      }
      emit(state.copyWith(isLoading: false));
    } on DioException catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: _mapDioError(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    _pendingBioEmail = null;
    _pendingBioPassword = null;
    emit(const AuthState.unauthenticated());
  }

  Future<void> _onBiometricUnlockRequested(
    AuthBiometricUnlockRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true, showBiometricLogin: true));
    final ok = await _biometric.authenticate();
    if (!ok) {
      emit(
        const AuthState.unauthenticated().copyWith(
          showBiometricLogin: true,
          errorMessage: 'Не удалось подтвердить личность',
        ),
      );
      return;
    }
    if (await _authRepository.hasStoredSession()) {
      emit(const AuthState.authenticated());
      return;
    }
    final creds = await _authRepository.biometricCredentials();
    if (creds == null) {
      emit(
        const AuthState.unauthenticated().copyWith(
          errorMessage: 'Войдите по email и паролю',
        ),
      );
      return;
    }
    try {
      await _authRepository.login(email: creds.email, password: creds.password);
      emit(const AuthState.authenticated());
    } on DioException catch (e) {
      emit(
        const AuthState.unauthenticated().copyWith(
          showBiometricLogin: true,
          errorMessage: _mapDioError(e),
        ),
      );
    } catch (e) {
      emit(
        const AuthState.unauthenticated().copyWith(
          showBiometricLogin: true,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onBiometricEnabled(
    AuthBiometricEnabled event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.enableBiometric(
      email: event.email,
      password: event.password,
    );
  }

  String _mapDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final error = data['error'];
      if (error is Map && error['message'] is String) {
        return error['message'] as String;
      }
      if (data['message'] is String) {
        return data['message'] as String;
      }
    }
    return 'Ошибка сети (${e.response?.statusCode ?? 'нет связи'})';
  }
}
