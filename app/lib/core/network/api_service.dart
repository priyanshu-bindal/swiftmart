import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          AppLogger.log('HTTP REQUEST: ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.log('HTTP RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          AppLogger.error('HTTP ERROR: ${e.message}', error: e, stackTrace: e.stackTrace);
          return handler.next(e);
        },
      ),
    );
  }

  Dio get client => _dio;
}
