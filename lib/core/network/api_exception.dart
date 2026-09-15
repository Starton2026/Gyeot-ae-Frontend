import 'package:dio/dio.dart';

/// API 명세서(1. 공통 › 에러 포맷)가 정한 오류 코드.
///
/// 화면에서 `'ANALYSIS_EXPIRED'` 같은 문자열을 직접 적지 말고 이 상수를 쓴다.
class ApiErrorCode {
  const ApiErrorCode._();

  /// 400. 필수 항목 누락·형식 오류.
  static const String validationError = 'VALIDATION_ERROR';

  /// 400. 실종자 등록 시 얼굴 미검출. 등록은 거부된다.
  ///
  /// 제보 시 얼굴 미검출은 오류가 아니다. `face_found: false`로 정상 응답이 온다.
  static const String faceNotFound = 'FACE_NOT_FOUND';

  /// 401. 토큰 없음·만료.
  static const String unauthorized = 'UNAUTHORIZED';

  /// 403. 보호자 전용 기능에 타인이 접근.
  static const String forbidden = 'FORBIDDEN';

  /// 404. 리소스 없음.
  static const String notFound = 'NOT_FOUND';

  /// 410. 분석 결과 TTL(10분) 만료. 다시 분석해야 한다.
  static const String analysisExpired = 'ANALYSIS_EXPIRED';

  /// 429. 게스트 제보 횟수 초과. 사건 1건당 10분 내 3회.
  static const String rateLimited = 'RATE_LIMITED';
}

/// 화면에서 그대로 보여줄 수 있는 형태로 정리한 API 오류.
///
/// 서버는 오류를 명세서대로
/// `{"error": {"code": "...", "message": "...", "field": "..."}}` 형태로 돌려준다.
/// 옛 Flask 형식(`{"error": "문자열"}`)과 FastAPI 형식(`{"detail": ...}`)도
/// 함께 받아둔다.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.code,
    this.field,
    this.retryAfterSeconds,
    this.isNetworkIssue = false,
  });

  /// 사용자에게 보여줄 메시지.
  final String message;

  /// HTTP 상태 코드. 응답을 못 받은 경우 null.
  final int? statusCode;

  /// 서버가 준 오류 코드. [ApiErrorCode] 참고. 옛 형식 응답이면 null.
  ///
  /// 화면이 오류마다 다르게 반응해야 할 때 쓴다. 메시지 문자열을 비교하지 않는다.
  final String? code;

  /// 문제가 된 입력 항목 이름. 등록 폼에서 해당 칸에 오류를 붙일 때 쓴다.
  final String? field;

  /// 429일 때 다시 시도할 수 있기까지 남은 초.
  final int? retryAfterSeconds;

  /// 연결 실패·타임아웃처럼 서버에 닿지 못한 경우.
  final bool isNetworkIssue;

  bool get isUnauthorized => statusCode == 401;

  /// 분석 결과가 만료됐다. 사진을 다시 분석해야 한다.
  bool get isAnalysisExpired => code == ApiErrorCode.analysisExpired;

  /// 제보 횟수 제한에 걸렸다.
  bool get isRateLimited => code == ApiErrorCode.rateLimited;

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

    final body = response.data;
    final errorObject = body is Map ? body['error'] : null;

    if (errorObject is Map) {
      final message = errorObject['message'];
      final code = errorObject['code'];
      final field = errorObject['field'];
      final retryAfter = errorObject['retry_after'];

      return ApiException(
        message is String && message.isNotEmpty ? message : _unknownMessage,
        statusCode: response.statusCode,
        code: code is String && code.isNotEmpty ? code : null,
        field: field is String && field.isNotEmpty ? field : null,
        retryAfterSeconds: retryAfter is int ? retryAfter : null,
      );
    }

    return ApiException(
      _messageFromBody(body) ?? _unknownMessage,
      statusCode: response.statusCode,
    );
  }

  /// 옛 형식 응답에서 사람이 읽을 메시지를 뽑아낸다.
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
  String toString() =>
      'ApiException($statusCode${code == null ? '' : ' $code'}): $message';
}
