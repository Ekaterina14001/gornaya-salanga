import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository(),
        super(const AuthState.unknown()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthVerifyRequested>(_onVerifyRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final AuthRepository _authRepository;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final hasSession = await _authRepository.hasStoredSession();
      emit(
        hasSession
            ? const AuthState.authenticated()
            : const AuthState.unauthenticated(),
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
      emit(const AuthState.authenticated());
    } on DioException catch (e) {
      emit(
        AuthState.unauthenticated().copyWith(
          isLoading: false,
          errorMessage: _mapDioError(e),
        ),
      );
    } catch (e) {
      emit(
        AuthState.unauthenticated().copyWith(
          isLoading: false,
          errorMessage: e.toString(),
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
    emit(const AuthState.unauthenticated());
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
