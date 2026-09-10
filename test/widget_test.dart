import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/app.dart';
import 'package:gyeotae/features/auth/presentation/login_screen.dart';
import 'package:gyeotae/features/home/presentation/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('앱을 실행하면 로그인 없이 홈 화면이 보인다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GyeotaeApp()));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('홈에서 로그인 버튼을 누르면 로그인 화면으로 이동한다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GyeotaeApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HomeScreen.loginButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
