import 'package:dio/dio.dart';

import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';

class ProfileRepository {
  ProfileRepository({DioClient? dioClient})
      : _dio = (dioClient ?? DioClient()).dio;

  final Dio _dio;

  Future<Map<String, dynamic>> fetchProfile() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/users/me');
    return unwrapData(response.data);
  }

  Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/users/me',
      data: {
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (email != null) 'email': email,
      },
    );
    return unwrapData(response.data);
  }
}
