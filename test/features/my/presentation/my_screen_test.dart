import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/network/dio_provider.dart';
import 'package:gyeotae/core/theme/app_theme.dart';
import 'package:gyeotae/features/auth/data/auth_repository.dart';
import 'package:gyeotae/features/auth/data/auth_session.dart';
import 'package:gyeotae/features/auth/data/kakao_auth_source.dart';
import 'package:gyeotae/features/auth/presentation/widgets/login_sheet.dart';
import 'package:gyeotae/features/missing/data/missing_case.dart';
import 'package:gyeotae/features/my/data/my_report.dart';
import 'package:gyeotae/features/my/data/my_repository.dart';
import 'package:gyeotae/features/my/presentation/my_screen.dart';
import 'package:gyeotae/features/my/presentation/widgets/my_case_card.dart';
import 'package:gyeotae/features/my/presentation/widgets/my_login_card.dart';
import 'package:gyeotae/features/my/presentation/widgets/my_menu.dart';
import 'package:gyeotae/features/report/data/report.dart';

import '../../../support/fake_auth.dart';
import '../../../support/fake_my_repository.dart';
import '../../../support/in_memory_token_storage.dart';

const _signedInProfile = AuthProfile(
  user: AuthUser(id: 'u_1', name: '김보호'),
  caseCount: 1,
  reportCount: 6,
);

late FakeMyRepository lastRepository;

Future<void> _pumpMy(
  WidgetTester tester, {
  bool signedIn = false,
  MyReportList? reports,
  MissingCaseList? cases,
}) async {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // 로그인 상태는 저장된 토큰으로 갈린다.
        tokenStorageProvider.overrideWithValue(
          InMemoryTokenStorage(signedIn ? 'token' : null),
        ),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(user: signedIn ? _signedInProfile : null),
        ),
        kakaoAuthSourceProvider.overrideWithValue(FakeKakaoAuthSource()),
        myRepositoryProvider.overrideWithValue(
          lastRepository = FakeMyRepository(reports: reports, cases: cases),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const MyScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('비로그인', () {
    testWidgets('로그인 유도와 이 기기 이력을 함께 보여준다', (tester) async {
      await _pumpMy(
        tester,
        reports: MyReportList(count: 2, items: [fakeMyReport()]),
      );

      expect(find.text('로그인하면 더 챙겨드려요'), findsOneWidget);

      // 빈 화면 대신 기기에 남은 이력을 준다. 제보는 로그인 없이 하는 것이
      // 기본이라(설계 결정 1번) 게스트도 자기 기록은 봐야 한다.
      expect(find.text('이 기기에서 한 제보'), findsOneWidget);
      expect(find.text('2건'), findsOneWidget);
      expect(find.text('김하준'), findsOneWidget);

      // 어디에 저장된 기록인지 알려준다.
      expect(find.textContaining('앱을 지우면 사라집니다'), findsOneWidget);
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

    testWidgets('카카오 버튼을 누르면 로그인 시트가 뜬다', (tester) async {
      await _pumpMy(tester);

      await tester.tap(find.byKey(MyLoginCard.loginButtonKey));
      await tester.pumpAndSettle();

      expect(find.byType(LoginSheet), findsOneWidget);
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
      expect(find.text('로그인하면 더 챙겨드려요'), findsNothing);
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
      await _pumpMy(tester, cases: MissingCaseList(count: 1, items: [fakeMyCase()]));

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
}
