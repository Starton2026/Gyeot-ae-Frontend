import 'package:dio/dio.dart';

/// 화면에서 그대로 보여줄 수 있는 형태로 정리한 API 오류.
///
/// 서버는 오류를 `{"error": "..."}` 형태로 돌려준다 (Flask).
/// `{"detail": ...}`(FastAPI/검증 오류) 형태도 함께 받아둔다.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.isNetworkIssue = false,
  });

  /// 사용자에게 보여줄 메시지.
  final String message;

  /// HTTP 상태 코드. 응답을 못 받은 경우 null.
  final int? statusCode;

  /// 연결 실패·타임아웃처럼 서버에 닿지 못한 경우.
  final bool isNetworkIssue;

  bool get isUnauthorized => statusCode == 401;

  static const _networkMessage = '네트워크 연결을 확인해 주세요.';
  static const _unknownMessage = '일시적인 오류가 발생했어요. 잠시 후 다시 시도해 주세요.';

  factory ApiException.from(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return const ApiException(_networkMessage, isNetworkIssue: true);
      case DioExceptionType.cancel:
        return const ApiException('요청이 취소됐어요.');
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break;
    }

    final response = error.response;
    if (response == null) {
      return const ApiException(_unknownMessage, isNetworkIssue: true);
    }

    return ApiException(
      _messageFromBody(response.data) ?? _unknownMessage,
      statusCode: response.statusCode,
    );
  }

  /// FastAPI 응답 본문에서 사람이 읽을 메시지를 뽑아낸다.
  static String? _messageFromBody(Object? body) {
    if (body is! Map) return null;

    final error = body['error'];
    if (error is String && error.isNotEmpty) return error;

    final detail = body['detail'];
    if (detail is String && detail.isNotEmpty) return detail;

    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first['msg'] is String) return first['msg'] as String;
    }

    final message = body['message'];
    if (message is String && message.isNotEmpty) return message;

    return null;
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
