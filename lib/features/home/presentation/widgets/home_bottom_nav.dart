import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 하단 네비게이션 4탭. 실종자 등록은 여기에 넣지 않는다(기능정의서 3).
///
/// TODO(네비게이션): 실종자(S2)·지도(S5)·MY(S8) 화면이 생기면 go_router의
/// 셸 라우트로 묶고 [_NavTab]에 이동을 연결한다. 화면이 없는 동안에는
/// 눌리지 않는 회색으로 둔다.
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(8, 9, 8, 10),
          child: Row(
            children: [
              _NavTab(icon: Icons.home_outlined, label: '홈', selected: true),
              _NavTab(icon: Icons.people_outline, label: '실종자'),
              _NavTab(icon: Icons.place_outlined, label: '지도'),
              _NavTab(icon: Icons.person_outline, label: 'MY'),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textDisabled;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 23, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.small.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
