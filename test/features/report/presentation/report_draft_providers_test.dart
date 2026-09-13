import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/media/photo_picker.dart';
import 'package:gyeotae/core/mock/mock_backend.dart';
import 'package:gyeotae/features/report/data/mock_report_repository.dart';
import 'package:gyeotae/features/report/data/report.dart';
import 'package:gyeotae/features/report/data/report_repository.dart';
import 'package:gyeotae/features/report/presentation/report_draft_providers.dart';

import '../../../support/fake_photo_picker.dart';

const _caseId = MockBackend.demoCaseId;

({ProviderContainer container, MockBackend backend, FakePhotoPicker picker})
_setUp({String? photoPath = '/tmp/shot.jpg'}) {
  final backend = MockBackend.seeded();
  final picker = FakePhotoPicker(photoPath);
  final container = ProviderContainer.test(
    overrides: [
      photoPickerProvider.overrideWithValue(picker),
      reportRepositoryProvider.overrideWithValue(
        MockReportRepository(backend, latency: Duration.zero),
      ),
    ],
  );

  return (container: container, backend: backend, picker: picker);
}

void main() {
  group('사진 첨부(F-4.2)', () {
    test('고르면 담긴다', () async {
      final env = _setUp();
      final notifier = env.container.read(
        reportDraftProvider(_caseId).notifier,
      );

      await notifier.pickPhoto(PhotoSource.camera);

      expect(env.container.read(reportDraftProvider(_caseId)).photoPath,
          '/tmp/shot.jpg');
      expect(env.picker.calls, [PhotoSource.camera]);
    });

    test('고르지 않으면 아무 일도 일어나지 않는다', () async {
      final env = _setUp(photoPath: null);
      final notifier = env.container.read(
        reportDraftProvider(_caseId).notifier,
      );

      await notifier.pickPhoto(PhotoSource.gallery);

      final draft = env.container.read(reportDraftProvider(_caseId));
      expect(draft.hasPhoto, isFalse, reason: '권한 거부도 같은 경로다');
      expect(draft.hasWorkInProgress, isFalse, reason: '나갈 때 묻지 않아야 한다');
    });

    test('사진을 바꾸면 앞선 분석은 버린다', () async {
      final env = _setUp();
      final notifier = env.container.read(
        reportDraftProvider(_caseId).notifier,
      );

      await notifier.pickPhoto(PhotoSource.camera);
      await notifier.analyze();
      expect(env.container.read(reportDraftProvider(_caseId)).isAnalyzed, isTrue);

      env.picker.path = '/tmp/other.jpg';
      await notifier.pickPhoto(PhotoSource.camera);

      expect(
        env.container.read(reportDraftProvider(_caseId)).isAnalyzed,
        isFalse,
        reason: '다른 사진의 유사도를 그대로 두면 엉뚱한 제보가 확정된다',
      );
    });
  });

  group('분석과 제보(F-4.5·F-4.6)', () {
    test('분석 전에는 제보할 수 없다', () async {
      final env = _setUp();
      final notifier = env.container.read(
        reportDraftProvider(_caseId).notifier,
      );

      await notifier.pickPhoto(PhotoSource.camera);

      expect(env.container.read(reportDraftProvider(_caseId)).canSubmit, isFalse);
      expect(await notifier.submit(), isNull);
    });

    test('사진이 없으면 분석하지 않는다', () async {
      final env = _setUp(photoPath: null);
      final notifier = env.container.read(
        reportDraftProvider(_caseId).notifier,
      );

      await notifier.analyze();

      final draft = env.container.read(reportDraftProvider(_caseId));
      expect(draft.isAnalyzing, isFalse);
      expect(draft.isAnalyzed, isFalse);
    });

    test('분석을 마치면 결과가 남고 제보 버튼이 살아난다', () async {
      final env = _setUp();
      final notifier = env.container.read(
        reportDraftProvider(_caseId).notifier,
      );

      await notifier.pickPhoto(PhotoSource.camera);
      await notifier.analyze();

      final draft = env.container.read(reportDraftProvider(_caseId));
      expect(draft.analysisResult, isNotNull);
      expect(draft.analysisResult!.grade, SimilarityGrade.medium);
      expect(draft.canSubmit, isTrue);
    });

    test('제보하면 저장되고 목격 시각이 그대로 간다', () async {
      final env = _setUp();
      final notifier = env.container.read(
        reportDraftProvider(_caseId).notifier,
      );
      final observedAt = DateTime.now().subtract(const Duration(hours: 2));

      await notifier.pickPhoto(PhotoSource.camera);
      await notifier.analyze();
      notifier.setObservedAt(observedAt);
      notifier.setPlaceName(' 만수주공 앞 버스정류장 ');

      final report = await notifier.submit();

      expect(report, isNotNull);
      // 전송 시각이 아니라 목격 시각으로 저장된다(설계 결정 5번).
      expect(report!.observedAt, observedAt);
      expect(report.placeName, '만수주공 앞 버스정류장', reason: '앞뒤 공백은 떼고 보낸다');

      final stored = await env.container
          .read(reportRepositoryProvider)
          .fetchReports(_caseId);
      expect(stored.reports.map((r) => r.id), contains(report.id));
    });

    test('장소 이름을 비워두면 보내지 않는다', () async {
      final env = _setUp();
      final notifier = env.container.read(
        reportDraftProvider(_caseId).notifier,
      );

      await notifier.pickPhoto(PhotoSource.camera);
      await notifier.analyze();
      final report = await notifier.submit();

      expect(report!.placeName, isNull);
    });

    test('분석이 만료됐으면 실패 사유가 남는다', () async {
      final env = _setUp();
      final notifier = env.container.read(
        reportDraftProvider(_caseId).notifier,
      );

      await notifier.pickPhoto(PhotoSource.camera);
      await notifier.analyze();

      // 확정은 한 번뿐이다. 두 번째는 만료로 떨어진다.
      await notifier.submit();
      final second = await notifier.submit();

      expect(second, isNull);
      expect(
        env.container.read(reportDraftProvider(_caseId)).submission.hasError,
        isTrue,
      );
    });
  });

  group('자동으로 담긴 정보(F-4.3·F-4.4)', () {
    test('시각을 고치면 고쳤다고 표시한다', () {
      final env = _setUp();
      final notifier = env.container.read(
        reportDraftProvider(_caseId).notifier,
      );

      expect(
        env.container.read(reportDraftProvider(_caseId)).observedAtEdited,
        isFalse,
      );

      notifier.setObservedAt(DateTime(2026, 9, 12, 17, 12));

      final draft = env.container.read(reportDraftProvider(_caseId));
      expect(draft.observedAt, DateTime(2026, 9, 12, 17, 12));
      expect(draft.observedAtEdited, isTrue);
    });
  });
}
