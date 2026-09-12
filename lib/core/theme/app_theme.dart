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
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.title0,
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
