import 'package:dio/dio.dart';



import '../config/app_config.dart';

import '../storage/secure_storage.dart';

import 'api_response.dart';



class DioClient {

  DioClient({SecureStorage? secureStorage})

      : _secureStorage = secureStorage ?? SecureStorage() {

    _dio = Dio(

      BaseOptions(

        baseUrl: AppConfig.apiBaseUrl,

        connectTimeout: const Duration(seconds: 15),

        receiveTimeout: const Duration(seconds: 15),

        headers: {'Content-Type': 'application/json'},

      ),

    );



    _dio.interceptors.add(

      InterceptorsWrapper(

        onRequest: _onRequest,

        onError: _onError,

      ),

    );

  }



  final SecureStorage _secureStorage;

  late final Dio _dio;

  bool _isRefreshing = false;



  Dio get dio => _dio;



  Future<void> _onRequest(

    RequestOptions options,

    RequestInterceptorHandler handler,

  ) async {

    final token = await _secureStorage.getAccessToken();

    if (token != null && token.isNotEmpty) {

      options.headers['Authorization'] = 'Bearer $token';

    }

    handler.next(options);

  }



  Future<void> _onError(

    DioException err,

    ErrorInterceptorHandler handler,

  ) async {

    if (err.response?.statusCode != 401) {

      handler.next(err);

      return;

    }



    if (_isRefreshing) {

      handler.next(err);

      return;

    }



    _isRefreshing = true;

    try {

      final refreshToken = await _secureStorage.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {

        await _secureStorage.clearTokens();

        handler.next(err);

        return;

      }



      final refreshDio = Dio(

        BaseOptions(baseUrl: AppConfig.apiBaseUrl),

      );

      final response = await refreshDio.post<Map<String, dynamic>>(

        '/api/auth/refresh',

        data: {'refreshToken': refreshToken},

      );



      final data = unwrapData(response.data);

      final newAccess = data['accessToken'] as String?;

      final newRefresh = data['refreshToken'] as String? ?? refreshToken;



      if (newAccess == null) {

        await _secureStorage.clearTokens();

        handler.next(err);

        return;

      }



      await _secureStorage.saveTokens(

        accessToken: newAccess,

        refreshToken: newRefresh,

      );



      final requestOptions = err.requestOptions;

      requestOptions.headers['Authorization'] = 'Bearer $newAccess';

      final retryResponse = await _dio.fetch<dynamic>(requestOptions);

      handler.resolve(retryResponse);

    } on DioException catch (refreshError) {

      await _secureStorage.clearTokens();

      handler.next(refreshError);

    } finally {

      _isRefreshing = false;

    }

  }

}

