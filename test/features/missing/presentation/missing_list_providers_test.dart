import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/features/missing/data/missing_case.dart';
import 'package:gyeotae/features/missing/data/missing_repository.dart';
import 'package:gyeotae/features/missing/presentation/missing_list_providers.dart';

/// 어떤 조건으로 불렸는지 기록하고, 요청한 만큼만 잘라서 돌려준다.
class _RecordingRepository implements MissingRepository {
  _RecordingRepository({this.total = 45});

  final int total;

  String? lastQuery;
  MissingCategory? lastCategory;
  CaseStatusFilter? lastStatus;
  MissingSort? lastSort;
  String? lastCursor;
  int callCount = 0;

  @override
  Future<MissingCaseList> fetchCases({
    String? query,
    MissingCategory? category,
    CaseStatusFilter status = CaseStatusFilter.active,
    MissingSort sort = MissingSort.urgency,
    double? lat,
    double? lng,
    double? radiusKm,
    int limit = 20,
    String? cursor,
  }) async {
    callCount++;
    lastQuery = query;
    lastCategory = category;
    lastStatus = status;
    lastSort = sort;
    lastCursor = cursor;

    final offset = int.tryParse(cursor ?? '') ?? 0;
    final end = (offset + limit).clamp(0, total);
    final items = [
      for (var i = offset; i < end; i++) _summary('m_$i'),
    ];

    return MissingCaseList(
      count: total,
      items: items,
      nextCursor: end < total ? '$end' : null,
    );
  }

  @override
  Future<MissingCaseDetail> fetchCase(String id) => throw UnimplementedError();

  @override
  Future<MissingCaseRegistration> register(MissingCaseDraft draft) =>
      throw UnimplementedError();
}

MissingCaseSummary _summary(String id) {
  return MissingCaseSummary(
    id: id,
    name: '김하준',
    age: 7,
    gender: Gender.male,
    category: MissingCategory.child,
    description: '노란 후드티',
    lastLat: 37.4491,
    lastLng: 126.7312,
    missingAt: DateTime(2026, 9, 12, 14, 40),
    elapsedMinutes: 192,
    status: CaseStatus.active,
    reportCount: 6,
    urgencyLevel: UrgencyLevel.critical,
  );
}

ProviderContainer _container(_RecordingRepository repository) {
  return ProviderContainer.test(
    overrides: [missingRepositoryProvider.overrideWithValue(repository)],
  );
}

void main() {
  group('조회 조건', () {
    test('기본값은 전체 · 긴급도순이고 검색어가 없다', () async {
      final repository = _RecordingRepository();
      final container = _container(repository);

      await container.read(missingListProvider.future);

      expect(repository.lastStatus, CaseStatusFilter.all);
      expect(repository.lastCategory, isNull);
      expect(repository.lastSort, MissingSort.urgency);
      expect(repository.lastQuery, isNull, reason: '빈 검색어는 보내지 않는다');
    });

    test('전체 칩은 발견 완료까지 함께 부른다', () {
      expect(MissingListFilter.all.status, CaseStatusFilter.all);
    });

    test('진행중 칩은 active만, 발견 칩은 resolved만 부른다', () async {
      final repository = _RecordingRepository();
      final container = _container(repository);
      await container.read(missingListProvider.future);

      container
          .read(missingListQueryProvider.notifier)
          .setFilter(MissingListFilter.active);
      await container.read(missingListProvider.future);
      expect(repository.lastStatus, CaseStatusFilter.active);
      expect(repository.lastCategory, isNull);

      container
          .read(missingListQueryProvider.notifier)
          .setFilter(MissingListFilter.resolved);
      await container.read(missingListProvider.future);
      expect(repository.lastStatus, CaseStatusFilter.resolved);
    });

    test('구분 칩은 category로 간다', () async {
      final repository = _RecordingRepository();
      final container = _container(repository);
      await container.read(missingListProvider.future);

      container
          .read(missingListQueryProvider.notifier)
          .setFilter(MissingListFilter.dementia);
      await container.read(missingListProvider.future);

      expect(repository.lastCategory, MissingCategory.dementia);
      expect(
        repository.lastStatus,
        CaseStatusFilter.all,
        reason: '구분 칩은 상태를 가리지 않는다',
      );
    });

    test('검색어 앞뒤 공백은 떼고 보낸다', () async {
      final repository = _RecordingRepository();
      final container = _container(repository);
      await container.read(missingListProvider.future);

      container.read(missingListQueryProvider.notifier).setKeyword('  구월동 ');
      await container.read(missingListProvider.future);

      expect(repository.lastQuery, '구월동');
    });

    test('조건이 그대로면 다시 부르지 않는다', () async {
      final repository = _RecordingRepository();
      final container = _container(repository);
      await container.read(missingListProvider.future);
      final before = repository.callCount;

      container
          .read(missingListQueryProvider.notifier)
          .setFilter(MissingListFilter.all);
      await container.read(missingListProvider.future);

      expect(repository.callCount, before);
    });
  });

  group('무한 스크롤 — F-2.6', () {
    test('다음 장을 뒤에 잇고 커서를 갱신한다', () async {
      final repository = _RecordingRepository(total: 45);
      final container = _container(repository);

      final first = await container.read(missingListProvider.future);
      expect(first.items, hasLength(20));
      expect(first.count, 45, reason: '건수는 받아온 개수가 아니라 전체 건수다');
      expect(first.hasMore, isTrue);

      await container.read(missingListProvider.notifier).loadMore();
      final second = container.read(missingListProvider).value!;

      expect(second.items, hasLength(40));
      expect(repository.lastCursor, '20');
      expect(second.hasMore, isTrue);

      await container.read(missingListProvider.notifier).loadMore();
      final third = container.read(missingListProvider).value!;

      expect(third.items, hasLength(45));
      expect(third.hasMore, isFalse, reason: '마지막 장이면 커서가 없다');
    });

    test('마지막 장에서는 더 부르지 않는다', () async {
      final repository = _RecordingRepository(total: 3);
      final container = _container(repository);

      await container.read(missingListProvider.future);
      final before = repository.callCount;

      await container.read(missingListProvider.notifier).loadMore();

      expect(repository.callCount, before);
    });
  });
}
