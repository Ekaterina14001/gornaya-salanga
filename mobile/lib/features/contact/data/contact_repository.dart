import 'package:dio/dio.dart';

import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';

class ContactRepository {
  ContactRepository({DioClient? dioClient})
      : _dio = (dioClient ?? DioClient()).dio;

  final Dio _dio;

  Future<void> sendMessage({
    required String subject,
    required String body,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/users/contact',
      data: {'subject': subject, 'body': body},
    );
  }

  Future<List<Map<String, dynamic>>> fetchMessages() async {
    final response = await _dio.get<dynamic>('/api/users/me/messages');
    final data = unwrapData(response.data);
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }
}
