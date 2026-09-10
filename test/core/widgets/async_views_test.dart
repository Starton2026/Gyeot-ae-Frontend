import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/widgets/error_view.dart';
import 'package:gyeotae/core/widgets/loading_view.dart';

void main() {
  testWidgets('LoadingView는 진행 표시기를 보여준다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LoadingView())),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('ErrorView는 전달받은 메시지를 보여준다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ErrorView(message: '네트워크 연결을 확인해 주세요.')),
      ),
    );

    expect(find.text('네트워크 연결을 확인해 주세요.'), findsOneWidget);
  });

  testWidgets('ErrorView의 다시 시도 버튼을 누르면 onRetry가 호출된다', (tester) async {
    var retried = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorView(message: '오류', onRetry: () => retried++),
        ),
      ),
    );
    await tester.tap(find.byKey(ErrorView.retryButtonKey));

    expect(retried, 1);
  });

  testWidgets('onRetry가 없으면 다시 시도 버튼을 그리지 않는다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ErrorView(message: '오류')),
      ),
    );

    expect(find.byKey(ErrorView.retryButtonKey), findsNothing);
  });
}
