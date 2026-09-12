import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/mock/mock_backend.dart';
import 'package:gyeotae/core/network/api_exception.dart';
import 'package:gyeotae/features/missing/data/missing_case.dart';
import 'package:gyeotae/features/missing/data/mock_missing_repository.dart';

MockMissingRepository _repository([MockBackend? backend]) {
  return MockMissingRepository(
    backend ?? MockBackend.seeded(),
    latency: Duration.zero,
  );
}

void main() {
  group('시드 데이터', () {
    test('사건이 여러 건 있고 발견 완료가 섞여 있다', () async {
      final all = await _repository().fetchCases(status: CaseStatusFilter.all);

      expect(all.items.length, greaterThanOrEqualTo(5));
      expect(
        all.items.where((c) => c.status == CaseStatus.resolved),
        isNotEmpty,
        reason: '설계 결정 7번 — 발견 완료 사건도 목록에 남는다',
      );
    });

    test('골든타임 안에 있는 사건이 있다', () async {
      final list = await _repository().fetchCases();

      expect(
        list.items.where((c) => c.elapsedMinutes < 180),
        isNotEmpty,
        reason: '고정 날짜를 박으면 데모 때 골든타임 배너가 안 뜬다',
      );
    });

    test('경과 시간은 실종 시각과 맞아떨어진다', () async {
      final list = await _repository().fetchCases();
      final item = list.items.first;
      final computed = DateTime.now().difference(item.missingAt).inMinutes;

      expect(
        item.elapsedMinutes,
        closeTo(computed, 2),
        reason: '설계 결정 6번 — 경과 시간은 서버(여기선 mock)가 계산한다',
      );
    });

    test('아동과 어르신이 모두 있다', () async {
      final list = await _repository().fetchCases(status: CaseStatusFilter.all);
      final categories = list.items.map((c) => c.category).toSet();

      expect(categories, contains(MissingCategory.child));
      expect(categories, contains(MissingCategory.elderly));
    });
  });

  group('fetchCases', () {
    test('기본은 진행중만 준다', () async {
      final list = await _repository().fetchCases();

      expect(list.items.every((c) => c.status == CaseStatus.active), isTrue);
    });

    test('이름으로 검색한다', () async {
      final repository = _repository();
      final all = await repository.fetchCases(status: CaseStatusFilter.all);
      final target = all.items.first;

      final found = await repository.fetchCases(
        query: target.name,
        status: CaseStatusFilter.all,
      );

      expect(found.items.map((c) => c.id), contains(target.id));
    });

    test('지역으로도 검색한다', () async {
      final repository = _repository();
      final all = await repository.fetchCases(status: CaseStatusFilter.all);
      final withAddress = all.items.firstWhere((c) => c.lastAddress != null);
      final keyword = withAddress.lastAddress!.split(' ').first;

      final found = await repository.fetchCases(
        query: keyword,
        status: CaseStatusFilter.all,
      );

      expect(found.items, isNotEmpty);
    });

    test('찾는 게 없으면 빈 목록을 준다', () async {
      final list = await _repository().fetchCases(query: '없는이름zzz');

      expect(list.items, isEmpty);
      expect(list.count, 0);
    });

    test('분류로 거른다', () async {
      final list = await _repository().fetchCases(
        category: MissingCategory.elderly,
        status: CaseStatusFilter.all,
      );

      expect(list.items, isNotEmpty);
      expect(
        list.items.every((c) => c.category == MissingCategory.elderly),
        isTrue,
      );
    });

    test('최신순은 실종 시각 내림차순이다', () async {
      final list = await _repository().fetchCases(
        sort: MissingSort.recent,
        status: CaseStatusFilter.all,
      );
      final times = list.items.map((c) => c.missingAt).toList();

      for (var i = 1; i < times.length; i++) {
        expect(times[i].isAfter(times[i - 1]), isFalse);
      }
    });

    test('긴급도순은 점수 내림차순이다', () async {
      final list = await _repository().fetchCases(sort: MissingSort.urgency);
      final scores = list.items.map((c) => c.urgencyScore ?? 0).toList();

      for (var i = 1; i < scores.length; i++) {
        expect(scores[i], lessThanOrEqualTo(scores[i - 1]));
      }
    });

    test('위치를 주면 거리를 채우고 거리순으로 정렬한다', () async {
      final list = await _repository().fetchCases(
        sort: MissingSort.distance,
        lat: 37.4491,
        lng: 126.7312,
      );

      expect(list.items.every((c) => c.distanceKm != null), isTrue);

      final distances = list.items.map((c) => c.distanceKm!).toList();
      for (var i = 1; i < distances.length; i++) {
        expect(distances[i], greaterThanOrEqualTo(distances[i - 1]));
      }
    });

    test('위치를 안 주면 거리가 null이다', () async {
      final list = await _repository().fetchCases();

      expect(list.items.every((c) => c.distanceKm == null), isTrue);
    });

    test('limit과 cursor로 나눠 준다', () async {
      final repository = _repository();
      final first = await repository.fetchCases(
        limit: 2,
        status: CaseStatusFilter.all,
      );

      expect(first.items, hasLength(2));
      expect(first.hasMore, isTrue);

      final second = await repository.fetchCases(
        limit: 2,
        cursor: first.nextCursor,
        status: CaseStatusFilter.all,
      );
      final firstIds = first.items.map((c) => c.id).toSet();

      expect(second.items, isNotEmpty);
      expect(second.items.any((c) => firstIds.contains(c.id)), isFalse);
    });

    test('count는 거른 뒤의 전체 건수다', () async {
      final repository = _repository();
      final all = await repository.fetchCases(status: CaseStatusFilter.all);
      final page = await repository.fetchCases(
        limit: 2,
        status: CaseStatusFilter.all,
      );

      expect(page.count, all.items.length);
    });
  });

  group('fetchCase', () {
    test('목록의 사건을 상세로 가져온다', () async {
      final repository = _repository();
      final list = await repository.fetchCases(status: CaseStatusFilter.all);
      final target = list.items.first;

      final detail = await repository.fetchCase(target.id);

      expect(detail.id, target.id);
      expect(detail.name, target.name);
      expect(detail.photos, isNotEmpty);
    });

    test('없는 사건은 NOT_FOUND로 던진다', () async {
      await expectLater(
        _repository().fetchCase('m_없는사건'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', ApiErrorCode.notFound)
              .having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });
  });

  group('register', () {
    const draft = MissingCaseDraft(
      name: '박서연',
      age: 6,
      gender: Gender.female,
      category: MissingCategory.child,
      description: '분홍 원피스, 흰 운동화',
      lastLat: 37.45,
      lastLng: 126.73,
      guardianPhone: '010-0000-0000',
      photoPaths: ['a.jpg', 'b.jpg'],
    );

    test('등록하면 목록에 늘어난다', () async {
      final repository = _repository();
      final before = await repository.fetchCases(status: CaseStatusFilter.all);

      final created = await repository.register(draft);
      final after = await repository.fetchCases(status: CaseStatusFilter.all);

      expect(created.faceEncodingCount, 2);
      expect(created.notifiedDevices, greaterThan(0));
      expect(after.items.length, before.items.length + 1);
      expect(after.items.map((c) => c.id), contains(created.id));
    });

    test('등록한 사건을 바로 상세로 볼 수 있다', () async {
      final repository = _repository();
      final created = await repository.register(draft);

      final detail = await repository.fetchCase(created.id);

      expect(detail.name, '박서연');
      expect(detail.isGuardian, isTrue, reason: '내가 등록한 사건이다');
    });

    test('사진이 없으면 FACE_NOT_FOUND로 거부한다', () async {
      await expectLater(
        _repository().register(
          const MissingCaseDraft(
            name: '박서연',
            age: 6,
            gender: Gender.female,
            category: MissingCategory.child,
            description: '분홍 원피스',
            lastLat: 37.45,
            lastLng: 126.73,
            guardianPhone: '010-0000-0000',
            photoPaths: [],
          ),
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.faceNotFound,
          ),
        ),
      );
    });
  });
}
