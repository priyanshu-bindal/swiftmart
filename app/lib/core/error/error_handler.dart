import 'package:dio/dio.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timed out. Please check your internet connection.';
        case DioExceptionType.badResponse:
          return _handleResponseError(error.response?.statusCode, error.response?.data);
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        case DioExceptionType.connectionError:
          return 'No internet connection.';
        default:
          return 'An unexpected network error occurred.';
      }
    }
    return error.toString();
  }

  static String _handleResponseError(int? statusCode, dynamic data) {
    if (data is Map<String, dynamic> && data.containsKey('message')) {
      return data['message'] as String;
    }
    switch (statusCode) {
      case 400:
        return 'Bad request.';
      case 401:
        return 'Unauthorized. Please check your credentials.';
      case 403:
        return 'Forbidden action.';
      case 404:
        return 'Requested resource not found.';
      case 500:
        return 'Internal server error. Please try again later.';
      default:
        return 'Oops! Something went wrong.';
    }
  }
}
