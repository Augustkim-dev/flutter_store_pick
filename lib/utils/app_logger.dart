import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: kDebugMode ? Level.debug : Level.warning,
    filter: kDebugMode ? DevelopmentFilter() : ProductionFilter(),
  );

  // Debug level - 개발 중 상세 정보
  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  // Info level - 일반 정보
  static void i(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  // Warning level - 경고
  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  // Error level - 에러
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  // Fatal level - 치명적 에러
  static void f(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  // 특정 태그와 함께 로그
  static void logWithTag(String tag, String message, {Level level = Level.info}) {
    final taggedMessage = '[$tag] $message';
    switch (level) {
      case Level.debug:
        d(taggedMessage);
        break;
      case Level.info:
        i(taggedMessage);
        break;
      case Level.warning:
        w(taggedMessage);
        break;
      case Level.error:
        e(taggedMessage);
        break;
      case Level.fatal:
        f(taggedMessage);
        break;
      default:
        i(taggedMessage);
    }
  }

  // API 요청/응답 로깅
  static void logApiRequest(String method, String url, [dynamic data]) {
    if (kDebugMode) {
      d('🌐 API Request: $method $url', data);
    }
  }

  static void logApiResponse(String method, String url, int statusCode, [dynamic data]) {
    if (kDebugMode) {
      if (statusCode >= 200 && statusCode < 300) {
        d('✅ API Response: $method $url - $statusCode', data);
      } else {
        w('⚠️ API Response: $method $url - $statusCode', data);
      }
    }
  }

  // 성능 측정 로깅
  static void logPerformance(String operation, int milliseconds) {
    if (kDebugMode) {
      d('⏱️ Performance: $operation took ${milliseconds}ms');
    }
  }

  // 사용자 액션 로깅
  static void logUserAction(String action, [Map<String, dynamic>? params]) {
    if (kDebugMode) {
      d('👤 User Action: $action', params);
    }
  }
}