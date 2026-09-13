import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/network/api_exception.dart';
import 'package:gyeotae/features/missing/data/http_missing_repository.dart';
import 'package:gyeotae/features/missing/data/missing_case.dart';

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

File _photoFile(String name) {
  final dir = Directory.systemTemp.createTempSync('gyeotae_missing');
  addTearDown(() {
    try {
      dir.deleteSync(recursive: true);
    } on FileSystemException {
      // 업로드 스트림이 잡고 있으면 못 지운다. 임시 폴더라 그냥 둔다.
    }
  });

  return File('${dir.path}/$name')..writeAsBytesSync([1, 2, 3]);
}

const _summary = {
  'id': 'm_1',
  'name': '김하준',
  'age': 7,
  'gender': 'male',
  'category': 'child',
  'description': '노란 후드티',
  'thumbnail': '/uploads/m_1_thumb.jpg',
  'last_lat': 37.47,
  'last_lng': 126.75,
  'last_address': '인천 남동구',
  'missing_at': '2026-09-13T17:00:00+09:00',
  'elapsed_minutes': 185,
  'status': 'active',
  'report_count': 3,
  'urgency_score': 4.5,
  'urgency_level': 'high',
  'distance_km': 1.2,
};

void main() {
  group('목록', () {
    test('검색·필터·정렬·좌표를 질의로 넘긴다', () async {
      final env = _dio(
        body: {
          'count': 1,
          'next_cursor': '20',
          'items': [_summary],
        },
      );

      final list = await HttpMissingRepository(env.dio).fetchCases(
        query: '  김  ',
        category: MissingCategory.child,
        status: CaseStatusFilter.all,
        sort: MissingSort.distance,
        lat: 37.47,
        lng: 126.75,
        radiusKm: 3,
        limit: 20,
      );

      final query = env.adapter.lastRequest!.queryParameters;
      expect(env.adapter.lastRequest!.path, '/missing');
      expect(query['q'], '김', reason: '앞뒤 공백은 서버로 넘기지 않는다');
      expect(query['category'], 'child');
      expect(query['status'], 'all');
      expect(query['sort'], 'distance');
      expect(query['lat'], 37.47);
      expect(query['lng'], 126.75);
      expect(query['radius_km'], 3);

      expect(list.count, 1);
      expect(list.nextCursor, '20');
      expect(list.items.single.name, '김하준');
      expect(list.items.single.distanceKm, 1.2);
    });

    test('좌표가 없으면 거리 관련 값을 안 보낸다', () async {
      final env = _dio(
        body: {'count': 0, 'items': <Object>[]},
      );

      await HttpMissingRepository(env.dio).fetchCases();

      // 위치 권한을 거부해도 목록은 보인다. 긴급도에서 거리 가중치만 빠진다.
      final query = env.adapter.lastRequest!.queryParameters;
      expect(query.containsKey('lat'), isFalse);
      expect(query.containsKey('lng'), isFalse);
      expect(query.containsKey('q'), isFalse);
      expect(query['status'], 'active');
      expect(query['sort'], 'urgency');
    });
  });

  group('상세', () {
    test('없는 사건이면 NOT_FOUND로 던진다', () async {
      final env = _dio(
        statusCode: 404,
        body: {
          'error': {
            'code': 'NOT_FOUND',
            'message': '존재하지 않는 실종자입니다: m_9',
          },
        },
      );

      await expectLater(
        HttpMissingRepository(env.dio).fetchCase('m_9'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', ApiErrorCode.notFound)
              .having((e) => e.statusCode, 'status', 404),
        ),
      );
    });

    test('서버가 닿지 않으면 네트워크 문제로 표시한다', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.httpClientAdapter = _ThrowingAdapter();

      await expectLater(
        HttpMissingRepository(dio).fetchCase('m_1'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.isNetworkIssue,
            '네트워크 문제',
            isTrue,
          ),
        ),
      );
    });
  });

  group('등록', () {
    test('사진 여러 장과 폼 값을 multipart로 올린다', () async {
      final env = _dio(
        statusCode: 201,
        body: {
          'id': 'm_2',
          'name': '김하준',
          'photos': ['/uploads/m_2_a.jpg', '/uploads/m_2_b.jpg'],
          'face_encoding_count': 2,
          'notified_devices': 0,
        },
      );

      final result = await HttpMissingRepository(env.dio).register(
        MissingCaseDraft(
          name: '김하준',
          age: 7,
          gender: Gender.male,
          category: MissingCategory.child,
          description: '노란 후드티',
          lastLat: 37.47,
          lastLng: 126.75,
          guardianPhone: '010-0000-0000',
          missingAt: DateTime.parse('2026-09-13T17:00:00+09:00'),
          photoPaths: [_photoFile('a.jpg').path, _photoFile('b.jpg').path],
        ),
      );

      final form = env.adapter.lastRequest!.data as FormData;
      final fields = {
        for (final field in form.fields) field.key: field.value,
      };

      expect(fields['name'], '김하준');
      expect(fields['age'], '7');
      expect(fields['gender'], 'male');
      expect(fields['category'], 'child');
      expect(fields['last_lat'], '37.47');
      // 오프셋이 붙어야 서버가 시각을 넘겨짚지 않는다.
      expect(fields['missing_at'], matches(r'[+-]\d{2}:\d{2}$'));

      // 여러 장일수록 대조 정확도가 오른다. 한 장으로 줄여 보내면 안 된다.
      expect(form.files.where((entry) => entry.key == 'photos'), hasLength(2));

      expect(result.id, 'm_2');
      expect(result.faceEncodingCount, 2);
    });

    test('모든 사진에서 얼굴을 못 찾으면 거부된다', () async {
      final env = _dio(
        statusCode: 400,
        body: {
          'error': {
            'code': 'FACE_NOT_FOUND',
            'message': '사진에서 얼굴을 찾지 못했습니다.',
            'field': 'photos',
          },
        },
      );

      // 제보와 달리 등록은 얼굴이 있어야 한다(설계 결정 4번).
      await expectLater(
        HttpMissingRepository(env.dio).register(
          MissingCaseDraft(
            name: '김하준',
            age: 7,
            gender: Gender.male,
            category: MissingCategory.child,
            description: '',
            lastLat: 37.47,
            lastLng: 126.75,
            guardianPhone: '010-0000-0000',
            photoPaths: [_photoFile('a.jpg').path],
          ),
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', ApiErrorCode.faceNotFound)
              .having((e) => e.field, '문제가 된 칸', 'photos'),
        ),
      );
    });
  });
}

/// 서버에 닿지 못하는 상황.
class _ThrowingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException.connectionError(
      requestOptions: options,
      reason: '연결 실패',
    );
  }

  @override
  void close({bool force = false}) {}
}
