import 'dart:typed_data';

import 'package:dio/dio.dart';

/// 실제 네트워크를 타지 않고 정해진 응답을 돌려주는 dio 어댑터.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter({this.statusCode = 200, this.body = '{}'});

  final int statusCode;
  final String body;

  /// 어댑터까지 도달한 마지막 요청. 인터셉터가 무엇을 붙였는지 확인할 때 쓴다.
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
