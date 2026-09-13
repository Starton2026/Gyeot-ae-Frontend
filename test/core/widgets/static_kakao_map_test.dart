import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/map/map_plan.dart';
import 'package:gyeotae/core/theme/app_theme.dart';
import 'package:gyeotae/core/widgets/map_preview_card.dart';
import 'package:gyeotae/core/widgets/static_kakao_map.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart' show KakaoMap;

const _plan = MapPlan(center: (lat: 37.47, lng: 126.75), zoomLevel: 13);

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  testWidgets('지도 키가 없으면 카카오맵을 띄우지 않고 회색 판을 둔다', (tester) async {
    await _pump(
      tester,
      const SizedBox(
        width: 300,
        height: 150,
        child: StaticKakaoMap(plan: _plan, ready: false),
      ),
    );

    // 키 없이 플랫폼 뷰를 올리면 설명 없는 흰 판이 된다.
    expect(find.byType(KakaoMap), findsNothing);
    expect(find.byKey(StaticKakaoMap.placeholderKey), findsOneWidget);
  });

  testWidgets('지도 카드는 받은 지도를 회색 판 자리에 그린다', (tester) async {
    await _pump(
      tester,
      const SizedBox(
        width: 320,
        child: MapPreviewCard(
          height: 150,
          label: '내 주변 실종 2건',
          map: ColoredBox(key: Key('fake_map'), color: Colors.green),
        ),
      ),
    );

    expect(find.byKey(const Key('fake_map')), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('fake_map'))).height, 150);
  });

  testWidgets('지도 위를 눌러도 카드가 눌린다', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      SizedBox(
        width: 320,
        child: MapPreviewCard(
          height: 150,
          label: '내 주변 실종 2건',
          onTap: () => taps += 1,
          map: const StaticKakaoMap(plan: _plan, ready: false),
        ),
      ),
    );

    // 보기 전용이다. 지도가 손가락을 먹지 않고 카드(지도 탭으로 가기)가 받는다.
    await tester.tap(find.byKey(StaticKakaoMap.placeholderKey));

    expect(taps, 1);
  });
}
