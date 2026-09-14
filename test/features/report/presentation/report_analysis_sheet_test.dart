import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/app.dart';
import 'package:gyeotae/core/location/location_source.dart';
import 'package:gyeotae/core/media/photo_picker.dart';
import 'package:gyeotae/core/mock/mock_backend.dart';
import 'package:gyeotae/core/router/app_router.dart';
import 'package:gyeotae/features/missing/data/missing_repository.dart';
import 'package:gyeotae/features/missing/data/mock_missing_repository.dart';
import 'package:gyeotae/features/notifications/data/notification_repository.dart';
import 'package:gyeotae/features/report/data/mock_report_repository.dart';
import 'package:gyeotae/features/report/data/report_repository.dart';
import 'package:gyeotae/features/report/presentation/report_screen.dart';
import 'package:gyeotae/features/report/presentation/widgets/analysis_progress.dart';
import 'package:gyeotae/features/report/presentation/widgets/report_analysis_sheet.dart';
import 'package:gyeotae/features/report/presentation/widgets/report_analysis_slot.dart';
import 'package:gyeotae/features/report/presentation/widgets/report_photo_field.dart';
import 'package:gyeotae/features/report/presentation/widgets/report_submit_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_notification_repository.dart';
import '../../../support/onboarding_overrides.dart';
import '../../../support/fake_location_source.dart';
import '../../../support/fake_photo_picker.dart';

/// 제보창을 열고 사진까지 올려둔다. 분석 버튼을 누를 수 있는 상태.
///
/// [latency]를 주면 분석이 도는 동안의 화면을 볼 수 있다.
Future<void> _pumpWithPhoto(
  WidgetTester tester, {
  Duration latency = Duration.zero,
  LocationFix? deviceFix = (lat: 37.47, lng: 126.75),
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final backend = MockBackend.seeded();
  final container = ProviderContainer.test(
    overrides: [
      notificationRepositoryProvider.overrideWithValue(
        FakeNotificationRepository(),
      ),
      ...startAfterOnboarding(),
      photoPickerProvider.overrideWithValue(FakePhotoPicker('/tmp/shot.jpg')),
      locationSourceProvider.overrideWithValue(
        FakeLocationSource(known: deviceFix, now: deviceFix),
      ),
      missingRepositoryProvider.overrideWithValue(
        MockMissingRepository(backend, latency: Duration.zero),
      ),
      reportRepositoryProvider.overrideWithValue(
        MockReportRepository(backend, latency: latency),
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const GyeotaeApp()),
  );
  await tester.pumpAndSettle();

  container.read(routerProvider).go(AppRoute.report(MockBackend.demoCaseId));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(ReportPhotoField.cameraKey));
  await tester.pumpAndSettle();
}

/// 제보창에도 같은 문구가 남아 있다. 시트 안만 본다.
Finder _inSheet(Finder matching) {
  return find.descendant(of: find.byType(BottomSheet), matching: matching);
}

Future<void> _tapAnalyze(WidgetTester tester) async {
  await tester.tap(find.byKey(ReportAnalysisSlot.analyzeButtonKey));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('분석 중과 결과의 시트 높이가 같다', (tester) async {
    await _pumpWithPhoto(tester, latency: const Duration(milliseconds: 400));

    await tester.tap(find.byKey(ReportAnalysisSlot.analyzeButtonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final whileLoading = tester.getSize(find.byType(BottomSheet)).height;

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(BottomSheet)).height,
      whileLoading,
      reason: '결과가 왔을 때 시트가 늘어나면 보던 자리가 통째로 움직인다',
    );
  });

  testWidgets('분석 중 화면은 위에서부터 쌓고 남는 자리는 아래에 둔다', (tester) async {
    await _pumpWithPhoto(tester, latency: const Duration(milliseconds: 400));

    await tester.tap(find.byKey(ReportAnalysisSlot.analyzeButtonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final sheet = tester.getRect(find.byType(BottomSheet));
    final steps = tester.getRect(find.byKey(AnalysisProgress.stepsKey));
    final wait = tester.getRect(_inSheet(find.text('잠시만 기다려주세요.')));

    expect(
      steps.top - wait.bottom,
      moreOrLessEquals(24, epsilon: 1),
      reason: '블록 사이는 같은 간격이다',
    );
    expect(
      sheet.bottom - steps.bottom,
      greaterThan(40),
      reason: '남는 높이를 채우려고 내용을 벌리지 않는다',
    );

    // 분석을 끝까지 돌려 타이머를 비운다.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  });

  testWidgets('분석 확인 버튼은 시트 바닥에 붙는다', (tester) async {
    await _pumpWithPhoto(tester);
    await _tapAnalyze(tester);

    final sheet = tester.getRect(find.byType(BottomSheet));
    final button = tester.getRect(find.byKey(analysisConfirmKey));

    expect(
      sheet.bottom - button.bottom,
      moreOrLessEquals(22, epsilon: 1),
      reason: '위 내용이 길든 짧든 누를 자리는 같은 곳에 있어야 한다',
    );
  });

  testWidgets('분석하는 동안 무엇을 하고 있는지 단계로 적는다', (tester) async {
    // 분석은 800ms 걸린다(mock은 latency의 두 배를 쓴다).
    await _pumpWithPhoto(tester, latency: const Duration(milliseconds: 400));

    await tester.tap(find.byKey(ReportAnalysisSlot.analyzeButtonKey));
    await tester.pump();
    // 시트가 올라오는 동안. 분석은 아직 돌고 있다.
    await tester.pump(const Duration(milliseconds: 300));

    // 아직 결과가 아니라 제목을 달지 않는다. 진행 화면이 제 제목을 든다.
    expect(find.text('분석 결과'), findsNothing);
    expect(_inSheet(find.text('AI가 사진을 분석하고 있어요')), findsOneWidget);
    expect(_inSheet(find.text('사진 업로드 중...')), findsOneWidget);
    // 아직 오지 않은 단계는 이름만 적힌다.
    expect(_inSheet(find.text('유사도 계산')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    expect(_inSheet(find.text('사진 업로드 완료')), findsOneWidget);
    expect(_inSheet(find.text('얼굴 특징 분석 중...')), findsOneWidget);

    // 결과가 오면 단계가 남아 있어도 그대로 넘어간다.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(_inSheet(find.byKey(AnalysisProgress.stepsKey)), findsNothing);
    expect(find.text('분석 결과'), findsOneWidget);
    expect(find.byKey(analysisConfirmKey), findsOneWidget);
  });

  testWidgets('유사도와 등급, 대조 사진, 위치·시간이 함께 뜬다', (tester) async {
    await _pumpWithPhoto(tester);
    await _tapAnalyze(tester);

    // 게이지의 큰 숫자와 단위는 따로 그린다(F-4.1.1).
    expect(_inSheet(find.text('63')), findsOneWidget);
    expect(_inSheet(find.text('%')), findsOneWidget);
    expect(_inSheet(find.text('보통 · 확인해볼 만합니다')), findsOneWidget);

    // 숫자만으로는 납득되지 않는다. 두 장을 나란히 둔다(F-4.1.3).
    expect(_inSheet(find.text('등록 사진')), findsOneWidget);
    expect(_inSheet(find.text('내가 찍은 사진')), findsOneWidget);

    // 보내기 전 마지막으로 눈에 걸리는 자리(F-4.1.4).
    expect(_inSheet(find.text('위치')), findsOneWidget);
    expect(_inSheet(find.text('시간')), findsOneWidget);
    expect(_inSheet(find.text('현재 위치')), findsOneWidget);
  });

  testWidgets('확신이 없어도 제보하라고 적는다', (tester) async {
    await _pumpWithPhoto(tester);
    await _tapAnalyze(tester);

    // 이 화면의 목적은 거르기가 아니라 면죄부다(F-4.1.5).
    expect(_inSheet(find.textContaining('확인은 보호자가 합니다')), findsOneWidget);
    expect(_inSheet(find.textContaining('옷을 갈아입었거나')), findsOneWidget);
  });

  testWidgets('분석 확인을 누르면 제보창으로 돌아가고 결과가 남는다', (tester) async {
    await _pumpWithPhoto(tester);
    await _tapAnalyze(tester);

    await tester.tap(find.byKey(analysisConfirmKey));
    await tester.pumpAndSettle();

    expect(find.text('분석 결과'), findsNothing);
    expect(find.byType(ReportScreen), findsOneWidget);
    // 첨부 완료 상태로 남는다(F-4.1.7).
    expect(find.text('63%'), findsOneWidget);
    expect(
      tester
          .widget<ButtonStyleButton>(
            find.byKey(ReportSubmitBar.submitButtonKey),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('얼굴을 못 찾아도 오류가 아니고 제보할 수 있다', (tester) async {
    await _pumpWithPhoto(tester);

    // 두 번째 분석이 얼굴 미검출을 내놓는다(mock 고정 순서).
    await _tapAnalyze(tester);
    await tester.tap(find.byKey(analysisConfirmKey));
    await tester.pumpAndSettle();
    await _tapAnalyze(tester);

    // 0%가 아니라 숫자가 없는 것이다.
    expect(_inSheet(find.text('—')), findsOneWidget);
    expect(_inSheet(find.text('얼굴 미검출 · 위치와 시간은 남습니다')), findsOneWidget);
    expect(_inSheet(find.textContaining('위치와 시간만으로도')), findsOneWidget);

    await tester.tap(find.byKey(analysisConfirmKey));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<ButtonStyleButton>(
            find.byKey(ReportSubmitBar.submitButtonKey),
          )
          .onPressed,
      isNotNull,
      reason: '얼굴 미검출은 에러가 아니다(설계 결정 4번)',
    );
  });
}
