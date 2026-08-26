import 'package:dio/dio.dart';

import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/hive_boxes.dart';

class ContentRepository {
  ContentRepository({DioClient? dioClient})
      : _dio = (dioClient ?? DioClient()).dio;

  final Dio _dio;
  static const _cacheTtl = Duration(minutes: 15);

  Future<Map<String, dynamic>> fetchWeather({bool forceRefresh = false}) async {
    return _fetchCached('weather_cache', '/api/content/weather', forceRefresh);
  }

  Future<List<dynamic>> fetchServices({bool forceRefresh = false}) async {
    if (forceRefresh) {
      await HiveBoxes.settings.delete('services_cache');
    }
    try {
      final response = await _dio.get<dynamic>(
        '/api/content/services',
        queryParameters: forceRefresh
            ? {'_': DateTime.now().millisecondsSinceEpoch}
            : null,
      );
      final data = unwrapData(response.data);
      final List<dynamic> items;
      if (data is List) {
        items = data;
      } else if (data is Map && data['items'] is List) {
        items = data['items'] as List<dynamic>;
      } else {
        items = [];
      }
      await _writeCache('services_cache', {'items': items});
      return items;
    } catch (_) {
      final cached = await _readCache('services_cache', ignoreExpiry: true);
      return (cached?['items'] as List<dynamic>?) ?? [];
    }
  }

  Future<List<dynamic>> fetchTrails({bool forceRefresh = false}) async {
    return _fetchListCached('trails_cache', '/api/content/trails', forceRefresh);
  }

  Future<List<dynamic>> fetchLifts({bool forceRefresh = false}) async {
    return _fetchListCached('lifts_cache', '/api/content/lifts', forceRefresh);
  }

  Future<List<dynamic>> fetchWebcams({bool forceRefresh = false}) async {
    return _fetchListCached('webcams_cache', '/api/content/webcams', forceRefresh);
  }

  Future<Map<String, dynamic>> fetchAbout({bool forceRefresh = false}) async {
    return _fetchCached('about_cache', '/api/content/about', forceRefresh);
  }

  Future<List<dynamic>> fetchSchedule({bool forceRefresh = false}) async {
    return _fetchListCached('schedule_cache', '/api/content/schedule', forceRefresh);
  }

  Future<Map<String, dynamic>> fetchRules(String type, {bool forceRefresh = false}) async {
    final normalized = type == 'visit' ? 'visiting' : type;
    return _fetchCached('rules_$normalized', '/api/content/rules?type=$normalized', forceRefresh);
  }

  Future<List<dynamic>> fetchHeadliners({bool forceRefresh = false}) async {
    return _fetchListCached('headliners_cache', '/api/content/headliners', forceRefresh);
  }

  Future<Map<String, dynamic>> _fetchCached(
    String cacheKey,
    String path,
    bool forceRefresh,
  ) async {
    if (!forceRefresh) {
      final cached = await _readCache(cacheKey);
      if (cached != null) return cached;
    }
    try {
      final response = await _dio.get<dynamic>(path);
      final data = unwrapData(response.data);
      final map = data is Map<String, dynamic>
          ? data
          : data is Map
              ? Map<String, dynamic>.from(data)
              : <String, dynamic>{};
      await _writeCache(cacheKey, map);
      return map;
    } catch (_) {
      return await _readCache(cacheKey, ignoreExpiry: true) ?? {};
    }
  }

  Future<List<dynamic>> _fetchListCached(
    String cacheKey,
    String path,
    bool forceRefresh, {
    Duration ttl = _cacheTtl,
  }) async {
    if (!forceRefresh) {
      final cached = await _readCache(cacheKey, ttl: ttl);
      if (cached != null && cached['items'] is List) {
        return cached['items'] as List<dynamic>;
      }
    }
    try {
      final response = await _dio.get<dynamic>(path);
      final data = unwrapData(response.data);
      final List<dynamic> items;
      if (data is List) {
        items = data;
      } else if (data is Map && data['items'] is List) {
        items = data['items'] as List<dynamic>;
      } else {
        items = [];
      }
      await _writeCache(cacheKey, {'items': items});
      return items;
    } catch (_) {
      final cached = await _readCache(cacheKey, ignoreExpiry: true);
      return (cached?['items'] as List<dynamic>?) ?? [];
    }
  }

  Future<Map<String, dynamic>?> _readCache(
    String key, {
    bool ignoreExpiry = false,
    Duration ttl = _cacheTtl,
  }) async {
    final raw = HiveBoxes.settings.get(key);
    if (raw is! Map) return null;
    if (!ignoreExpiry) {
      final fetchedAt = raw['fetchedAt'] as int?;
      if (fetchedAt != null) {
        final age = DateTime.now().millisecondsSinceEpoch - fetchedAt;
        if (age > ttl.inMilliseconds) return null;
      }
    }
    return Map<String, dynamic>.from(raw['data'] as Map? ?? {});
  }

  Future<void> _writeCache(String key, Map<String, dynamic> data) async {
    await HiveBoxes.settings.put(key, {
      'fetchedAt': DateTime.now().millisecondsSinceEpoch,
      'data': data,
    });
  }
}
