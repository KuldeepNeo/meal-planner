import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/storage/auth_storage.dart';

class AuthService {
  final DioClient _dioClient;
  final AuthStorage _authStorage;

  AuthService({DioClient? dioClient, AuthStorage? authStorage})
      : _dioClient = dioClient ?? DioClient(),
        _authStorage = authStorage ?? AuthStorage();

  Future<bool> login({required String email, required String password}) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      if (response.statusCode == 200) {
        final data = response.data;
        await _authStorage.saveTokens(
          token: data['token'],
          refreshToken: data['refreshToken'],
          userId: data['userId'],
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/auth/register',
        data: {'name': name, 'email': email, 'password': password},
      );
      if (response.statusCode == 201) {
        return response.data;
      }
      final data = response.data;
      if (data is Map && data.containsKey('error')) {
        return {'error': data['error'] ?? 'Registration failed'};
      }
      return {'error': 'Registration failed'};
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) {
        return {'error': data['error'] ?? 'Registration failed'};
      }
      return {'error': 'Registration failed'};
    } catch (e) {
      return {'error': 'Registration failed'};
    }
  }

  Future<bool> requestPasswordReset({required String email}) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/auth/password-reset-request',
        data: {'email': email},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/auth/password-reset',
        data: {'token': token, 'newPassword': newPassword},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await _authStorage.clearSession();
  }

  Future<bool> isLoggedIn() async {
    return await _authStorage.hasSession();
  }
}
