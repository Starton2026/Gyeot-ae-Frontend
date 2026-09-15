import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 알림 설정의 한 구역. 제목, 무엇을 정하는지 한 줄, 그리고 고르는 칸.
class NotificationSection extends StatelessWidget {
  const NotificationSection({
    required this.title,
    required this.description,
    required this.child,
    super.key,
  });

  final String title;

  /// 이 값을 바꾸면 무엇이 달라지는지. 칩만 있으면 반경이 누구 기준인지,
  /// 대상을 끄면 무엇이 안 오는지 알 수 없다.
  final String description;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.title0),
        const SizedBox(height: 4),
        Text(
          description,
          style: AppTextStyles.body0.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
