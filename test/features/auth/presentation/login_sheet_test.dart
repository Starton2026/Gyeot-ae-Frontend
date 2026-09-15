import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/network/api_exception.dart';
import 'package:gyeotae/core/network/dio_provider.dart';
import 'package:gyeotae/core/theme/app_theme.dart';
import 'package:gyeotae/features/auth/data/auth_repository.dart';
import 'package:gyeotae/features/auth/data/auth_session.dart';
import 'package:gyeotae/features/auth/data/kakao_auth_source.dart';
import 'package:gyeotae/features/auth/presentation/widgets/login_sheet.dart';

import '../../../support/fake_auth.dart';
import '../../../support/in_memory_token_storage.dart';

/// 시트를 여는 버튼 하나짜리 화면. 시트가 무엇 위에 뜨든 상관없다.
const Key _openKey = Key('open_sheet');

Future<
  ({
    FakeKakaoAuthSource kakao,
    FakeAuthRepository repository,
    InMemoryTokenStorage tokens,
    List<AuthSession?> results,
  })
>
_open(
  WidgetTester tester, {
  FakeKakaoAuthSource? kakao,
  FakeAuthRepository? repository,
}) async {
  final source = kakao ?? FakeKakaoAuthSource();
  final repo = repository ?? FakeAuthRepository();
  final tokens = InMemoryTokenStorage();
  final results = <AuthSession?>[];

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        kakaoAuthSourceProvider.overrideWithValue(source),
        authRepositoryProvider.overrideWithValue(repo),
        tokenStorageProvider.overrideWithValue(tokens),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: _openKey,
              onPressed: () async => results.add(await showLoginSheet(context)),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.byKey(_openKey));
  await tester.pumpAndSettle();

  return (kakao: source, repository: repo, tokens: tokens, results: results);
}

void main() {
  testWidgets('왜 로그인하는지와, 안 해도 된다는 것을 함께 적는다', (tester) async {
    await _open(tester);

    // 요구하는 이유(F-6.1). 안 적으면 계정을 모으려는 것으로 읽힌다.
    expect(find.textContaining('허위 등록을 막기 위해'), findsOneWidget);
    expect(find.textContaining('실종자 등록에만 요구되며'), findsOneWidget);

    // 카카오 하나뿐이라 더 중요한 문장(F-6.2). 이게 빠지면 카카오 계정이 없는
    // 사람이 서비스 전체를 못 쓴다고 오해한다.
    expect(find.textContaining('제보는 로그인 없이도 할 수 있어요'), findsOneWidget);

    expect(find.byKey(LoginSheet.kakaoButtonKey), findsOneWidget);
  });

  testWidgets('로그인하면 토큰을 저장하고 시트만 닫힌다', (tester) async {
    final env = await _open(tester);

    await tester.tap(find.byKey(LoginSheet.kakaoButtonKey));
    await tester.pumpAndSettle();

    expect(env.repository.lastAccessToken, 'kakao-access-token');
    // 토큰이 저장돼야 다음 요청에 실려 나간다(AuthInterceptor).
    expect(await env.tokens.read(), 'server-token');

    expect(find.byType(LoginSheet), findsNothing);
    // 하려던 일로 이어갈 수 있도록 세션을 돌려준다(F-6.4).
    expect(env.results.single?.user.name, '김보호');
    expect(env.results.single?.claimedReports, 2, reason: '게스트 제보 귀속 건수');
  });

  testWidgets('취소하면 시트가 그대로 남는다', (tester) async {
    final env = await _open(tester, kakao: FakeKakaoAuthSource(token: null));

    await tester.tap(find.byKey(LoginSheet.kakaoButtonKey));
    await tester.pumpAndSettle();

    // 취소는 오류가 아니다. 다시 누를 수 있어야 한다.
    expect(find.byType(LoginSheet), findsOneWidget);
    expect(env.results, isEmpty);
    expect(await env.tokens.read(), isNull);
  });

  testWidgets('실패하면 왜 안 됐는지 시트 안에 적는다', (tester) async {
    await _open(
      tester,
      repository: FakeAuthRepository(
        error: const ApiException('카카오 토큰 검증에 실패했습니다.'),
      ),
    );

    await tester.tap(find.byKey(LoginSheet.kakaoButtonKey));
    await tester.pumpAndSettle();

    // 시트가 닫혀버리면 무엇이 잘못됐는지 볼 자리가 없다.
    expect(find.byType(LoginSheet), findsOneWidget);
    expect(find.text('카카오 토큰 검증에 실패했습니다.'), findsOneWidget);
  });

  testWidgets('카카오를 아직 안 붙였으면 그렇다고 적는다', (tester) async {
    await _open(
      tester,
      kakao: FakeKakaoAuthSource(
        error: const ApiException('카카오 로그인은 아직 연결되지 않았어요. 조금만 기다려 주세요.'),
      ),
    );

    await tester.tap(find.byKey(LoginSheet.kakaoButtonKey));
    await tester.pumpAndSettle();

    // 버튼이 먹통인지 로그인이 실패한 것인지 구분되어야 한다.
    expect(find.textContaining('아직 연결되지 않았어요'), findsOneWidget);
  });
}
