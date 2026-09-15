import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/app.dart';
import 'package:gyeotae/core/map/map_plan.dart';
import 'package:gyeotae/core/media/photo_picker.dart';
import 'package:gyeotae/core/mock/mock_backend.dart';
import 'package:gyeotae/core/router/app_router.dart';
import 'package:gyeotae/core/widgets/resolve_case_dialog.dart';
import 'package:gyeotae/core/widgets/static_kakao_map.dart';
import 'package:gyeotae/features/missing/data/address_lookup.dart';
import 'package:gyeotae/features/missing/data/missing_repository.dart';
import 'package:gyeotae/features/missing/data/mock_missing_repository.dart';
import 'package:gyeotae/features/missing/presentation/case_edit_screen.dart';
import 'package:gyeotae/features/missing/presentation/widgets/detail_guardian_bar.dart';
import 'package:gyeotae/features/missing/presentation/widgets/detail_report_cta.dart';
import 'package:gyeotae/features/missing/presentation/widgets/report_timeline_card.dart';
import 'package:gyeotae/features/notifications/data/notification_repository.dart';
import 'package:gyeotae/features/report/data/mock_report_repository.dart';
import 'package:gyeotae/features/report/data/report_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_address_lookup.dart';
import '../../../support/fake_notification_repository.dart';
import '../../../support/fake_photo_picker.dart';
import '../../../support/onboarding_overrides.dart';

typedef _Env = ({MockBackend backend, FakePhotoPicker picker});

/// 시연용 사건의 상세를 띄운다. [guardian]이면 내가 등록한 사건이다.
Future<_Env> _pumpDetail(WidgetTester tester, {bool guardian = true}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final backend = MockBackend.seeded();
  backend.findCase(MockBackend.demoCaseId)!['is_guardian'] = guardian;
  final picker = FakePhotoPicker();

  final container = ProviderContainer.test(
    overrides: [
      notificationRepositoryProvider.overrideWithValue(
        FakeNotificationRepository(),
      ),
      ...startAfterOnboarding(),
      missingRepositoryProvider.overrideWithValue(
        MockMissingRepository(backend, latency: Duration.zero),
      ),
      reportRepositoryProvider.overrideWithValue(
        MockReportRepository(backend, latency: Duration.zero),
      ),
      photoPickerProvider.overrideWithValue(picker),
      addressLookupProvider.overrideWithValue(FakeAddressLookup('구월동')),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const GyeotaeApp()),
  );
  await tester.pumpAndSettle();

  container
      .read(routerProvider)
      .go(AppRoute.missingDetail(MockBackend.demoCaseId));
  await tester.pumpAndSettle();

  return (backend: backend, picker: picker);
}

/// 스크롤 안의 버튼을 누른다. 딱 보이는 데까지만 굴리면 떠 있는 상단바 밑에
/// 깔려 눌리지 않아서 조금 더 내려 준다.
Future<void> _tapInScroll(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 150));
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Map<String, dynamic> _report(MockBackend backend, String id) =>
    backend.findReport(id)!;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('보호자가 아니면 제보 버튼을, 보호자면 보호자 메뉴를 둔다', (tester) async {
    await _pumpDetail(tester, guardian: false);

    expect(find.byKey(DetailReportCta.buttonKey), findsOneWidget);
    expect(find.byType(DetailGuardianBar), findsNothing);
    // 시민에게는 제보를 숨기거나 확인할 손잡이가 없다.
    expect(find.byKey(ReportTimelineCard.hideButtonKey('r_06')), findsNothing);
  });

  testWidgets('보호자는 제보 버튼 대신 정보 수정·사진 추가·발견 완료를 본다', (tester) async {
    await _pumpDetail(tester);

    // 내 아이 사건에서 "이 아이를 봤어요"는 보호자가 누를 버튼이 아니다.
    expect(find.byKey(DetailReportCta.buttonKey), findsNothing);
    expect(find.byKey(DetailGuardianBar.editKey), findsOneWidget);
    expect(find.byKey(DetailGuardianBar.addPhotosKey), findsOneWidget);
    expect(find.byKey(DetailGuardianBar.resolveKey), findsOneWidget);
  });

  group('제보 관리', () {
    testWidgets('숨기면 경로와 지도에서 빠지고, 다시 보이게 할 수 있다', (tester) async {
      final env = await _pumpDetail(tester);

      await _tapInScroll(
        tester,
        find.byKey(ReportTimelineCard.hideButtonKey('r_06')),
      );

      // 지우지 않는다. 보호자에게는 숨긴 채로 남아 되돌릴 수 있다.
      expect(_report(env.backend, 'r_06')['status'], 'hidden');
      expect(find.text('숨긴 제보'), findsOneWidget);
      final map = tester.widget<StaticKakaoMap>(find.byType(StaticKakaoMap));
      expect(
        map.plan.marks.whereType<ReportMark>().map((mark) => mark.id),
        isNot(contains('r_06')),
      );

      await _tapInScroll(
        tester,
        find.byKey(ReportTimelineCard.hideButtonKey('r_06')),
      );

      expect(_report(env.backend, 'r_06')['status'], 'visible');
      expect(find.text('숨긴 제보'), findsNothing);
    });

    testWidgets('확인함을 누르면 표시되고 다시 누르면 풀린다', (tester) async {
      final env = await _pumpDetail(tester);
      final confirm = find.byKey(ReportTimelineCard.confirmButtonKey('r_06'));

      Finder icon(IconData data) =>
          find.descendant(of: confirm, matching: find.byIcon(data));

      expect(icon(Icons.radio_button_unchecked), findsOneWidget);

      await _tapInScroll(tester, confirm);
      expect(_report(env.backend, 'r_06')['confirmed'], isTrue);
      // 색만으로 알리지 않는다. 체크 표시 모양이 바뀐다.
      expect(icon(Icons.check_circle), findsOneWidget);

      await _tapInScroll(tester, confirm);
      expect(_report(env.backend, 'r_06')['confirmed'], isFalse);
      expect(icon(Icons.radio_button_unchecked), findsOneWidget);
    });
  });

  testWidgets('사진을 더하면 다시 분석한 제보 수를 알려준다', (tester) async {
    final env = await _pumpDetail(tester);
    final before =
        (env.backend.findCase(MockBackend.demoCaseId)!['photos'] as List)
            .length;
    env.picker.galleryPaths = ['/tmp/side.jpg', '/tmp/back.jpg'];

    await tester.tap(find.byKey(DetailGuardianBar.addPhotosKey));
    await tester.pumpAndSettle();

    // 보호자는 카메라가 아니라 앨범에서 고른다. 실종된 사람은 눈앞에 없다.
    expect(env.picker.calls, isEmpty);
    expect(env.picker.manyLimits.single, lessThanOrEqualTo(10 - before));
    expect(
      (env.backend.findCase(MockBackend.demoCaseId)!['photos'] as List).length,
      before + 2,
    );
    expect(find.textContaining('제보 6건을 다시 분석했어요'), findsOneWidget);
  });

  testWidgets('발견 완료는 한 번 묻고 바꾸며, 보호자 메뉴를 거둔다', (tester) async {
    final env = await _pumpDetail(tester);

    await tester.tap(find.byKey(DetailGuardianBar.resolveKey));
    await tester.pumpAndSettle();
    expect(find.byType(ResolveCaseDialog), findsOneWidget);

    await tester.tap(find.byKey(ResolveCaseDialog.confirmKey));
    await tester.pumpAndSettle();

    expect(env.backend.findCase(MockBackend.demoCaseId)!['status'], 'resolved');
    expect(find.byType(DetailGuardianBar), findsNothing);
    expect(find.text('찾는 중'), findsNothing);
  });

  testWidgets('정보 수정에서 인상착의를 고치면 상세에 바로 반영된다', (tester) async {
    final env = await _pumpDetail(tester);

    await tester.tap(find.byKey(DetailGuardianBar.editKey));
    await tester.pumpAndSettle();
    expect(find.byType(CaseEditScreen), findsOneWidget);

    // 긴급도를 조작할 수 있는 칸은 없다고 먼저 알린다.
    expect(find.textContaining('바꿀 수 없어요'), findsOneWidget);

    await tester.enterText(
      find.byKey(CaseEditScreen.descriptionFieldKey),
      '빨간 우비, 노란 장화',
    );
    await tester.tap(find.byKey(CaseEditScreen.saveButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(CaseEditScreen), findsNothing);
    expect(
      env.backend.findCase(MockBackend.demoCaseId)!['description'],
      '빨간 우비, 노란 장화',
    );
    expect(find.textContaining('빨간 우비, 노란 장화'), findsOneWidget);
  });

  testWidgets('인상착의를 비우면 저장하지 않고 칸에 알린다', (tester) async {
    final env = await _pumpDetail(tester);
    final before = env.backend.findCase(MockBackend.demoCaseId)!['description'];

    await tester.tap(find.byKey(DetailGuardianBar.editKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(CaseEditScreen.descriptionFieldKey), ' ');
    await tester.tap(find.byKey(CaseEditScreen.saveButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(CaseEditScreen), findsOneWidget);
    expect(find.text('인상착의를 입력해 주세요'), findsOneWidget);
    expect(
      env.backend.findCase(MockBackend.demoCaseId)!['description'],
      before,
    );
  });
}
