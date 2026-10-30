import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../state/network_status.dart';
import 'api_exceptions.dart';
import 'auth_token_store.dart';
import 'config.dart';

typedef TokenRefresher = Future<void> Function();
typedef LogoutCallback = Future<void> Function();

/// Dio-клиент к PocketBase (`/api/...`).
Dio buildPbClient({
  AuthTokenStore? tokenStore,
  NetworkStatus? network,
  TokenRefresher? onRefresh,
  LogoutCallback? onLogout,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: '$apiBaseUrl/api',
      // Free Render cold start может занимать до ~60 сек.
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (s) => s != null && s < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenStore?.accessToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['Bypass-Tunnel-Reminder'] = 'true';
        if (kDebugMode) {
          debugPrint('[PB] → ${options.method} ${options.uri}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        network?.markOnline();
        final status = response.statusCode ?? 0;
        if (kDebugMode) {
          debugPrint(
            '[PB] ← ${response.requestOptions.method} '
            '${response.requestOptions.uri} → $status',
          );
        }
        if (status >= 400) {
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
        }
        return handler.next(response);
      },
      onError: (error, handler) async {
        final isNetwork = error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            (error.type == DioExceptionType.unknown && error.response == null);
        if (isNetwork) {
          network?.markOffline(
            'Нет соединения с сервером. Проверьте сеть и нажмите «Повторить».',
          );
        }
        if (kDebugMode) {
          debugPrint('[PB] сбой ${error.requestOptions.uri}: ${error.type}');
        }
        return handler.next(error);
      },
    ),
  );

  // 401 → auth-refresh → повтор (не для auth-with-password / auth-refresh).
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        final path = error.requestOptions.path;
        final alreadyRetried =
            error.requestOptions.extra['authRetried'] == true;
        final isAuthPath = path.contains('auth-with-password') ||
            path.contains('auth-refresh');
        if (status != 401 ||
            onRefresh == null ||
            alreadyRetried ||
            isAuthPath) {
          if (status == 401 && onLogout != null && !isAuthPath) {
            await onLogout();
          }
          return handler.next(error);
        }
        try {
          await onRefresh();
          final opts = error.requestOptions;
          opts.headers['Authorization'] =
              'Bearer ${tokenStore?.accessToken ?? ''}';
          opts.extra = {...opts.extra, 'authRetried': true};
          final response = await dio.fetch(opts);
          return handler.resolve(response);
        } catch (_) {
          if (onLogout != null) await onLogout();
          return handler.next(error);
        }
      },
    ),
  );

  return dio;
}

Future<T> guard<T>(Future<T> Function() run) async {
  try {
    return await run();
  } on DioException catch (e) {
    final err = e.error;
    if (err is ApiException) throw err;
    final isNetwork = e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        (e.type == DioExceptionType.unknown && e.response == null);
    if (isNetwork) throw const NetworkException();
    throw ApiException(
      localizeApiMessage(e.message, status: e.response?.statusCode),
      statusCode: e.response?.statusCode,
    );
  }
}
