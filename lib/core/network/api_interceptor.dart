import 'package:dio/dio.dart';
import 'package:srs8/core/error/app_exception.dart';

/// Добавляет технические заголовки к каждому запросу.
class ApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept'] = 'application/json';
    options.headers['X-App-Name'] = 'PostExplorer';
    options.headers['X-Request-Id'] =
        DateTime.now().microsecondsSinceEpoch.toString();
    handler.next(options);
  }
}

/// Централизованно превращает любые ошибки Dio в AppException.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err.copyWith(error: AppException.fromDio(err)));
  }
}