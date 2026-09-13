import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 온보딩 한 장. 그림 → 제목 → 설명 순으로 읽힌다.
///
/// 세 장이 같은 자리에 같은 크기로 서야 넘길 때 글자가 튀지 않는다. 그래서
/// 그림 영역 높이를 고정한다.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    required this.art,
    required this.title,
    required this.body,
    this.extra,
    super.key,
  });

  final Widget art;

  /// 두 줄로 끊어 적는다. 한 줄로 흐르면 넘기는 리듬이 무너진다.
  final String title;

  /// 설명. 강조할 말이 있어서 문자열이 아니라 위젯으로 받는다.
  final Widget body;

  /// 제목·설명 아래에 더 붙는 것. 3장의 권한 목록이 여기 들어간다.
  final Widget? extra;

  /// 그림 자리 높이. 시안 값이다.
  static const double artHeight = 252;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: artHeight,
            width: double.infinity,
            child: Center(child: art),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: AppTextStyles.heading2.copyWith(
              letterSpacing: -0.8,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 13),
          DefaultTextStyle(
            style: AppTextStyles.subtitle1.copyWith(
              color: AppColors.textSecondary,
              height: 1.7,
            ),
            child: body,
          ),
          if (extra != null) ...[const SizedBox(height: 18), extra!],
        ],
      ),
    );
  }
}
