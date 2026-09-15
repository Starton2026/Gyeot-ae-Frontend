import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/app.dart';
import 'package:gyeotae/features/auth/presentation/widgets/login_sheet.dart';
import 'package:gyeotae/features/home/presentation/home_screen.dart';
import 'package:gyeotae/core/widgets/guardian_shortcut_banner.dart';
import 'package:gyeotae/features/missing/presentation/missing_register_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/offline_repositories.dart';
import 'support/onboarding_overrides.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('앱을 실행하면 로그인 없이 홈 화면이 보인다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...startAfterOnboarding(), ...offlineRepositories()],
        child: const GyeotaeApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('로그인 전에 실종자 등록 바로가기를 누르면 폼 위에 로그인 시트가 덮는다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...startAfterOnboarding(), ...offlineRepositories()],
        child: const GyeotaeApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(GuardianShortcutBanner.registerShortcutKey));
    await tester.pumpAndSettle();

    // 로그인은 독립 화면이 아니라 끼어드는 시트다(기능정의서 3). 등록 폼이
    // 뒤에 보여야 무엇을 요구하는지 본 채로 로그인한다(시안 S6).
    expect(find.byType(LoginSheet), findsOneWidget);
    expect(find.byType(MissingRegisterScreen), findsOneWidget);
  });
}
