import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/auth_storage.dart';

class DioClient {
  final Dio dio;
  final AuthStorage _authStorage;

  DioClient({Dio? dioClient, AuthStorage? authStorage})
    : dio = dioClient ?? Dio(),
      _authStorage = authStorage ?? AuthStorage() {
    dio.options.baseUrl = 'http://localhost:5003';
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);
    dio.options.validateStatus = (status) => status != null && status < 500;
    dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    dio.interceptors.addAll([
      LogInterceptor(
        requestBody: true,     // Print request body
        responseBody: true,    // Print response body
        requestHeader: false,   // Optional: set to true to see headers
        responseHeader: false,  // Optional: set to true to see headers
        error: true,           // Print error logs
        logPrint: (obj) {
          // Crucial: use debugPrint or log to prevent console text truncation
          debugPrint(obj.toString());
        },
      ),
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _authStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            await _authStorage.clearSession();
          }
          return handler.next(e);
        },
      ),
    ]);
  }
}
