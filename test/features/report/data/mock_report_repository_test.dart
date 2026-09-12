import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/mock/mock_backend.dart';
import 'package:gyeotae/core/network/api_exception.dart';
import 'package:gyeotae/features/report/data/mock_report_repository.dart';
import 'package:gyeotae/features/report/data/report.dart';

/// 시드 데이터에서 제보가 가장 많이 달린 사건. 타임라인·경로를 볼 수 있다.
const _caseId = MockBackend.demoCaseId;

({MockBackend backend, MockReportRepository repository}) _fixture() {
  final backend = MockBackend.seeded();

  return (
    backend: backend,
    repository: MockReportRepository(backend, latency: Duration.zero),
  );
}

void main() {
  group('시드 데이터', () {
    test('데모 사건에 등급 4종이 모두 달려 있다', () async {
      final bundle = await _fixture().repository.fetchReports(_caseId);
      final grades = bundle.reports.map((r) => r.grade).toSet();

      expect(grades, contains(SimilarityGrade.high));
      expect(grades, contains(SimilarityGrade.medium));
      expect(grades, contains(SimilarityGrade.low));
      expect(grades, contains(SimilarityGrade.noFace));
    });

    test('40% 미만 제보도 저장돼 있다', () async {
      final bundle = await _fixture().repository.fetchReports(_caseId);

      expect(
        bundle.reports.where((r) => !r.grade.countsTowardPath),
        isNotEmpty,
        reason: '설계 결정 3번 — 임계값은 삭제 기준이 아니다',
      );
    });
  });

  group('fetchReports', () {
    test('타임라인은 최신순, 경로는 시간순이다', () async {
      final bundle = await _fixture().repository.fetchReports(_caseId);

      final observed = bundle.reports.map((r) => r.observedAt).toList();
      for (var i = 1; i < observed.length; i++) {
        expect(observed[i].isAfter(observed[i - 1]), isFalse);
      }

      final pathTimes = bundle.path.map((p) => p.at).toList();
      for (var i = 1; i < pathTimes.length; i++) {
        expect(pathTimes[i].isBefore(pathTimes[i - 1]), isFalse);
      }
    });

    test('경로의 첫 점은 최초 실종 지점이다', () async {
      final bundle = await _fixture().repository.fetchReports(_caseId);

      expect(bundle.origin, isNotNull);
      expect(bundle.path.first.isOrigin, isTrue);
      expect(bundle.path.first.index, 0);
      expect(bundle.path.first.lat, bundle.origin!.lat);
    });

    test('경로에는 40% 이상 제보만 들어간다', () async {
      final bundle = await _fixture().repository.fetchReports(_caseId);
      final onPath = bundle.reports.where((r) => r.isOnPath).length;

      expect(bundle.path.length, onPath + 1, reason: '실종 지점 1개가 더 있다');
    });

    test('route_index는 1부터 순서대로 붙는다', () async {
      final bundle = await _fixture().repository.fetchReports(_caseId);
      final indexes =
          bundle.reports
              .where((r) => r.isOnPath)
              .map((r) => r.routeIndex!)
              .toList()
            ..sort();

      expect(indexes, List.generate(indexes.length, (i) => i + 1));
    });

    test('경로 정렬 기준은 observedAt이다', () async {
      final bundle = await _fixture().repository.fetchReports(_caseId);
      final onPath = bundle.reports.where((r) => r.isOnPath).toList()
        ..sort((a, b) => a.routeIndex!.compareTo(b.routeIndex!));

      for (var i = 1; i < onPath.length; i++) {
        expect(onPath[i].observedAt.isBefore(onPath[i - 1].observedAt), isFalse);
      }
    });

    test('min_similarity로 거른다', () async {
      final bundle = await _fixture().repository.fetchReports(
        _caseId,
        minSimilarity: 60,
      );

      expect(bundle.reports, isNotEmpty);
      expect(
        bundle.reports.every((r) => (r.similarity ?? 0) >= 60),
        isTrue,
      );
    });

    test('includeLow가 false면 40% 미만을 뺀다', () async {
      final bundle = await _fixture().repository.fetchReports(
        _caseId,
        includeLow: false,
      );

      expect(bundle.reports.every((r) => r.grade.countsTowardPath), isTrue);
    });

    test('until로 그 시각까지만 본다', () async {
      final repository = _fixture().repository;
      final all = await repository.fetchReports(_caseId);
      final cutoff = all.reports.last.observedAt;

      final limited = await repository.fetchReports(_caseId, until: cutoff);

      expect(limited.reports, isNotEmpty);
      expect(
        limited.reports.every((r) => !r.observedAt.isAfter(cutoff)),
        isTrue,
      );
      expect(limited.reports.length, lessThan(all.reports.length));
    });

    test('없는 사건은 NOT_FOUND로 던진다', () async {
      await expectLater(
        _fixture().repository.fetchReports('m_없는사건'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.notFound,
          ),
        ),
      );
    });
  });

  group('analyze', () {
    test('분석 결과를 돌려준다', () async {
      final result = await _fixture().repository.analyze(
        missingId: _caseId,
        photoPath: 'photo.jpg',
      );

      expect(result.analysisId, isNotEmpty);
      expect(result.photoUrl, isNotEmpty);
      expect(result.expiresAt.isAfter(DateTime.now()), isTrue);
    });

    test('여러 번 부르면 등급이 돌아가며 나온다', () async {
      final repository = _fixture().repository;
      final grades = <SimilarityGrade>{};

      for (var i = 0; i < 4; i++) {
        final result = await repository.analyze(
          missingId: _caseId,
          photoPath: 'photo.jpg',
        );
        grades.add(result.grade);
      }

      expect(
        grades.length,
        greaterThan(1),
        reason: '데모에서 등급별 UI를 다 보여줄 수 있어야 한다',
      );
    });

    test('얼굴 미검출도 정상 결과다', () async {
      final repository = _fixture().repository;
      final results = <bool>[];

      for (var i = 0; i < 4; i++) {
        final result = await repository.analyze(
          missingId: _caseId,
          photoPath: 'photo.jpg',
        );
        results.add(result.faceFound);
      }

      expect(results, contains(false));
    });

    test('없는 사건을 분석하면 NOT_FOUND로 던진다', () async {
      await expectLater(
        _fixture().repository.analyze(
          missingId: 'm_없는사건',
          photoPath: 'photo.jpg',
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('submit', () {
    test('제보를 확정하면 타임라인에 바로 보인다', () async {
      final repository = _fixture().repository;
      final before = await repository.fetchReports(_caseId);

      final analysis = await repository.analyze(
        missingId: _caseId,
        photoPath: 'photo.jpg',
      );
      final created = await repository.submit(
        analysisId: analysis.analysisId,
        lat: 37.4622,
        lng: 126.7401,
        placeName: '만수주공 앞 버스정류장',
        observedAt: DateTime.now(),
      );

      final after = await repository.fetchReports(_caseId);

      expect(after.count, before.count + 1);
      expect(after.reports.map((r) => r.id), contains(created.id));
      expect(after.reports.first.id, created.id, reason: '가장 최근 목격이다');
    });

    test('40% 이상이면 경로 번호를 받고 경로가 늘어난다', () async {
      final repository = _fixture().repository;
      final before = await repository.fetchReports(_caseId);

      Report? created;
      for (var i = 0; i < 6 && created == null; i++) {
        final analysis = await repository.analyze(
          missingId: _caseId,
          photoPath: 'photo.jpg',
        );
        if (!analysis.grade.countsTowardPath) continue;

        created = await repository.submit(
          analysisId: analysis.analysisId,
          lat: 37.4622,
          lng: 126.7401,
          observedAt: DateTime.now(),
        );
      }

      expect(created, isNotNull);
      expect(created!.routeIndex, isNotNull);

      final after = await repository.fetchReports(_caseId);
      expect(after.path.length, before.path.length + 1);
    });

    test('40% 미만이면 저장은 되고 경로 번호는 없다', () async {
      final repository = _fixture().repository;
      final before = await repository.fetchReports(_caseId);

      Report? created;
      for (var i = 0; i < 6 && created == null; i++) {
        final analysis = await repository.analyze(
          missingId: _caseId,
          photoPath: 'photo.jpg',
        );
        if (analysis.grade.countsTowardPath) continue;

        created = await repository.submit(
          analysisId: analysis.analysisId,
          lat: 37.4622,
          lng: 126.7401,
          observedAt: DateTime.now(),
        );
      }

      expect(created, isNotNull);
      expect(created!.routeIndex, isNull);

      final after = await repository.fetchReports(_caseId);
      expect(after.count, before.count + 1, reason: '설계 결정 3번 — 저장은 한다');
      expect(after.path.length, before.path.length, reason: '경로에는 안 들어간다');
    });

    test('같은 분석을 두 번 확정할 수 없다', () async {
      final repository = _fixture().repository;
      final analysis = await repository.analyze(
        missingId: _caseId,
        photoPath: 'photo.jpg',
      );

      await repository.submit(
        analysisId: analysis.analysisId,
        lat: 37.4622,
        lng: 126.7401,
        observedAt: DateTime.now(),
      );

      await expectLater(
        repository.submit(
          analysisId: analysis.analysisId,
          lat: 37.4622,
          lng: 126.7401,
          observedAt: DateTime.now(),
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.isAnalysisExpired,
            'isAnalysisExpired',
            isTrue,
          ),
        ),
      );
    });

    test('없는 분석 아이디는 ANALYSIS_EXPIRED로 던진다', () async {
      await expectLater(
        _fixture().repository.submit(
          analysisId: 'an_없는분석',
          lat: 37.4622,
          lng: 126.7401,
          observedAt: DateTime.now(),
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', ApiErrorCode.analysisExpired)
              .having((e) => e.statusCode, 'statusCode', 410),
        ),
      );
    });

    test('사진첩에서 늦게 올려도 목격 시각 순서대로 경로에 낀다', () async {
      final repository = _fixture().repository;
      final before = await repository.fetchReports(_caseId);
      final earliestOnPath = before.reports
          .where((r) => r.isOnPath)
          .map((r) => r.observedAt)
          .reduce((a, b) => a.isBefore(b) ? a : b);

      Report? created;
      for (var i = 0; i < 6 && created == null; i++) {
        final analysis = await repository.analyze(
          missingId: _caseId,
          photoPath: 'photo.jpg',
        );
        if (!analysis.grade.countsTowardPath) continue;

        created = await repository.submit(
          analysisId: analysis.analysisId,
          lat: 37.4500,
          lng: 126.7350,
          observedAt: earliestOnPath.subtract(const Duration(minutes: 5)),
        );
      }

      expect(created, isNotNull);
      expect(
        created!.routeIndex,
        1,
        reason: '설계 결정 5번 — 경로 정렬은 created_at이 아니라 observed_at이다',
      );
    });
  });
}
