import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/network/api_exception.dart';
import 'package:gyeotae/features/missing/data/missing_case.dart';
import 'package:gyeotae/features/my/data/my_repository.dart';
import 'package:gyeotae/features/report/data/report.dart';

import '../../../support/fake_http_adapter.dart';

({Dio dio, FakeHttpAdapter adapter}) _dio({
  int statusCode = 200,
  Object body = const <String, dynamic>{},
}) {
  final adapter = FakeHttpAdapter(
    statusCode: statusCode,
    body: jsonEncode(body),
  );
  final dio = Dio(BaseOptions(baseUrl: 'http://test'))
    ..httpClientAdapter = adapter;

  return (dio: dio, adapter: adapter);
}

void main() {
  test('내 제보 이력을 읽는다', () async {
    final env = _dio(
      body: {
        'count': 2,
        'items': [
          {
            'id': 'r_01',
            'missing_name': '김하준',
            'missing_thumbnail': '/uploads/m_1_thumb.jpg',
            'missing_status': 'resolved',
            'similarity': 82.1,
            'grade': 'high',
            'observed_at': '2026-09-13T17:12:00+09:00',
            'contributed_to_path': true,
          },
          {
            'id': 'r_02',
            'missing_name': '이순자',
            'missing_thumbnail': null,
            'missing_status': 'active',
            'similarity': null,
            'grade': 'no_face',
            'observed_at': '2026-09-09T15:40:00+09:00',
            'contributed_to_path': false,
          },
        ],
      },
    );

    final list = await HttpMyRepository(env.dio).fetchMyReports();

    expect(env.adapter.lastRequest!.path, '/me/reports');

    expect(list.count, 2);
    expect(list.items.first.missingName, '김하준');
    expect(list.items.first.missingStatus, CaseStatus.resolved);
    expect(list.items.first.contributedToPath, isTrue);

    // 얼굴을 못 찾은 제보도 이력에 남는다(설계 결정 4번).
    expect(list.items.last.similarity, isNull);
    expect(list.items.last.grade, SimilarityGrade.noFace);
    expect(list.items.last.missingThumbnail, isNull);
  });

  test('제보가 없으면 빈 묶음이다', () async {
    final env = _dio(body: {'count': 0, 'items': <Object>[]});

    final list = await HttpMyRepository(env.dio).fetchMyReports();

    expect(list.isEmpty, isTrue);
    expect(list.count, 0);
  });

  test('서버가 닿지 않으면 ApiException으로 바꿔 던진다', () async {
    final env = _dio(
      statusCode: 500,
      body: {
        'error': {'code': 'INTERNAL', 'message': '서버 오류'},
      },
    );

    await expectLater(
      HttpMyRepository(env.dio).fetchMyReports(),
      throwsA(isA<ApiException>()),
    );
  });
}
