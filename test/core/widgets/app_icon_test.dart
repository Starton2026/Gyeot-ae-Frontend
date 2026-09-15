import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/theme/app_colors.dart';
import 'package:gyeotae/core/widgets/app_icon.dart';

void main() {
  testWidgets('지정한 크기의 정사각 박스로 그린다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: AppIcon(AppIcons.bell, size: 32))),
      ),
    );

    expect(tester.getSize(find.byType(AppIcon)), const Size(32, 32));
  });

  testWidgets('세로로 긴 아이콘도 박스를 넘지 않는다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: AppIcon(AppIcons.rightAngleBracket, size: 20)),
        ),
      ),
    );

    expect(tester.getSize(find.byType(AppIcon)), const Size(20, 20));
  });

  testWidgets('color를 주면 그 색으로 칠한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppIcon(AppIcons.share, color: AppColors.accent)),
      ),
    );

    final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));

    expect(
      svg.colorFilter,
      const ColorFilter.mode(AppColors.accent, BlendMode.srcIn),
    );
  });

  testWidgets('color를 생략하면 IconTheme 색을 따른다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: IconTheme(
          data: IconThemeData(color: AppColors.primary),
          child: Scaffold(body: AppIcon(AppIcons.glass)),
        ),
      ),
    );

    final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));

    expect(
      svg.colorFilter,
      const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
    );
  });

  testWidgets('AppIcons의 모든 경로가 실제 에셋을 가리킨다', (tester) async {
    expect(AppIcons.all, isNotEmpty);

    for (final asset in AppIcons.all) {
      final data = await rootBundle.load(asset);

      expect(data.lengthInBytes, greaterThan(0), reason: '$asset 이(가) 비어 있다');
    }
  });
}
