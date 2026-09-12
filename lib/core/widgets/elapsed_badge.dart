import 'package:flutter/material.dart';

import '../format/elapsed_time.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 실종 후 경과 시간 뱃지. S1 주변 목록 · S2 목록 · S3 상세가 같은 모양을 쓴다.
///
/// 색은 긴급도의 골든타임 구간(기능정의서 5.1)을 그대로 따른다.
/// 3시간 안이면 관심색으로 가득 채우고, 12시간까지는 배려색, 그 뒤로는
/// 균형색으로 가라앉힌다. **오래된 사건이라고 숨기지는 않는다**(설계 결정 7번).
class ElapsedBadge extends StatelessWidget {
  const ElapsedBadge({required this.elapsedMinutes, super.key});

  /// 서버가 계산해준 경과 분(설계 결정 6번).
  final int elapsedMinutes;

  @override
  Widget build(BuildContext context) {
    final tier = _Tier.of(elapsedMinutes);
    final label = ElapsedTime.fromMinutes(elapsedMinutes).shortLabel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tier.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label 경과',
        style: AppTextStyles.badge.copyWith(color: tier.foreground),
      ),
    );
  }
}

/// 경과 시간 구간. 골든타임 3시간, 그다음 12시간이 경계다.
enum _Tier {
  golden(AppColors.accent, AppColors.white),
  half(AppColors.brandHope, AppColors.textCareAccent),
  long(AppColors.brandReliability, AppColors.textSecondary);

  const _Tier(this.background, this.foreground);

  final Color background;
  final Color foreground;

  static _Tier of(int minutes) {
    if (minutes < 180) return _Tier.golden;
    if (minutes < 720) return _Tier.half;
    return _Tier.long;
  }
}
