import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// 앱 전체 테마.
///
/// 색은 [AppColors], 글자는 [AppTextStyles]가 원본이다. 여기서는 그것을
/// Material 슬롯에 연결만 한다. 새 색이나 새 글자 크기를 여기서 만들지 않는다.
///
/// 다크 테마는 두지 않는다. 디자인 토큰이 라이트 전용이라, 다크를 흉내 내면
/// 토큰에 없는 색을 지어내야 한다.
class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: AppColors.white,
          secondary: AppColors.accent,
          onSecondary: AppColors.white,
          error: AppColors.error,
          onError: AppColors.white,
          surface: AppColors.background,
          onSurface: AppColors.textPrimary,
          surfaceContainerLow: AppColors.backgroundSubtle,
          surfaceContainerLowest: AppColors.background,
          outline: AppColors.border,
          outlineVariant: AppColors.border,
        );

    return ThemeData(
      colorScheme: colorScheme,
      fontFamily: AppTextStyles.fontFamily,
      textTheme: _textTheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        // Material 3은 본문이 상단바 밑으로 지나가면 배경에 색을 덧씌우고
        // 그림자를 준다. 스크롤하다 상단바 색이 바뀌어 보이는 이유다.
        // 흰 배경 하나로 고정한다.
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        centerTitle: true,
        // 색을 빼면 안 된다. AppBar는 appBarTheme.titleTextStyle이 있으면
        // foregroundColor를 얹지 않아서, 색 없는 스타일이 그대로 흰 글자로
        // 그려진다(흰 배경 위에서 제목이 사라진다).
        titleTextStyle: AppTextStyles.title0.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: AppTextStyles.button,
          disabledBackgroundColor: AppColors.primaryDisabled,
          disabledForegroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.button,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.subtitle0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundSubtle,
        hintStyle: AppTextStyles.subtitle1.copyWith(
          color: AppColors.textDisabled,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.background,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        // 꺼짐일 때 손잡이를 흰색으로 둔다. 기본값은 옅은 파랑이라 트랙과
        // 색이 붙어서 켜졌는지 꺼졌는지 눈으로 구분되지 않는다.
        thumbColor: const WidgetStatePropertyAll(AppColors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textDisabled;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.backgroundSubtle,
        labelStyle: AppTextStyles.body1,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  /// 카드 안에 얹히는 버튼의 모양.
  ///
  /// 화면 아래를 가로지르는 주 버튼(높이 52)보다 한 치수 작다. 긴급 배너나
  /// 등록 소개 블록처럼 이미 색이 있는 카드 위에 올라가는 버튼은 같은 크기로
  /// 두면 카드보다 버튼이 먼저 읽힌다.
  ///
  /// 배경색·글자색은 카드마다 달라서 쓰는 쪽이 정하고, **크기와 모서리는 여기서만
  /// 정한다.** 위젯이 제 마음대로 `shape`을 만들지 않게 하려는 것이다.
  static ButtonStyle cardButton({
    required Color background,
    required Color foreground,
  }) {
    return FilledButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      // 화면이 아직 없어 눌리지 않는 버튼도 색이 죽지 않게 같은 색을 준다.
      disabledBackgroundColor: background,
      disabledForegroundColor: foreground,
      minimumSize: const Size.fromHeight(46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  /// [AppTextStyles]를 Material 슬롯에 연결한다.
  ///
  /// 위젯에서 `Theme.of(context).textTheme.*`를 써도, [AppTextStyles]를 직접
  /// 써도 같은 값이 나오게 맞춘 것이다.
  static const TextTheme _textTheme = TextTheme(
    displaySmall: AppTextStyles.headline1,
    headlineMedium: AppTextStyles.heading2,
    headlineSmall: AppTextStyles.headline0,
    titleLarge: AppTextStyles.title0,
    titleMedium: AppTextStyles.title1,
    titleSmall: AppTextStyles.subtitle0,
    bodyLarge: AppTextStyles.body2,
    bodyMedium: AppTextStyles.subtitle1,
    bodySmall: AppTextStyles.body0,
    labelLarge: AppTextStyles.button,
    labelMedium: AppTextStyles.body1,
    labelSmall: AppTextStyles.small,
  );
}
