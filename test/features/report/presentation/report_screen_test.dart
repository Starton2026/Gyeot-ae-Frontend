import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/app.dart';
import 'package:gyeotae/core/location/location_source.dart';
import 'package:gyeotae/core/media/photo_picker.dart';
import 'package:gyeotae/core/mock/mock_backend.dart';
import 'package:gyeotae/core/router/app_router.dart';
import 'package:gyeotae/core/widgets/app_top_bar.dart';
import 'package:gyeotae/features/missing/data/missing_repository.dart';
import 'package:gyeotae/features/missing/data/mock_missing_repository.dart';
import 'package:gyeotae/features/missing/presentation/missing_detail_screen.dart';
import 'package:gyeotae/features/missing/presentation/widgets/detail_report_cta.dart';
import 'package:gyeotae/features/report/data/mock_report_repository.dart';
import 'package:gyeotae/features/report/data/report_repository.dart';
import 'package:gyeotae/features/report/presentation/report_done_screen.dart';
import 'package:gyeotae/features/report/presentation/report_screen.dart';
import 'package:gyeotae/features/report/presentation/widgets/report_analysis_sheet.dart';
import 'package:gyeotae/features/report/presentation/widgets/report_analysis_slot.dart';
import 'package:gyeotae/features/report/presentation/widgets/report_exit_dialog.dart';
import 'package:gyeotae/features/report/presentation/widgets/report_photo_field.dart';
import 'package:gyeotae/features/report/presentation/widgets/report_submit_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/onboarding_overrides.dart';
import '../../../support/fake_location_source.dart';
import '../../../support/fake_photo_picker.dart';

/// 상세(S3)를 거쳐 제보창을 연다. 실제 사용자가 들어오는 길과 같게 두면
/// 닫았을 때 돌아갈 곳이 있는지도 함께 확인된다.
Future<FakePhotoPicker> _pumpReport(
  WidgetTester tester, {
  LocationFix? deviceFix = (lat: 37.47, lng: 126.75),
}) async {
  // 깜빡이는 '찾는 중' 점이 멈춰야 pumpAndSettle이 끝난다.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  // 제보창은 한 화면에 다 들어가야 하는 폼이다. 기본 800 높이로 두면 분석
  // 칸이 ListView 밖에 남아 아예 만들어지지 않는다.
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final backend = MockBackend.seeded();
  final picker = FakePhotoPicker('/tmp/shot.jpg');
  final container = ProviderContainer.test(
    overrides: [
      ...startAfterOnboarding(),
      photoPickerProvider.overrideWithValue(picker),
      locationSourceProvider.overrideWithValue(
        FakeLocationSource(known: deviceFix, now: deviceFix),
      ),
      missingRepositoryProvider.overrideWithValue(
        MockMissingRepository(backend, latency: Duration.zero),
      ),
      reportRepositoryProvider.overrideWithValue(
        MockReportRepository(backend, latency: Duration.zero),
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const GyeotaeApp()),
  );
  await tester.pumpAndSettle();

  container.read(routerProvider).go(AppRoute.missingDetail(MockBackend.demoCaseId));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(DetailReportCta.buttonKey));
  await tester.pumpAndSettle();

  return picker;
}

Future<void> _attachPhoto(WidgetTester tester) async {
  await tester.tap(find.byKey(ReportPhotoField.cameraKey));
  await tester.pumpAndSettle();
}

/// 분석하고 결과 시트를 닫는다. 시트 안은 S4-1 테스트가 따로 본다.
Future<void> _analyze(WidgetTester tester) async {
  await tester.tap(find.byKey(ReportAnalysisSlot.analyzeButtonKey));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(analysisConfirmKey));
  await tester.pumpAndSettle();
}

bool _enabled(WidgetTester tester, Key key) {
  return tester.widget<ButtonStyleButton>(find.byKey(key)).onPressed != null;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('상세에서 제보 버튼을 누르면 제보창이 열린다', (tester) async {
    await _pumpReport(tester);

    expect(find.byType(ReportScreen), findsOneWidget);
    expect(find.text('제보하기'), findsOneWidget);
    // 누구를 제보하는지 화면 맨 위에 못 박는다(F-4.1).
    expect(find.text('김하준 · 7세 남아'), findsOneWidget);
    expect(find.textContaining('노란 후드티'), findsOneWidget);
  });

  testWidgets('시민이 채우는 칸은 사진 하나뿐이다', (tester) async {
    await _pumpReport(tester);

    expect(find.byType(TextField), findsNothing);
    expect(find.text('목격한 사진 *'), findsOneWidget);
    // 위치와 시간은 묻지 않고 담아둔다(F-4.3·F-4.4).
    expect(find.text('자동으로 담긴 정보'), findsOneWidget);
    expect(find.text('현재 위치'), findsOneWidget);
  });

  testWidgets('위치를 못 받으면 지어내지 않고 비워둔다', (tester) async {
    await _pumpReport(tester, deviceFix: null);

    // 시연용 좌표를 붙여 보내면 아무도 보지 않은 자리에 점이 찍힌다.
    expect(find.text('위치를 못 받았어요'), findsOneWidget);
    expect(find.text('위치 없이도 제보할 수 있어요'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets('분석 전에는 제보 버튼이 회색으로 남는다', (tester) async {
    await _pumpReport(tester);

    expect(_enabled(tester, ReportAnalysisSlot.analyzeButtonKey), isFalse);
    expect(_enabled(tester, ReportSubmitBar.submitButtonKey), isFalse);
    // 숨기지 않고 남겨둬야 무엇이 남았는지 읽힌다(F-4.6).
    expect(find.byKey(ReportSubmitBar.submitButtonKey), findsOneWidget);
    expect(find.text('분석을 마치면 제보할 수 있습니다'), findsOneWidget);
  });

  testWidgets('사진을 올리면 분석할 수 있고, 분석하면 결과가 남는다', (tester) async {
    final picker = await _pumpReport(tester);

    await _attachPhoto(tester);
    expect(picker.calls, [PhotoSource.camera]);
    expect(_enabled(tester, ReportAnalysisSlot.analyzeButtonKey), isTrue);
    expect(_enabled(tester, ReportSubmitBar.submitButtonKey), isFalse);

    await _analyze(tester);

    // 시트를 닫아도 제보창에 결과가 남아 있어야 한다(F-4.1.7).
    expect(find.text('63%'), findsOneWidget);
    expect(find.text('보통 · 확인해볼 만합니다'), findsOneWidget);
    expect(_enabled(tester, ReportSubmitBar.submitButtonKey), isTrue);
    expect(find.textContaining('로그인 없이 제보'), findsOneWidget);
  });

  testWidgets('제보하면 완료 화면으로 넘어간다', (tester) async {
    await _pumpReport(tester);

    await _attachPhoto(tester);
    await _analyze(tester);
    await tester.tap(find.byKey(ReportSubmitBar.submitButtonKey));
    await tester.pumpAndSettle();

    // 완료 화면 안쪽은 S4-2 테스트가 본다.
    expect(find.byType(ReportDoneScreen), findsOneWidget);
    expect(find.byType(ReportScreen), findsNothing);
  });

  group('이탈 방지(F-4.7)', () {
    testWidgets('빈 화면은 그냥 닫힌다', (tester) async {
      await _pumpReport(tester);

      await tester.tap(find.byKey(AppTopBar.closeButtonKey));
      await tester.pumpAndSettle();

      expect(find.byType(MissingDetailScreen), findsOneWidget);
    });

    testWidgets('사진이 있으면 되묻고, 계속 쓰기를 누르면 남는다', (tester) async {
      await _pumpReport(tester);
      await _attachPhoto(tester);

      await tester.tap(find.byKey(AppTopBar.closeButtonKey));
      await tester.pumpAndSettle();
      expect(find.text('작성을 취소할까요?'), findsOneWidget);

      await tester.tap(find.byKey(reportExitKeepKey));
      await tester.pumpAndSettle();
      expect(find.byType(ReportScreen), findsOneWidget);

      await tester.tap(find.byKey(ReportSubmitBar.cancelButtonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(reportExitLeaveKey));
      await tester.pumpAndSettle();
      expect(find.byType(MissingDetailScreen), findsOneWidget);
    });
  });
}
