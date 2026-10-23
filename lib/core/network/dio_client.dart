import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:srs8/core/network/api_interceptor.dart';

/// отправляет запросы в интернет, так же обработка запросов и ошибок 
class DioClient {
  DioClient({Dio? dio}) : dio = dio ?? _create();

  static const baseUrl = 'https://jsonplaceholder.typicode.com';

  final Dio dio;

  static Dio _create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        responseType: ResponseType.json,
      ),
    );

    dio.interceptors.add(ApiInterceptor());
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseBody: false,
          logPrint: (o) => debugPrint(o.toString()),
        ),
      );
    }
    dio.interceptors.add(ErrorInterceptor());
    return dio;
  }
}