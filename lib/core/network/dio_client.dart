import 'package:dio/dio.dart';

import '../auth/portal_session.dart';
import '../constants/api_constants.dart';

class DioClient {
  DioClient._();
  static final DioClient _instance = DioClient._();
  static DioClient get instance => _instance;

  late final Dio dio = _createDio();

  Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          PortalSession.readAuthHeaders().then(
            (h) {
              final t = h.token;
              if (t != null && t.isNotEmpty) {
                options.headers['X-Session-Token'] = t;
                options.headers['X-Session'] = t;
                // Opaque portal session (not necessarily DRF Token auth).
                options.headers['Authorization'] = 'Bearer $t';
              }
              final c = h.cookie;
              if (c != null && c.isNotEmpty) {
                options.headers['Cookie'] = c;
              }
              handler.next(options);
            },
            onError: (_, __) => handler.next(options),
          );
        },
      ),
    );

    assert(() {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false,
          responseHeader: false,
          error: true,
        ),
      );
      return true;
    }());

    return dio;
  }
}
