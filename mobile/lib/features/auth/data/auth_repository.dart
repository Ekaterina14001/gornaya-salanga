import 'package:dio/dio.dart';

import 'package:equatable/equatable.dart';



import '../../../core/network/dio_client.dart';

import '../../../core/network/api_response.dart';

import '../../../core/storage/secure_storage.dart';



class AuthRepository {

  AuthRepository({

    DioClient? dioClient,

    SecureStorage? secureStorage,

  })  : _dioClient = dioClient ?? DioClient(),

        _secureStorage = secureStorage ?? SecureStorage();



  final DioClient _dioClient;

  final SecureStorage _secureStorage;



  Dio get _dio => _dioClient.dio;



  Future<bool> hasStoredSession() => _secureStorage.hasTokens();



  Future<void> login({

    required String email,

    required String password,

  }) async {

    final response = await _dio.post<Map<String, dynamic>>(

      '/api/auth/login',

      data: {'email': email, 'password': password},

    );

    await _saveSession(response.data);

  }



  Future<void> register({

    required String email,

    required String password,

    required String phone,

    String firstName = 'Гость',

    String lastName = 'Новый',

  }) async {

    final response = await _dio.post<Map<String, dynamic>>(

      '/api/auth/register',

      data: {

        'email': email,

        'password': password,

        'phone': phone,

        'firstName': firstName,

        'lastName': lastName,

      },

    );

    await _saveSession(response.data);

  }



  Future<void> _saveSession(Map<String, dynamic>? body) async {

    final data = unwrapData(body);

    final accessToken = data['accessToken'] as String?;

    final refreshToken = data['refreshToken'] as String?;

    final deviceSecret = data['deviceSecret'] as String?;

    if (accessToken == null || refreshToken == null) {

      throw const AuthException('Неверный ответ сервера');

    }

    final user = data['user'] as Map<String, dynamic>?;

    await _secureStorage.saveTokens(

      accessToken: accessToken,

      refreshToken: refreshToken,

      deviceSecret: deviceSecret,

      userId: user?['id'] as String?,

    );

  }



  Future<void> verify({
    required String phone,
    required String code,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/auth/verify-phone',
      data: {'phone': phone, 'code': code},
    );
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/auth/forgot-password',
      data: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/auth/reset-password',
      data: {'email': email, 'code': code, 'newPassword': newPassword},
    );
  }

  Future<void> logout() => _secureStorage.clearTokens();

}



class AuthException implements Exception {

  const AuthException(this.message);



  final String message;



  @override

  String toString() => message;

}



class LoginCredentials extends Equatable {

  const LoginCredentials({required this.email, required this.password});



  final String email;

  final String password;



  @override

  List<Object?> get props => [email, password];

}

