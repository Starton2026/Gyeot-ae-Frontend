import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/app.dart';
import 'package:gyeotae/core/location/location_source.dart';
import 'package:gyeotae/core/media/photo_picker.dart';
import 'package:gyeotae/core/network/dio_provider.dart';
import 'package:gyeotae/core/router/app_router.dart';
import 'package:gyeotae/core/widgets/app_top_bar.dart';
import 'package:gyeotae/core/widgets/guardian_shortcut_banner.dart';
import 'package:gyeotae/core/widgets/map_unavailable_view.dart';
import 'package:gyeotae/core/widgets/mascot.dart';
import 'package:gyeotae/features/auth/data/auth_repository.dart';
import 'package:gyeotae/features/auth/data/auth_session.dart';
import 'package:gyeotae/features/auth/data/kakao_auth_source.dart';
import 'package:gyeotae/features/auth/presentation/widgets/login_sheet.dart';
import 'package:gyeotae/features/home/presentation/home_screen.dart';
import 'package:gyeotae/features/home/presentation/widgets/guardian_register_block.dart';
import 'package:gyeotae/features/missing/data/address_lookup.dart';
import 'package:gyeotae/features/missing/data/missing_case.dart';
import 'package:gyeotae/features/missing/data/register_draft_storage.dart';
import 'package:gyeotae/features/missing/data/register_form.dart';
import 'package:gyeotae/features/missing/presentation/missing_detail_screen.dart';
import 'package:gyeotae/features/missing/presentation/missing_list_screen.dart';
import 'package:gyeotae/features/missing/presentation/missing_register_screen.dart';
import 'package:gyeotae/features/missing/presentation/register_location_screen.dart';
import 'package:gyeotae/features/missing/presentation/widgets/register_exit_dialog.dart';
import 'package:gyeotae/features/missing/presentation/widgets/register_form_view.dart';
import 'package:gyeotae/features/missing/presentation/widgets/register_location_card.dart';
import 'package:gyeotae/features/missing/presentation/widgets/register_photo_field.dart';
import 'package:gyeotae/features/missing/presentation/widgets/register_submit_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_address_lookup.dart';
import '../../../support/fake_auth.dart';
import '../../../support/fake_location_source.dart';
import '../../../support/fake_photo_picker.dart';
import '../../../support/in_memory_register_draft_storage.dart';
import '../../../support/in_memory_token_storage.dart';
import '../../../support/offline_repositories.dart';
import '../../../support/onboarding_overrides.dart';

typedef _Env = ({
  ProviderContainer container,
  InMemoryRegisterDraftStorage storage,
  InMemoryTokenStorage tokens,
});

/// 앱을 통째로 띄워 홈에서 시작한다.
Future<_Env> _launch(
  WidgetTester tester, {
  bool signedIn = true,
  FakeKakaoAuthSource? kakao,
  RegisterForm? saved,
  Size screen = const Size(400, 1000),
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  tester.view.physicalSize = screen * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final storage = InMemoryRegisterDraftStorage(saved);
  final tokens = InMemoryTokenStorage(signedIn ? 'token' : null);

  final container = ProviderContainer.test(
    overrides: [
      ...startAfterOnboarding(),
      ...offlineRepositories(),
      tokenStorageProvider.overrideWithValue(tokens),
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(
          user: signedIn
              ? const AuthProfile(
                  user: AuthUser(id: 'u_1', name: '김보호'),
                )
              : null,
        ),
      ),
      kakaoAuthSourceProvider.overrideWithValue(kakao ?? FakeKakaoAuthSource()),
      photoPickerProvider.overrideWithValue(
        FakePhotoPicker()..galleryPaths = ['/tmp/front.jpg', '/tmp/side.jpg'],
      ),
      locationSourceProvider.overrideWithValue(
        FakeLocationSource(
          known: (lat: 37.47, lng: 126.75),
          now: (lat: 37.47, lng: 126.75),
        ),
      ),
      addressLookupProvider.overrideWithValue(FakeAddressLookup()),
      registerDraftStorageProvider.overrideWithValue(storage),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const GyeotaeApp()),
  );
  await tester.pumpAndSettle();

  return (container: container, storage: storage, tokens: tokens);
}

Future<void> _openFromHomeBanner(WidgetTester tester) async {
  await tester.tap(find.byKey(GuardianShortcutBanner.registerShortcutKey));
  await tester.pumpAndSettle();
}

/// 화면 밖 칸은 누를 수 없다. 보일 때까지 굴린다.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find
        .descendant(
          of: find.byType(RegisterFormView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, Key key, String text) async {
  await _scrollTo(tester, find.byKey(key));
  await tester.enterText(find.byKey(key), text);
  await tester.pump();
}

/// 필수 칸을 화면에서 전부 채운다. 위치는 기기 위치가 저절로 들어간다.
Future<void> _fillRequired(WidgetTester tester) async {
  await tester.tap(find.byKey(RegisterPhotoField.addKey));
  await tester.pumpAndSettle();

  await _enter(tester, RegisterFormView.nameFieldKey, '김하준');
  await _enter(tester, RegisterFormView.ageFieldKey, '7');

  await _scrollTo(tester, find.byKey(RegisterFormView.genderFieldKey));
  await tester.tap(find.byKey(RegisterFormView.genderFieldKey));
  await tester.pumpAndSettle();
  await tester.tap(find.text('남').last);
  await tester.pumpAndSettle();

  await _scrollTo(tester, find.text('아동'));
  await tester.tap(find.text('아동'));
  await tester.pump();

  await _enter(tester, RegisterFormView.descriptionFieldKey, '노란 후드티');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('들어오는 길', () {
    testWidgets('로그인했으면 홈 바로가기가 시트 없이 폼을 연다', (tester) async {
      await _launch(tester);

      await _openFromHomeBanner(tester);

      expect(find.byType(MissingRegisterScreen), findsOneWidget);
      // 이미 로그인한 사람에게 로그인 시트를 또 띄우던 버그.
      expect(find.byType(LoginSheet), findsNothing);
    });

    testWidgets('홈 아래 등록 소개 블록에서도 연다', (tester) async {
      await _launch(tester);

      await tester.scrollUntilVisible(
        find.byKey(GuardianRegisterBlock.registerButtonKey),
        300,
        scrollable: find
            .descendant(
              of: find.byType(HomeScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.byKey(GuardianRegisterBlock.registerButtonKey));
      await tester.pumpAndSettle();

      expect(find.byType(MissingRegisterScreen), findsOneWidget);
    });

    testWidgets('실종자 목록 바로가기에서도 연다', (tester) async {
      final env = await _launch(tester);
      env.container.read(routerProvider).go(AppRoute.missingList);
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(MissingListScreen),
          matching: find.byKey(GuardianShortcutBanner.registerShortcutKey),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MissingRegisterScreen), findsOneWidget);
      expect(find.byType(LoginSheet), findsNothing);
    });

    testWidgets('로그인 전이면 폼 위에 시트를 덮고, 로그인하면 시트만 걷힌다', (tester) async {
      await _launch(tester, signedIn: false);

      await _openFromHomeBanner(tester);

      // 무엇을 요구하는지 뒤에 보이는 채로 로그인한다(시안 S6).
      expect(find.byType(MissingRegisterScreen), findsOneWidget);
      expect(find.byType(LoginSheet), findsOneWidget);

      await tester.tap(find.byKey(LoginSheet.kakaoButtonKey));
      await tester.pumpAndSettle();

      expect(find.byType(LoginSheet), findsNothing);
      expect(find.byType(MissingRegisterScreen), findsOneWidget);
    });

    testWidgets('로그인하지 않고 시트를 닫으면 폼도 닫힌다', (tester) async {
      await _launch(tester, signedIn: false);
      await _openFromHomeBanner(tester);

      // 시트 바깥을 눌러 닫는다.
      await tester.tapAt(const Offset(200, 40));
      await tester.pumpAndSettle();

      expect(find.byType(LoginSheet), findsNothing);
      expect(find.byType(MissingRegisterScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('폼', () {
    testWidgets('112 안내가 맨 위에 있고 이음이는 나오지 않는다', (tester) async {
      await _launch(tester);
      await _openFromHomeBanner(tester);

      expect(find.textContaining('112 신고를 먼저 해주세요'), findsOneWidget);
      // 등록 폼은 긴급 화면이다(설계 결정 8번).
      expect(find.byType(Mascot), findsNothing);
    });

    testWidgets('사진 추가를 누르면 고를 것 없이 앨범에서 여러 장을 담는다', (tester) async {
      await _launch(tester);
      await _openFromHomeBanner(tester);

      await tester.tap(find.byKey(RegisterPhotoField.addKey));
      await tester.pumpAndSettle();

      // 실종된 사람을 카메라로 찍을 수는 없다. 카메라/앨범을 묻지 않는다.
      expect(find.text('카메라로 찍기'), findsNothing);
      expect(find.byKey(RegisterPhotoField.removeKey(0)), findsOneWidget);
      expect(find.byKey(RegisterPhotoField.removeKey(1)), findsOneWidget);
      expect(find.text('대표'), findsOneWidget);
    });

    testWidgets('기기 위치와 그 주소가 목격 위치에 들어가 있다', (tester) async {
      await _launch(tester);
      await _openFromHomeBanner(tester);
      await _scrollTo(tester, find.byType(RegisterLocationCard));

      expect(
        find.descendant(
          of: find.byType(RegisterLocationCard),
          matching: find.text('인천 남동구 인하로 501'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('빈 칸이 있으면 보내지 않고 칸 아래에 알린다', (tester) async {
      await _launch(tester);
      await _openFromHomeBanner(tester);

      await tester.tap(find.byKey(RegisterSubmitBar.submitButtonKey));
      await tester.pumpAndSettle();

      expect(find.byType(MissingRegisterScreen), findsOneWidget);
      expect(find.text(RegisterField.photos.message), findsOneWidget);
      expect(find.text(RegisterField.name.message), findsOneWidget);
    });

    testWidgets('화면 밖의 칸이 빠졌으면 그 칸까지 데려간다', (tester) async {
      // 실제 폰 크기. 인상착의 칸 아래가 첫 화면에 들어오지 않는다.
      await _launch(tester, screen: const Size(360, 740));
      await _openFromHomeBanner(tester);
      await _fillRequired(tester);
      await _enter(tester, RegisterFormView.descriptionFieldKey, '');
      // 키보드를 내린다. 포커스가 남은 입력칸은 화면 밖에서도 살아 있어 찾기 쉽다.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      // 맨 위로 올려 둔 채 누른다. 인상착의 안내는 화면 아래에 있다.
      await tester.drag(
        find
            .descendant(
              of: find.byType(RegisterFormView),
              matching: find.byType(Scrollable),
            )
            .first,
        const Offset(0, 3000),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(RegisterSubmitBar.submitButtonKey));
      await tester.pumpAndSettle();

      expect(
        find.text(RegisterField.description.message).hitTestable(),
        findsOneWidget,
      );
    });

    testWidgets('다 채우고 등록하면 새 사건 상세로 간다', (tester) async {
      final env = await _launch(tester);
      await _openFromHomeBanner(tester);
      await tester.tap(find.byKey(MissingRegisterScreen.saveDraftKey));
      await tester.pumpAndSettle();

      await _fillRequired(tester);
      await tester.tap(find.byKey(RegisterSubmitBar.submitButtonKey));
      await tester.pumpAndSettle();

      expect(find.byType(MissingRegisterScreen), findsNothing);
      expect(find.byType(MissingDetailScreen), findsOneWidget);
      expect(find.text('김하준'), findsWidgets);
      expect(find.textContaining('등록했어요'), findsOneWidget);
      // 등록이 끝났으니 이어 쓸 것이 없다.
      expect(env.storage.saved, isNull);
    });

    testWidgets('지도에서 조정을 누르면 위치 고르기 화면이 열린다', (tester) async {
      await _launch(tester);
      await _openFromHomeBanner(tester);

      await _scrollTo(tester, find.byKey(RegisterLocationCard.adjustKey));
      await tester.tap(find.byKey(RegisterLocationCard.adjustKey));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterLocationScreen), findsOneWidget);
      // 테스트에는 지도 키가 없다. 흰 판 대신 이유를 적는다.
      expect(find.byType(MapUnavailableView), findsOneWidget);
    });

    testWidgets('위치 고르기 화면은 키보드가 올라와도 줄어들지 않는다', (tester) async {
      await _launch(tester);
      await _openFromHomeBanner(tester);
      await _scrollTo(tester, find.byKey(RegisterLocationCard.adjustKey));
      await tester.tap(find.byKey(RegisterLocationCard.adjustKey));
      await tester.pumpAndSettle();

      // 지도(플랫폼 뷰)가 키보드 때문에 크기를 바꾸다 정리되는 순간과 겹치면
      // 엔진이 죽는다(실기기 2026-09-14, SurfaceProducer NPE). 지도 탭과 같다.
      final scaffold = tester.widget<Scaffold>(
        find.descendant(
          of: find.byType(RegisterLocationScreen),
          matching: find.byType(Scaffold),
        ),
      );
      expect(scaffold.resizeToAvoidBottomInset, isFalse);
    });

    testWidgets('입력하다 위치를 고르고 돌아와도 키보드가 저절로 올라오지 않는다', (tester) async {
      await _launch(tester);
      await _openFromHomeBanner(tester);
      await _enter(tester, RegisterFormView.nameFieldKey, '김하준');
      expect(tester.testTextInput.isVisible, isTrue);

      await _scrollTo(tester, find.byKey(RegisterLocationCard.adjustKey));
      await tester.tap(find.byKey(RegisterLocationCard.adjustKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(RegisterLocationScreen.confirmKey));
      await tester.pumpAndSettle();

      // 돌아오는 순간 키보드가 올라오면, 닫히는 지도 화면이 그 사이에 흔들린다.
      expect(find.byType(RegisterLocationScreen), findsNothing);
      expect(tester.testTextInput.isVisible, isFalse);
    });
  });

  group('임시저장·나가기', () {
    testWidgets('임시저장을 누르면 이 기기에 남는다', (tester) async {
      final env = await _launch(tester);
      await _openFromHomeBanner(tester);
      await _enter(tester, RegisterFormView.nameFieldKey, '김하준');

      await tester.tap(find.byKey(MissingRegisterScreen.saveDraftKey));
      await tester.pumpAndSettle();

      expect(env.storage.saved?.name, '김하준');
      expect(find.textContaining('임시저장했어요'), findsOneWidget);
    });

    testWidgets('다시 열면 임시저장한 내용으로 이어 쓴다', (tester) async {
      await _launch(
        tester,
        saved: RegisterForm(
          missingAt: DateTime(2026, 9, 14, 14, 40),
          name: '이순자',
        ),
      );

      await _openFromHomeBanner(tester);

      expect(
        find.descendant(
          of: find.byKey(RegisterFormView.nameFieldKey),
          matching: find.text('이순자'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('임시저장한 내용을 불러왔어요'), findsOneWidget);
    });

    testWidgets('아무것도 안 썼으면 묻지 않고 닫힌다', (tester) async {
      await _launch(tester);
      await _openFromHomeBanner(tester);

      await tester.tap(find.byKey(AppTopBar.closeButtonKey));
      await tester.pumpAndSettle();

      expect(find.byType(MissingRegisterScreen), findsNothing);
    });

    testWidgets('쓰던 내용이 있으면 닫기 전에 묻는다', (tester) async {
      await _launch(tester);
      await _openFromHomeBanner(tester);
      await _enter(tester, RegisterFormView.nameFieldKey, '김하준');

      await tester.tap(find.byKey(AppTopBar.closeButtonKey));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(registerExitKeepKey));
      await tester.pumpAndSettle();
      expect(find.byType(MissingRegisterScreen), findsOneWidget);

      await tester.tap(find.byKey(AppTopBar.closeButtonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(registerExitLeaveKey));
      await tester.pumpAndSettle();
      expect(find.byType(MissingRegisterScreen), findsNothing);
    });

    testWidgets('임시저장하고 나가면 저장한 뒤 닫힌다', (tester) async {
      final env = await _launch(tester);
      await _openFromHomeBanner(tester);
      await _enter(tester, RegisterFormView.nameFieldKey, '김하준');

      await tester.tap(find.byKey(AppTopBar.closeButtonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(registerExitSaveKey));
      await tester.pumpAndSettle();

      expect(find.byType(MissingRegisterScreen), findsNothing);
      expect(env.storage.saved?.name, '김하준');
    });
  });

  testWidgets('키·몸무게는 누르지 않아도 처음부터 보인다', (tester) async {
    await _launch(tester);
    await _openFromHomeBanner(tester);

    // 옆에 "선택"이 적혀 있어 접어 둘 이유가 없다. 접으면 있는 줄도 모른다.
    await _scrollTo(tester, find.byKey(RegisterFormView.heightFieldKey));
    expect(find.byKey(RegisterFormView.heightFieldKey), findsOneWidget);
    expect(find.byKey(RegisterFormView.weightFieldKey), findsOneWidget);
  });

  testWidgets('보호자 연락처는 묻지 않는다', (tester) async {
    await _launch(tester);
    await _openFromHomeBanner(tester);

    // 제보자에게 공개하지 않고 운영팀이 확인할 수도 없어, 쓰는 곳 없이 모으기만
    // 하는 개인정보였다. 보호자는 로그인한 계정으로 제보 소식을 받는다.
    expect(find.text('보호자 연락처'), findsNothing);
  });

  test('성별은 남·여 두 가지만 고른다', () {
    // API에는 other가 있지만 실종자 등록에서 고를 일은 없다고 봤다.
    expect(RegisterFormView.genderChoices, [Gender.male, Gender.female]);
  });
}
