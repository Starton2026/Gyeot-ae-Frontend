import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/network/api_exception.dart';

DioException _errorWith({required int statusCode, required Object body}) {
  final options = RequestOptions(path: '/test');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: options,
      statusCode: statusCode,
      data: body,
    ),
  );
}

void main() {
  test('FastAPI의 detail 문자열을 메시지로 쓴다', () {
    final exception = ApiException.from(
      _errorWith(statusCode: 400, body: {'detail': '이미 가입된 이메일이에요.'}),
    );

    expect(exception.message, '이미 가입된 이메일이에요.');
    expect(exception.statusCode, 400);
  });

  test('Flask 서버의 error 필드를 메시지로 쓴다', () {
    final exception = ApiException.from(
      _errorWith(statusCode: 400, body: {'error': '사진에서 얼굴을 찾지 못했습니다.'}),
    );

    expect(exception.message, '사진에서 얼굴을 찾지 못했습니다.');
    expect(exception.statusCode, 400);
  });

  test('422 검증 오류는 detail 리스트의 첫 msg를 메시지로 쓴다', () {
    final exception = ApiException.from(
      _errorWith(
        statusCode: 422,
        body: {
          'detail': [
            {
              'loc': ['body', 'email'],
              'msg': '이메일 형식이 아니에요',
              'type': 'value_error',
            },
          ],
        },
      ),
    );

    expect(exception.message, '이메일 형식이 아니에요');
    expect(exception.statusCode, 422);
  });

  test('detail이 없는 서버 오류는 기본 안내 메시지를 쓴다', () {
    final exception = ApiException.from(
      _errorWith(statusCode: 500, body: 'Internal Server Error'),
    );

    expect(exception.message, isNotEmpty);
    expect(exception.statusCode, 500);
    expect(exception.isNetworkIssue, isFalse);
  });

  test('타임아웃은 네트워크 문제로 표시한다', () {
    final exception = ApiException.from(
      DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      ),
    );

    expect(exception.isNetworkIssue, isTrue);
    expect(exception.statusCode, isNull);
  });

  test('401은 인증 오류로 구분한다', () {
    final exception = ApiException.from(
      _errorWith(statusCode: 401, body: {'detail': 'Not authenticated'}),
    );

    expect(exception.isUnauthorized, isTrue);
  });
}
