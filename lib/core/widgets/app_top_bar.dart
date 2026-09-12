import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_icon.dart';

/// 상단바(기능정의서 5.5).
///
/// 홈은 가운데에 로고를 두고([AppTopBar.brand]), 실종자·지도·MY는 화면 제목을
/// 둔다([AppTopBar.title]). 오른쪽 알림 버튼은 네 탭이 함께 쓴다.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// 홈 전용. 가운데에 워드마크를 둔다.
  const AppTopBar.brand({super.key}) : title = null;

  /// 실종자·지도·MY. 가운데에 화면 제목을 둔다.
  const AppTopBar.title(String this.title, {super.key});

  final String? title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final label = title;

    return AppBar(
      title: label == null ? const _Wordmark() : Text(label),
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
              TextSpan(text: '곁', style: TextStyle(color: AppColors.primary)),
              TextSpan(text: '애', style: TextStyle(color: AppColors.accent)),
            ],
          ),
          style: AppTextStyles.headline0,
        ),
      ],
    );
  }
}
