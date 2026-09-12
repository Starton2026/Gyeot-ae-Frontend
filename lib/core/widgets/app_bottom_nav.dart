import 'package:flutter/material.dart';

import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 하단 네비게이션의 4탭(기능정의서 3).
///
/// 실종자 등록은 여기에 넣지 않는다. 평생 한 번도 누르지 않는 것이 최선인
/// 기능이 4칸 중 하나를 차지할 이유가 없다. 대신 화면 위의 바로가기 띠와
/// 아래의 소개 블록으로 처리한다.
enum AppTab {
  home('홈', Icons.home_outlined, AppRoute.home),
  missing('실종자', Icons.people_outline, AppRoute.missingList),
  map('지도', Icons.place_outlined, AppRoute.map),
  my('MY', Icons.person_outline, null);

  const AppTab(this.label, this.icon, this.path);

  final String label;
  final IconData icon;

  /// 갈 곳. **아직 화면이 없는 탭은 null이다.**
  ///
  /// TODO(S8): MY 화면이 생기면 경로를 채운다. 그러면 [AppBottomNav]가
  /// 알아서 눌리는 탭으로 그린다.
  final String? path;

  bool get isReady => path != null;
}

/// 하단 네비게이션 바.
///
/// 화면이 없는 탭은 눌리지 않는 회색으로 둔다. 눌러도 아무 일이 없는 것보다
/// 낫고, 감추면 탭 위치가 나중에 바뀌어 손이 기억한 자리가 어긋난다.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.current,
    required this.onSelect,
    super.key,
  });

  final AppTab current;

  /// 누를 수 있는 탭을 눌렀을 때만 불린다.
  final ValueChanged<AppTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 9, 8, 10),
          child: Row(
            children: [
              for (final tab in AppTab.values)
                _NavTab(
                  tab: tab,
                  selected: tab == current,
                  onTap: tab.isReady && tab != current
                      ? () => onSelect(tab)
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({required this.tab, required this.selected, this.onTap});

  final AppTab tab;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textDisabled;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tab.icon, size: 23, color: color),
              const SizedBox(height: 4),
              Text(
                tab.label,
                style: AppTextStyles.small.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
