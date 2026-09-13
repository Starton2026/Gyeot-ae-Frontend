import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/app.dart';
import 'package:gyeotae/core/location/location_source.dart';
import 'package:gyeotae/core/media/photo_picker.dart';
import 'package:gyeotae/core/mock/mock_backend.dart';
import 'package:gyeotae/core/network/dio_provider.dart';
import 'package:gyeotae/core/router/app_router.dart';
import 'package:gyeotae/core/widgets/mascot.dart';
import 'package:gyeotae/features/auth/data/auth_repository.dart';
import 'package:gyeotae/features/auth/data/auth_session.dart';
import 'package:gyeotae/features/map/presentation/map_screen.dart';
import 'package:gyeotae/features/missing/data/missing_repository.dart';
import 'package:gyeotae/features/missing/data/mock_missing_repository.dart';
import 'package:gyeotae/features/missing/presentation/missing_detail_screen.dart';
import 'package:gyeotae/features/report/data/mock_report_repository.dart';
import 'package:gyeotae/features/report/data/report_repository.dart';
import 'package:gyeotae/features/report/presentation/report_done_screen.dart';
import 'package:gyeotae/features/report/presentation/report_screen.dart';
import 'package:gyeotae/features/report/presentation/widgets/report_analysis_sheet.dart';
import 'package:gyeotae/features/report/presentation/widgets/report_analysis_slot.dart';
import 'package:gyeotae/features/report/presentation/widgets/report_done_notify.dart';
import 'package:gyeotae/features/report/presentation/widgets/report_photo_field.dart';
import 'package:gyeotae/features/report/presentation/widgets/report_submit_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_auth.dart';
import '../../../support/in_memory_token_storage.dart';
import '../../../support/onboarding_overrides.dart';
import '../../../support/fake_location_source.dart';
import '../../../support/fake_photo_picker.dart';

const _caseId = MockBackend.demoCaseId;

/// 상세 → 제보창 → 사진 → 분석 → 제보. 실제 사용자가 오는 길 그대로 태운다.
///
/// 완료 화면은 방금 확정된 제보를 넘겨받아야 뜨는 화면이라, 중간을 건너뛰고
/// 띄우면 정작 확인해야 할 것을 못 본다.
Future<ProviderContainer> _submitReport(
  WidgetTester tester, {
  LocationFix? deviceFix = (lat: 37.47, lng: 126.75),
  bool signedIn = false,
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
      ...startAfterOnboarding(),
      photoPickerProvider.overrideWithValue(FakePhotoPicker('/tmp/shot.jpg')),
      locationSourceProvider.overrideWithValue(
        FakeLocationSource(known: deviceFix, now: deviceFix),
      ),
      missingRepositoryProvider.overrideWithValue(
        MockMissingRepository(backend, latency: Duration.zero),
      ),
      reportRepositoryProvider.overrideWithValue(
        MockReportRepository(backend, latency: Duration.zero),
      ),
      tokenStorageProvider.overrideWithValue(
        InMemoryTokenStorage(signedIn ? 'token' : null),
      ),
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(
          user: signedIn
              ? const AuthProfile(user: AuthUser(id: 'u_1', name: '김보호'))
              : null,
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const GyeotaeApp()),
  );
  await tester.pumpAndSettle();

  container.read(routerProvider).go(AppRoute.missingDetail(_caseId));
  await tester.pumpAndSettle();
  unawaited(container.read(routerProvider).push(AppRoute.report(_caseId)));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(ReportPhotoField.cameraKey));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ReportAnalysisSlot.analyzeButtonKey));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(analysisConfirmKey));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ReportSubmitBar.submitButtonKey));
  await tester.pumpAndSettle();

  return container;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('제보를 보내면 완료 화면으로 갈아탄다', (tester) async {
    await _submitReport(tester);

    expect(find.byType(ReportDoneScreen), findsOneWidget);
    // 뒤로 눌러 쓰다 만 제보창으로 돌아가면 이미 보낸 것을 또 보낸다.
    expect(find.byType(ReportScreen), findsNothing);

    // 긴급 화면에서 물러나 있던 이음이가 안도의 순간에 나온다(설계 결정 8번).
    expect(find.byType(Mascot), findsOneWidget);
    expect(find.text('제보가 전달되었습니다'), findsOneWidget);
    expect(find.textContaining('경로의 한 점이 됩니다'), findsOneWidget);
  });

  testWidgets('무엇을 보냈는지 요약이 남는다', (tester) async {
    await _submitReport(tester);

    // 유사도·위치·시간 세 줄(F-4.2.2).
    expect(find.text('63% · 보통'), findsOneWidget);
    expect(find.text('유사도'), findsOneWidget);
    expect(find.text('현재 위치'), findsOneWidget);
    expect(find.textContaining('당신의 작은 관심'), findsOneWidget);
  });

  testWidgets('위치 없이 보낸 제보는 그렇게 적는다', (tester) async {
    await _submitReport(tester, deviceFix: null);

    expect(find.text('위치 없이 보냄'), findsOneWidget);
  });

  testWidgets('이름에 맞는 조사를 붙여 묻는다', (tester) async {
    await _submitReport(tester);

    // "김하준이" — 받침이 있으면 이, 없으면 가(F-4.2.5).
    expect(find.text('김하준이 발견되면 알려드릴까요?'), findsOneWidget);
    expect(find.byKey(ReportDoneNotify.loginButtonKey), findsOneWidget);
  });

  testWidgets('이미 로그인했으면 알림 받기를 묻지 않는다', (tester) async {
    await _submitReport(tester, signedIn: true);

    // 로그인한 사람의 제보는 이미 계정에 붙는다. 로그인하라고 또 물으면
    // 버튼을 눌러도 같은 시트만 다시 뜬다.
    expect(find.byType(ReportDoneNotify), findsNothing);
    expect(find.text('제보가 전달되었습니다'), findsOneWidget);
  });

  testWidgets('괜찮습니다를 눌러도 제보는 남는다', (tester) async {
    final container = await _submitReport(tester);
    final count = (await container
            .read(reportRepositoryProvider)
            .fetchReports(_caseId))
        .count;

    await tester.tap(find.byKey(ReportDoneNotify.skipButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(MissingDetailScreen), findsOneWidget);
    // 로그인을 건너뛰어도 방금 보낸 제보가 타임라인에 들어 있다(F-4.2.6).
    // 미니 지도 설명과 타임라인 머리글 두 군데에 같은 건수가 적힌다.
    expect(find.textContaining('제보 $count건'), findsWidgets);
  });

  testWidgets('닫기를 눌러도 사건으로 돌아간다', (tester) async {
    await _submitReport(tester);

    await tester.tap(find.byKey(ReportDoneScreen.closeButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(MissingDetailScreen), findsOneWidget);
  });

  testWidgets('지도에서 경로 보기를 누르면 지도로 간다', (tester) async {
    await _submitReport(tester);

    await tester.tap(find.byKey(ReportDoneScreen.mapLinkKey));
    await tester.pumpAndSettle();

    expect(find.byType(MapScreen), findsOneWidget);
  });
}
