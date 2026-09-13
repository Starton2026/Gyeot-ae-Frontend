import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/network/api_exception.dart';
import 'package:gyeotae/features/report/data/http_report_repository.dart';
import 'package:gyeotae/features/report/data/report.dart';

import '../../../support/fake_http_adapter.dart';

/// 올릴 사진 한 장. 내용은 아무래도 좋고 파일이 있기만 하면 된다.
File _photoFile() {
  final dir = Directory.systemTemp.createTempSync('gyeotae_report');
  addTearDown(() {
    // 윈도우에서는 업로드 스트림이 파일을 잡고 있어 바로 안 지워질 때가 있다.
    try {
      dir.deleteSync(recursive: true);
    } on FileSystemException {
      // 임시 폴더라 남아도 그만이다.
    }
  });

  return File('${dir.path}/shot.jpg')..writeAsBytesSync([1, 2, 3]);
}

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

const _analysisResponse = {
  'analysis_id': 'an_1',
  'similarity': 63.4,
  'grade': 'medium',
  'face_found': true,
  'photo_url': '/uploads/tmp/an_1.jpg',
  'matched_photo_url': '/uploads/m_1.jpg',
  'expires_at': '2026-09-13T21:40:00+09:00',
};

/// 확정 응답. **보낸 값(좌표·장소)은 돌려주지 않는다.** 서버 실제 모양이다.
const _submitResponse = {
  'id': 'r_1',
  'missing_id': 'm_1',
  'similarity': 63.4,
  'grade': 'medium',
  'route_index': 2,
  'photo_url': '/uploads/r_1.jpg',
  'observed_at': '2026-09-13T20:10:00+09:00',
  'created_at': '2026-09-13T20:12:00+09:00',
  'guardian_notified': true,
};

void main() {
  group('사진 분석', () {
    test('사진과 사건 id를 multipart로 올린다', () async {
      final env = _dio(body: _analysisResponse);

      final result = await HttpReportRepository(
        env.dio,
      ).analyze(missingId: 'm_1', photoPath: _photoFile().path);

      final request = env.adapter.lastRequest!;
      expect(request.path, '/reports/analyze');
      expect(request.method, 'POST');

      // MapEntry는 값 비교가 안 돼서 키·값을 펴서 본다.
      final form = request.data as FormData;
      expect({for (final field in form.fields) field.key: field.value}, {
        'missing_id': 'm_1',
      });
      expect(form.files.map((entry) => entry.key), contains('photo'));

      expect(result.analysisId, 'an_1');
      expect(result.similarity, 63.4);
      expect(result.grade, SimilarityGrade.medium);
    });

    test('얼굴을 못 찾아도 오류가 아니다', () async {
      final env = _dio(
        body: {
          ..._analysisResponse,
          'similarity': null,
          'grade': 'no_face',
          'face_found': false,
          'matched_photo_url': null,
        },
      );

      final result = await HttpReportRepository(
        env.dio,
      ).analyze(missingId: 'm_1', photoPath: _photoFile().path);

      // 설계 결정 4번. 위치와 시간만으로도 경로 복원에 쓰인다.
      expect(result.faceFound, isFalse);
      expect(result.similarity, isNull);
      expect(result.grade, SimilarityGrade.noFace);
    });
  });

  group('제보 확정', () {
    test('서버가 안 돌려주는 값은 방금 보낸 값으로 채운다', () async {
      final env = _dio(statusCode: 201, body: _submitResponse);
      final observedAt = DateTime.parse('2026-09-13T20:10:00+09:00');

      final report = await HttpReportRepository(env.dio).submit(
        analysisId: 'an_1',
        observedAt: observedAt,
        lat: 37.47,
        lng: 126.75,
        placeName: '3번 출구 앞',
      );

      // 응답만 읽으면 좌표가 비어 완료 화면이 "위치 없이 보냈다"고 적는다.
      expect(report.lat, 37.47);
      expect(report.lng, 126.75);
      expect(report.placeName, '3번 출구 앞');
      expect(report.hasLocation, isTrue);

      expect(report.id, 'r_1');
      expect(report.routeIndex, 2);
      expect(report.status, ReportStatus.visible);
      // 등급이 no_face가 아니면 얼굴을 찾은 것이다. 서버가 둘을 같이 정한다.
      expect(report.faceFound, isTrue);
    });

    test('좌표가 없으면 아예 안 보낸다', () async {
      final env = _dio(statusCode: 201, body: _submitResponse);

      final report = await HttpReportRepository(env.dio).submit(
        analysisId: 'an_1',
        observedAt: DateTime.parse('2026-09-13T20:10:00+09:00'),
      );

      // 0,0을 채워 보내면 아무도 보지 않은 자리에 점이 찍힌다.
      final sent = env.adapter.lastRequest!.data as Map<String, dynamic>;
      expect(sent.containsKey('lat'), isFalse);
      expect(sent.containsKey('lng'), isFalse);
      expect(sent['analysis_id'], 'an_1');

      expect(report.hasLocation, isFalse);
      expect(report.isOnPath, isFalse);
      expect(sent['observed_at'], matches(r'[+-]\d{2}:\d{2}$'));
    });

    test('분석이 만료됐으면 ANALYSIS_EXPIRED로 던진다', () async {
      final env = _dio(
        statusCode: 410,
        body: {
          'error': {
            'code': 'ANALYSIS_EXPIRED',
            'message': '분석 결과가 만료되었습니다. 다시 분석해 주세요.',
          },
        },
      );

      await expectLater(
        HttpReportRepository(env.dio).submit(
          analysisId: 'an_1',
          observedAt: DateTime.now(),
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', ApiErrorCode.analysisExpired)
              .having((e) => e.isAnalysisExpired, '만료 여부', isTrue),
        ),
      );
    });

    test('제보 횟수 제한은 다시 시도할 시각까지 함께 읽는다', () async {
      final env = _dio(
        statusCode: 429,
        body: {
          'error': {
            'code': 'RATE_LIMITED',
            'message': '잠시 후 다시 시도해 주세요.',
            'retry_after': 600,
          },
        },
      );

      await expectLater(
        HttpReportRepository(env.dio).submit(
          analysisId: 'an_1',
          observedAt: DateTime.now(),
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.isRateLimited, '제한 여부', isTrue)
              .having((e) => e.retryAfterSeconds, '남은 초', 600),
        ),
      );
    });
  });

  group('제보 목록', () {
    test('표시 필터를 질의로 넘긴다', () async {
      final env = _dio(
        body: {
          'missing_id': 'm_1',
          'count': 0,
          'hidden_count': 2,
          'reports': <Object>[],
          'path': <Object>[],
        },
      );

      final bundle = await HttpReportRepository(env.dio).fetchReports(
        'm_1',
        minSimilarity: 40,
        includeLow: false,
        until: DateTime.parse('2026-09-13T20:00:00+09:00'),
      );

      final query = env.adapter.lastRequest!.queryParameters;
      expect(env.adapter.lastRequest!.path, '/missing/m_1/reports');
      expect(query['min_similarity'], 40);
      expect(query['include_low'], false);
      // 오프셋 없이 보내면 서버가 KST라고 넘겨짚는다. 같은 순간을 가리키되
      // 오프셋이 붙어 있어야 한다.
      expect(query['until'], matches(r'[+-]\d{2}:\d{2}$'));
      expect(
        DateTime.parse(query['until'] as String).toUtc(),
        DateTime.parse('2026-09-13T20:00:00+09:00').toUtc(),
      );

      // 거른 제보는 지운 것이 아니라 숨긴 것이다(설계 결정 3번).
      expect(bundle.hiddenCount, 2);
    });
  });
}
