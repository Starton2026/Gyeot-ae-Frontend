import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/network/api_exception.dart';
import 'package:gyeotae/core/network/dio_provider.dart';
import 'package:gyeotae/core/theme/app_theme.dart';
import 'package:gyeotae/core/widgets/loading_view.dart';
import 'package:gyeotae/features/auth/data/auth_repository.dart';
import 'package:gyeotae/features/auth/data/auth_session.dart';
import 'package:gyeotae/features/auth/data/kakao_auth_source.dart';
import 'package:gyeotae/features/auth/presentation/widgets/login_sheet.dart';
import 'package:gyeotae/features/home/presentation/home_providers.dart';
import 'package:gyeotae/features/missing/data/missing_case.dart';
import 'package:gyeotae/features/my/data/my_report.dart';
import 'package:gyeotae/features/my/data/my_repository.dart';
import 'package:gyeotae/features/my/presentation/my_screen.dart';
import 'package:gyeotae/features/my/presentation/widgets/my_case_card.dart';
import 'package:gyeotae/features/my/presentation/widgets/my_folded_list.dart';
import 'package:gyeotae/features/my/presentation/widgets/my_login_card.dart';
import 'package:gyeotae/features/my/presentation/widgets/my_menu.dart';
import 'package:gyeotae/features/my/presentation/widgets/my_report_tile.dart';
import 'package:gyeotae/features/my/presentation/widgets/my_sign_out_dialog.dart';
import 'package:gyeotae/features/report/data/report.dart';

import '../../../support/fake_auth.dart';
import '../../../support/fake_my_repository.dart';
import '../../../support/in_memory_token_storage.dart';

/// 카카오 로그인 창이 아직 안 닫힌 상태. [complete]를 불러야 끝난다.
class _PendingKakaoAuthSource implements KakaoAuthSource {
  final _completer = Completer<String?>();

  int calls = 0;

  void complete(String? token) => _completer.complete(token);

  @override
  Future<void> signOut() async {}

  @override
  Future<String?> requestAccessToken() {
    calls += 1;

    return _completer.future;
  }
}

/// `GET /auth/me`가 아직 안 돌아온 상태. [complete]를 불러야 끝난다.
class _PendingAuthRepository extends FakeAuthRepository {
  final _me = Completer<AuthProfile?>();

  void complete(AuthProfile? profile) => _me.complete(profile);

  @override
  Future<AuthProfile?> me() => _me.future;
}

/// `GET /auth/me`가 실패한다. 서버가 죽었거나 네트워크가 끊겼다.
class _FailingAuthRepository extends FakeAuthRepository {
  @override
  Future<AuthProfile?> me() async =>
      throw const ApiException('서버 오류', statusCode: 500);
}

const _signedInProfile = AuthProfile(
  user: AuthUser(id: 'u_1', name: '김보호'),
  caseCount: 1,
  reportCount: 6,
);

late FakeMyRepository lastRepository;
late InMemoryTokenStorage lastTokens;

/// 홈 피드를 몇 번 받아왔는지. 발견 완료 뒤 홈이 옛 목록을 들고 있지 않은지 본다.
int homeFeedFetches = 0;
late KakaoAuthSource lastKakao;

Future<void> _pumpMy(
  WidgetTester tester, {
  bool signedIn = false,
  MyReportList? reports,
  MissingCaseList? cases,
  KakaoAuthSource? kakao,
  FakeAuthRepository? authRepository,
  // 로딩 표시가 도는 동안에는 pumpAndSettle이 끝나지 않는다.
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // 로그인 상태는 저장된 토큰으로 갈린다.
        tokenStorageProvider.overrideWithValue(
          lastTokens = InMemoryTokenStorage(signedIn ? 'token' : null),
        ),
        authRepositoryProvider.overrideWithValue(
          authRepository ??
              FakeAuthRepository(user: signedIn ? _signedInProfile : null),
        ),
        kakaoAuthSourceProvider.overrideWithValue(
          lastKakao = kakao ?? FakeKakaoAuthSource(),
        ),
        myRepositoryProvider.overrideWithValue(
          lastRepository = FakeMyRepository(reports: reports, cases: cases),
        ),
        homeFeedProvider.overrideWith((ref) async {
          homeFeedFetches += 1;
          return const HomeFeed(
            urgentCase: null,
            nearbyCases: [],
            nearbyCount: 0,
          );
        }),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const MyScreen()),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// 접힌 목록을 펼친다. [WidgetTester.ensureVisible]만으로는 스크롤이
/// 실제로 일어나지 않아, 펼치기 줄이 화면 밖에 있으면 탭이 빗나간다.
Future<void> _tapExpand(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(MyFoldedList.expandKey));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(MyFoldedList.expandKey));
  await tester.pumpAndSettle();
}

void main() {
  group('비로그인', () {
    testWidgets('로그인 유도와 이 기기 이력을 함께 보여준다', (tester) async {
      await _pumpMy(
        tester,
        reports: MyReportList(count: 2, items: [fakeMyReport()]),
      );

      expect(find.text('로그인하면 더 편리하게 제보할 수 있어요'), findsOneWidget);
      expect(
        find.text('등록한 실종자를 관리하고,\n제보한 소식과 발견 소식을 빠르게 받아볼 수 있습니다.'),
        findsOneWidget,
      );

      // 빈 화면 대신 기기에 남은 이력을 준다. 제보는 로그인 없이 하는 것이
      // 기본이라(설계 결정 1번) 게스트도 자기 기록은 봐야 한다.
      expect(find.text('이 기기에서 한 제보'), findsOneWidget);
      expect(find.text('2건'), findsOneWidget);
      expect(find.text('김하준'), findsOneWidget);

      // 어디에 저장된 기록인지 알려준다.
      expect(find.textContaining('앱을 지우면 사라집니다'), findsOneWidget);
    });

    testWidgets('로그아웃은 없다', (tester) async {
      await _pumpMy(tester);
      expect(find.byKey(MyMenu.signOutKey), findsNothing);
    });

    testWidgets('알림 설정은 잠겨 있다', (tester) async {
      await _pumpMy(tester);

      // 감추면 로그인하면 뭐가 생기는지 알 수 없다. 자물쇠로 남겨둔다.
      expect(
        find.descendant(
          of: find.byKey(MyMenu.notificationKey),
          matching: find.byIcon(Icons.lock_outline),
        ),
        findsOneWidget,
      );
    });

    testWidgets('카카오 버튼을 누르면 시트 없이 바로 카카오 로그인으로 간다', (tester) async {
      await _pumpMy(tester);

      await tester.tap(find.byKey(MyLoginCard.loginButtonKey));
      await tester.pumpAndSettle();

      // 카드가 이미 로그인하면 무엇이 좋은지 말했다. 같은 말을 하는 시트를
      // 한 번 더 띄우면 버튼을 두 번 누르게 된다.
      expect(find.byType(LoginSheet), findsNothing);
      expect((lastKakao as FakeKakaoAuthSource).calls, 1);

      // 로그인하면 그 자리에서 프로필로 바뀐다.
      expect(find.byKey(MyLoginCard.loginButtonKey), findsNothing);
      expect(find.text('김보호'), findsOneWidget);
    });

    testWidgets('카카오에서 취소하면 조용히 카드가 그대로 남는다', (tester) async {
      await _pumpMy(tester, kakao: FakeKakaoAuthSource(token: null));

      await tester.tap(find.byKey(MyLoginCard.loginButtonKey));
      await tester.pumpAndSettle();

      // 취소는 오류가 아니다. 다시 누를 수 있어야 한다.
      expect(find.byKey(MyLoginCard.loginButtonKey), findsOneWidget);
      expect(find.byKey(MyLoginCard.errorKey), findsNothing);
    });

    testWidgets('실패하면 왜 안 됐는지 카드 안에 적는다', (tester) async {
      await _pumpMy(
        tester,
        authRepository: FakeAuthRepository(
          error: const ApiException('카카오 토큰 검증에 실패했습니다.'),
        ),
      );

      await tester.tap(find.byKey(MyLoginCard.loginButtonKey));
      await tester.pumpAndSettle();

      expect(find.byKey(MyLoginCard.loginButtonKey), findsOneWidget);
      expect(find.text('카카오 토큰 검증에 실패했습니다.'), findsOneWidget);
    });

    testWidgets('카카오를 기다리는 동안 다시 눌러도 한 번만 부른다', (tester) async {
      final kakao = _PendingKakaoAuthSource();
      await _pumpMy(tester, kakao: kakao);

      await tester.tap(find.byKey(MyLoginCard.loginButtonKey));
      await tester.pump();
      await tester.tap(find.byKey(MyLoginCard.loginButtonKey));
      await tester.pump();

      // 카카오톡이 뜨기까지 틈이 있다. 그 사이 한 번 더 누르면 로그인 창이
      // 두 번 열린다.
      expect(kakao.calls, 1);

      kakao.complete(null);
      await tester.pumpAndSettle();
    });

    testWidgets('제보한 적이 없으면 다그치지 않고 무엇을 하면 되는지 적는다', (tester) async {
      await _pumpMy(tester);

      expect(find.textContaining('아직 보낸 제보가 없어요'), findsOneWidget);
    });
  });

  group('로그인', () {
    testWidgets('프로필과 건수를 보여준다', (tester) async {
      await _pumpMy(
        tester,
        signedIn: true,
        reports: MyReportList(count: 6, items: [fakeMyReport()]),
      );

      expect(find.text('김보호'), findsOneWidget);
      // 서버가 센 숫자를 그대로 적는다. 앱이 세면 화면마다 달라진다.
      expect(find.text('등록 사건 1 · 제보 6'), findsOneWidget);

      expect(find.text('내 제보 이력'), findsOneWidget);
      expect(find.byType(MyLoginCard), findsNothing);
    });

    testWidgets('누구인지 확인하는 동안 비로그인 화면을 그리지 않는다', (tester) async {
      final auth = _PendingAuthRepository();
      await _pumpMy(
        tester,
        signedIn: true,
        authRepository: auth,
        settle: false,
      );
      await tester.pump();

      // 토큰은 있는데 서버 답을 기다리는 중이다. 여기서 게스트 화면을 그리면
      // 앱을 켜고 MY를 누를 때 로그인 권유가 잠깐 번쩍였다가 프로필로 바뀐다.
      expect(find.byType(MyLoginCard), findsNothing);
      expect(find.text('이 기기에서 한 제보'), findsNothing);
      expect(find.byType(LoadingView), findsOneWidget);

      auth.complete(_signedInProfile);
      await tester.pumpAndSettle();

      expect(find.text('김보호'), findsOneWidget);
      expect(find.byType(MyLoginCard), findsNothing);
    });

    testWidgets('누구인지 확인하지 못하면 로딩에 갇히지 않는다', (tester) async {
      await _pumpMy(
        tester,
        signedIn: true,
        authRepository: _FailingAuthRepository(),
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Riverpod이 뒤에서 다시 시도하는 동안에도 화면은 움직여야 한다. 계정을
      // 확인하지 못했으니 게스트로 보여주고, 이 기기 제보 이력은 그대로 준다.
      expect(find.byType(MyLoginCard), findsOneWidget);
      expect(find.text('이 기기에서 한 제보'), findsOneWidget);
    });

    testWidgets('로그아웃은 로그인한 사람에게만 있다', (tester) async {
      await _pumpMy(tester, signedIn: true);
      expect(find.byKey(MyMenu.signOutKey), findsOneWidget);
    });

    testWidgets('로그아웃을 누르면 한 번 묻고, 확인하면 게스트 화면으로 돌아간다', (tester) async {
      await _pumpMy(tester, signedIn: true);

      await tester.ensureVisible(find.byKey(MyMenu.signOutKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(MyMenu.signOutKey));
      await tester.pumpAndSettle();

      // 로그아웃하면 이 폰으로 내 사건 제보 알림이 끊긴다. 모르고 누르면 안 된다.
      expect(find.text('로그아웃할까요?'), findsOneWidget);
      expect(find.textContaining('제보 알림이 오지 않아요'), findsOneWidget);
      expect(lastTokens.token, 'token');

      await tester.tap(find.byKey(MySignOutDialog.confirmKey));
      await tester.pumpAndSettle();

      expect(lastTokens.token, isNull);
      expect((lastKakao as FakeKakaoAuthSource).signOutCalls, 1);
      expect(find.byType(MyLoginCard), findsOneWidget);
      expect(find.text('이 기기에서 한 제보'), findsOneWidget);
      expect(find.byKey(MyMenu.signOutKey), findsNothing);
    });

    testWidgets('로그아웃을 취소하면 그대로 남는다', (tester) async {
      await _pumpMy(tester, signedIn: true);

      await tester.ensureVisible(find.byKey(MyMenu.signOutKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(MyMenu.signOutKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(lastTokens.token, 'token');
      expect(find.text('김보호'), findsOneWidget);
    });

    testWidgets('카카오 로그아웃이 실패해도 앱에서는 로그아웃된다', (tester) async {
      await _pumpMy(
        tester,
        signedIn: true,
        kakao: FakeKakaoAuthSource(signOutError: Exception('network')),
      );

      await tester.ensureVisible(find.byKey(MyMenu.signOutKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(MyMenu.signOutKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(MySignOutDialog.confirmKey));
      await tester.pumpAndSettle();

      // 카카오 서버가 안 받는다고 로그인 상태로 남으면, 사용자는 로그아웃
      // 버튼이 고장 난 줄 안다.
      expect(lastTokens.token, isNull);
      expect(find.byType(MyLoginCard), findsOneWidget);
    });

    testWidgets('알림 설정 자물쇠가 풀린다', (tester) async {
      await _pumpMy(tester, signedIn: true);

      expect(
        find.descendant(
          of: find.byKey(MyMenu.notificationKey),
          matching: find.byIcon(Icons.lock_outline),
        ),
        findsNothing,
      );
    });
  });

  group('내가 등록한 실종자', () {
    testWidgets('진행 중과 지난 사건을 나눠 적는다', (tester) async {
      await _pumpMy(
        tester,
        signedIn: true,
        cases: MissingCaseList(
          count: 2,
          items: [
            fakeMyCase(),
            fakeMyCase(
              id: 'm_2',
              name: '이순자',
              age: 81,
              status: CaseStatus.resolved,
              reportCount: 11,
              resolvedAt: DateTime(2026, 8, 24),
            ),
          ],
        ),
      );

      expect(find.text('내가 등록한 실종자'), findsOneWidget);
      expect(find.text('1건 진행 중'), findsOneWidget);

      // 끝난 사건도 지우지 않고 아래에 남긴다(설계 결정 7번).
      expect(find.text('지난 사건'), findsOneWidget);
      expect(find.textContaining('제보 11건으로 발견'), findsOneWidget);
    });

    testWidgets('게스트에게는 이 구역 자체가 없다', (tester) async {
      await _pumpMy(
        tester,
        cases: MissingCaseList(count: 1, items: [fakeMyCase()]),
      );

      // 등록에는 로그인이 필요하니 게스트에게는 내 사건이라는 개념이 없다.
      expect(find.text('내가 등록한 실종자'), findsNothing);
    });

    testWidgets('발견 완료는 한 번 묻고 나서 바꾼다', (tester) async {
      await _pumpMy(
        tester,
        signedIn: true,
        cases: MissingCaseList(count: 1, items: [fakeMyCase()]),
      );

      await tester.tap(find.byKey(MyCaseCard.resolveButtonKey));
      await tester.pumpAndSettle();

      // 되돌리기 어렵고 제보자들에게 알림이 나간다. 그냥 바뀌면 안 된다.
      expect(find.textContaining('찾으셨나요'), findsOneWidget);
      expect(lastRepository.resolved, isEmpty);

      await tester.tap(find.byKey(const Key('my_case_resolve_confirm')));
      await tester.pumpAndSettle();

      expect(lastRepository.resolved, ['m_1']);
    });

    testWidgets('발견 완료하면 홈도 다시 받아온다', (tester) async {
      await _pumpMy(
        tester,
        signedIn: true,
        cases: MissingCaseList(count: 1, items: [fakeMyCase()]),
      );
      // 홈 탭은 껍데기 아래에 살아 있다. 그 상태를 흉내 내 홈 피드를 붙들어 둔다.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MyScreen)),
      );
      container.listen(homeFeedProvider, (_, _) {});
      await tester.pumpAndSettle();
      final before = homeFeedFetches;

      await tester.tap(find.byKey(MyCaseCard.resolveButtonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('my_case_resolve_confirm')));
      await tester.pumpAndSettle();

      // 다시 받지 않으면 찾은 사람이 홈에 진행 중으로 남는다(실기기 2026-09-14).
      expect(homeFeedFetches, greaterThan(before));
    });

    testWidgets('확인 창의 두 버튼은 한 줄에 나란히 선다', (tester) async {
      await _pumpMy(
        tester,
        signedIn: true,
        cases: MissingCaseList(count: 1, items: [fakeMyCase()]),
      );

      await tester.tap(find.byKey(MyCaseCard.resolveButtonKey));
      await tester.pumpAndSettle();

      final no = tester.getRect(find.text('아니요'));
      final yes = tester.getRect(
        find.byKey(const Key('my_case_resolve_confirm')),
      );

      // 가로를 꽉 채우는 버튼이 끼면 아니요가 위로 밀리고 확인이 커진다(실기기).
      expect(no.center.dy, moreOrLessEquals(yes.center.dy, epsilon: 1));
      expect(yes.width, lessThan(200));
    });

    testWidgets('아니요를 누르면 아무 일도 없다', (tester) async {
      await _pumpMy(
        tester,
        signedIn: true,
        cases: MissingCaseList(count: 1, items: [fakeMyCase()]),
      );

      await tester.tap(find.byKey(MyCaseCard.resolveButtonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('아니요'));
      await tester.pumpAndSettle();

      expect(lastRepository.resolved, isEmpty);
    });

    testWidgets('끝난 사건에는 발견 완료 버튼이 없다', (tester) async {
      await _pumpMy(
        tester,
        signedIn: true,
        cases: MissingCaseList(
          count: 1,
          items: [fakeMyCase(status: CaseStatus.resolved)],
        ),
      );

      expect(find.byKey(MyCaseCard.resolveButtonKey), findsNothing);
    });
  });

  group('제보 한 건', () {
    testWidgets('경로에 들어갔는지 적는다', (tester) async {
      await _pumpMy(
        tester,
        reports: MyReportList(
          count: 2,
          items: [
            fakeMyReport(id: 'r_1'),
            fakeMyReport(
              id: 'r_2',
              missingName: '이순자',
              similarity: 34.2,
              grade: SimilarityGrade.low,
              contributedToPath: false,
            ),
          ],
        ),
      );

      // 내 제보가 어딘가에 쓰였다는 표시가 다음 제보를 부른다.
      expect(find.text('경로에 반영됨'), findsOneWidget);
      // 안 들어간 제보를 실패로 적지 않는다(설계 결정 3번).
      expect(find.text('확인 필요'), findsOneWidget);
    });

    testWidgets('끝난 사건이면 발견 완료를 덧붙인다', (tester) async {
      await _pumpMy(
        tester,
        reports: MyReportList(
          count: 1,
          items: [fakeMyReport(missingStatus: CaseStatus.resolved)],
        ),
      );

      expect(find.textContaining('발견 완료'), findsOneWidget);
    });
  });

  group('길어지는 목록', () {
    testWidgets('제보 이력은 접어 두고 몇 건만 보여준다', (tester) async {
      await _pumpMy(
        tester,
        reports: MyReportList(
          count: 12,
          items: [for (var i = 0; i < 12; i++) fakeMyReport(id: 'r_$i')],
        ),
      );

      // 접혀 있어도 머리글 건수는 전체를 말한다. 서버에서 잘라 오면
      // "12건"이라 적어 놓고 5건만 주는 셈이 된다.
      expect(find.text('12건'), findsOneWidget);
      expect(find.byType(MyReportTile), findsNWidgets(MyScreen.reportsPreview));
      expect(find.text('7건 더 보기'), findsOneWidget);
    });

    testWidgets('더 보기를 누르면 나머지가 펼쳐지고 다시 접힌다', (tester) async {
      await _pumpMy(
        tester,
        reports: MyReportList(
          count: 12,
          items: [for (var i = 0; i < 12; i++) fakeMyReport(id: 'r_$i')],
        ),
      );

      await _tapExpand(tester);

      expect(find.byType(MyReportTile), findsNWidgets(12));
      expect(find.text('접기'), findsOneWidget);

      await _tapExpand(tester);

      expect(find.byType(MyReportTile), findsNWidgets(MyScreen.reportsPreview));
    });

    testWidgets('상한을 안 넘으면 더 보기 줄을 내밀지 않는다', (tester) async {
      await _pumpMy(
        tester,
        reports: MyReportList(
          count: MyScreen.reportsPreview,
          items: [
            for (var i = 0; i < MyScreen.reportsPreview; i++)
              fakeMyReport(id: 'r_$i'),
          ],
        ),
      );

      expect(find.byType(MyReportTile), findsNWidgets(MyScreen.reportsPreview));
      expect(find.byKey(MyFoldedList.expandKey), findsNothing);
    });

    testWidgets('지난 사건만 접고 진행 중인 사건은 전부 보여준다', (tester) async {
      await _pumpMy(
        tester,
        signedIn: true,
        reports: MyReportList(
          count: 1,
          items: [fakeMyReport(missingName: '박민재')],
        ),
        cases: MissingCaseList(
          count: 7,
          items: [
            fakeMyCase(id: 'm_a', name: '김하준'),
            fakeMyCase(id: 'm_b', name: '이서연'),
            for (var i = 0; i < 5; i++)
              fakeMyCase(
                id: 'm_old_$i',
                name: '한복순',
                status: CaseStatus.resolved,
              ),
          ],
        ),
      );

      // 진행 중 2건은 그대로 + 지난 사건 5건 중 3건.
      expect(
        find.byType(MyCaseCard),
        findsNWidgets(2 + MyScreen.pastCasesPreview),
      );
      // 발견 완료를 누를 수 있어야 하므로 진행 중은 하나도 안 접는다.
      expect(find.text('김하준'), findsOneWidget);
      expect(find.text('이서연'), findsOneWidget);
      expect(find.text('2건 더 보기'), findsOneWidget);
      // 제보는 1건뿐이라 그쪽에는 더 보기가 없다.
      expect(find.byKey(MyFoldedList.expandKey), findsOneWidget);
    });
  });
}
