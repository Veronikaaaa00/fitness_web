import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/auth_token_store.dart';
import '../core/pb_client.dart';
import '../models/app_user.dart';
import '../models/role.dart';

class AuthResult {
  const AuthResult({
    required this.token,
    required this.user,
  });

  final String token;
  final AppUser user;
}

class AuthRepository {
  AuthRepository(this._dio, this._tokens);

  final Dio _dio;
  final AuthTokenStore _tokens;

  Future<AuthResult> login({
    required String email,
    required String password,
  }) =>
      guard(() async {
        final response = await _dio.post(
          '/collections/users/auth-with-password',
          data: {'identity': email, 'password': password},
        );
        return _parseAuth(response.data);
      });

  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
  }) =>
      guard(() async {
        await _dio.post(
          '/collections/users/records',
          data: {
            'email': email,
            'password': password,
            'passwordConfirm': password,
            'name': fullName,
            'role': Role.member.apiValue,
            'emailVisibility': true,
          },
        );
        return login(email: email, password: password);
      });

  Future<AppUser> me() => guard(() async {
        final response = await _dio.post('/collections/users/auth-refresh');
        final data = Map<String, dynamic>.from(response.data as Map);
        final record = Map<String, dynamic>.from(data['record'] as Map);
        final token = '${data['token'] ?? ''}';
        if (token.isNotEmpty) {
          _tokens.setTokens(access: token, userId: '${record['id']}');
        }
        return AppUser.fromJson(record);
      });

  AuthResult _parseAuth(dynamic raw) {
    final data = Map<String, dynamic>.from(raw as Map);
    final token = '${data['token'] ?? ''}';
    final record = Map<String, dynamic>.from(data['record'] as Map);
    if (token.isEmpty) {
      throw const ApiException('Сервер не вернул токен');
    }
    final user = AppUser.fromJson(record);
    _tokens.setTokens(access: token, userId: user.id);
    return AuthResult(token: token, user: user);
  }

  void clearLocal() => _tokens.clear();
}
