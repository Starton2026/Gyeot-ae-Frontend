import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/theme/app_colors.dart';
import 'package:gyeotae/core/theme/app_text_styles.dart';
import 'package:gyeotae/core/theme/app_theme.dart';

void main() {
  test('글자는 Pretendard로 그린다', () {
    final theme = AppTheme.light;

    expect(theme.textTheme.bodyMedium?.fontFamily, AppTextStyles.fontFamily);
    expect(theme.textTheme.titleLarge?.fontFamily, AppTextStyles.fontFamily);
  });

  test('상단바 제목에는 색이 들어 있다', () {
    // AppBar는 appBarTheme.titleTextStyle이 있으면 foregroundColor를 얹지
    // 않는다. 색 없는 스타일을 주면 제목이 흰 글자로 그려져 사라진다.
    final titleStyle = AppTheme.light.appBarTheme.titleTextStyle;

    expect(titleStyle?.color, AppColors.textPrimary);
  });

  test('상단바는 본문이 밑으로 지나가도 색이 변하지 않는다', () {
    // Material 3 기본값은 스크롤 시 배경에 틴트를 덧씌우고 그림자를 준다.
    final appBarTheme = AppTheme.light.appBarTheme;

    expect(appBarTheme.scrolledUnderElevation, 0);
    expect(appBarTheme.surfaceTintColor, Colors.transparent);
  });

  test('주요 액션 색은 디자인 토큰의 primary다', () {
    final colorScheme = AppTheme.light.colorScheme;

    expect(colorScheme.primary, AppColors.primary);
    expect(colorScheme.secondary, AppColors.accent);
    expect(colorScheme.surface, AppColors.background);
    expect(colorScheme.error, AppColors.error);
  });

  test('textTheme 슬롯이 AppTextStyles 크기·굵기를 그대로 쓴다', () {
    final textTheme = AppTheme.light.textTheme;

    expect(textTheme.titleLarge?.fontSize, AppTextStyles.title0.fontSize);
    expect(textTheme.titleLarge?.fontWeight, AppTextStyles.title0.fontWeight);
    expect(textTheme.bodyMedium?.fontSize, AppTextStyles.subtitle1.fontSize);
    expect(textTheme.labelSmall?.fontSize, AppTextStyles.small.fontSize);
  });

  test('경과 시간 타이머는 숫자 폭이 고정이다', () {
    expect(
      AppTextStyles.timer.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });
}
