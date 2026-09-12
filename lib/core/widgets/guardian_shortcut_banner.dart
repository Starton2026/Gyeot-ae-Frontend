import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_icon.dart';

/// 보호자 바로가기 띠(F-1.5). 홈과 실종자 목록이 상단바 바로 아래에 고정한다.
///
/// 실종자 등록은 하단 네비게이션에 넣지 않는다. 평생 한 번도 누르지 않는 것이
/// 최선인 기능이 4칸 중 하나를 차지할 이유가 없다. 대신 급한 보호자를 위해
/// 이 띠를 위에 두고, 평소 사용자가 기능을 알게 되는 자리는 화면 맨 아래에 둔다.
///
/// 배려색 배경이라 스크롤 없이 보이면서도 긴급 배너를 누르지 않는다.
class GuardianShortcutBanner extends StatelessWidget {
  const GuardianShortcutBanner({this.onTap, super.key});

  /// null이면 누를 수 없는 상태로 그린다.
  final VoidCallback? onTap;

  static const Key registerShortcutKey = Key('home_guardian_shortcut');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Material(
        color: AppColors.brandHope,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: registerShortcutKey,
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 44,
            padding: const EdgeInsets.fromLTRB(14, 0, 13, 0),
            child: Row(
              children: [
                const AppIcon(
                  AppIcons.locationMarker,
                  size: 16,
                  color: AppColors.textCareAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '실종자를 찾고 계신가요?',
                    style: AppTextStyles.subtitle0.copyWith(
                      color: AppColors.textCareAccent,
                    ),
                  ),
                ),
                Text(
                  '등록',
                  style: AppTextStyles.badge.copyWith(
                    color: AppColors.textCareAccent,
                  ),
                ),
                const SizedBox(width: 2),
                const AppIcon(
                  AppIcons.rightAngleBracket,
                  size: 12,
                  color: AppColors.textCareAccent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
