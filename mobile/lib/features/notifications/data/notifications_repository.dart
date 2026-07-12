import 'package:dio/dio.dart';

import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';

class NotificationsRepository {
  NotificationsRepository({DioClient? dioClient})
      : _dio = (dioClient ?? DioClient()).dio;

  final Dio _dio;

  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final response = await _dio.get<dynamic>('/api/notifications');
    final data = unwrapData(response.data);
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<void> markRead(String id) async {
    await _dio.patch<void>('/api/notifications/$id/read');
  }

  Future<void> registerDevice(String token, {String platform = 'android'}) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/notifications/register-device',
      data: {'token': token, 'platform': platform},
    );
  }
}
