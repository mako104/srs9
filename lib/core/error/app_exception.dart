import 'dart:io';

import 'package:dio/dio.dart';

enum AppExceptionType { noConnection, timeout, client, server, parsing, unknown }

/// перечень ошибок
class AppException implements Exception {
  const AppException(
    this.type,
    this.message, {
    this.statusCode,
    this.technical,
  });

  final AppExceptionType type;
  final String message; // показываем пользователю
  final int? statusCode;
  final String? technical; // только для логов

  /// Превращает любую ошибку в AppException.
  factory AppException.from(Object error) {
    if (error is AppException) return error;
    if (error is DioException) {
      final inner = error.error;
      if (inner is AppException) return inner;
      return AppException.fromDio(error);
    }
    if (error is TypeError || error is FormatException) {
      return AppException(
        AppExceptionType.parsing,
        'Не удалось обработать ответ сервера. Попробуйте позже.',
        technical: error.toString(),
      );
    }
    return AppException(
      AppExceptionType.unknown,
      'Что-то пошло не так. Попробуйте ещё раз.',
      technical: error.toString(),
    );
  }

  factory AppException.fromDio(DioException e) {
    final technical = e.message ?? e.toString();
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppException(
          AppExceptionType.timeout,
          'Сервер слишком долго отвечает. Проверьте интернет и повторите.',
          technical: technical,
        );
      case DioExceptionType.connectionError:
        return AppException(
          AppExceptionType.noConnection,
          'Нет подключения к интернету.',
          technical: technical,
        );
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode ?? 0;
        if (code >= 500) {
          return AppException(
            AppExceptionType.server,
            'Ошибка на сервере ($code). Попробуйте позже.',
            statusCode: code,
            technical: technical,
          );
        }
        return AppException(
          AppExceptionType.client,
          code == 404
              ? 'Данные не найдены (404).'
              : 'Некорректный запрос ($code).',
          statusCode: code,
          technical: technical,
        );
      case DioExceptionType.unknown:
        if (e.error is SocketException) {
          return AppException(
            AppExceptionType.noConnection,
            'Нет подключения к интернету.',
            technical: technical,
          );
        }
        if (e.error is FormatException) {
          return AppException(
            AppExceptionType.parsing,
            'Не удалось обработать ответ сервера. Попробуйте позже.',
            technical: technical,
          );
        }
        return AppException(
          AppExceptionType.unknown,
          'Что-то пошло не так. Попробуйте ещё раз.',
          technical: technical,
        );
      default:
        return AppException(
          AppExceptionType.unknown,
          'Запрос был отменён или завершился ошибкой.',
          technical: technical,
        );
    }
  }

  @override
  String toString() => 'AppException($type, $message)';
} 