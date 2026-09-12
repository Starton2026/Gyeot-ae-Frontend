import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_icon.dart';

/// 홈 상단바. 상단바 규칙(기능정의서 5.5)의 "로고(중앙) + 알림" 변형이다.
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const _Wordmark(),
      actions: [
        const IconButton(
          // TODO(알림): 알림 화면이 생기면 연결한다.
          onPressed: null,
          icon: AppIcon(
            AppIcons.bell,
            size: 22,
            color: AppColors.textSecondary,
          ),
          tooltip: '알림',
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

/// 마크 + 워드마크.
///
/// 화면 낭독기가 `愛`를 중국어로 읽거나 건너뛰기 때문에, 앱 안에서는 한글
/// `곁애`를 쓴다(설계 결정 10번). `곁愛`는 앱 아이콘·스플래시가 맡는다.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo_icon.png',
          height: 22,
          excludeFromSemantics: true,
        ),
        const SizedBox(width: 7),
        const Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '곁',
                style: TextStyle(color: AppColors.primary),
              ),
              TextSpan(
                text: '애',
                style: TextStyle(color: AppColors.accent),
              ),
            ],
          ),
          style: AppTextStyles.headline0,
        ),
      ],
    );
  }
}
