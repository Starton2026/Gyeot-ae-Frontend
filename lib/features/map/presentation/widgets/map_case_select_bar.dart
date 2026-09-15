import 'package:flutter/material.dart';

import '../../../../core/format/elapsed_time.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/missing_thumbnail.dart';
import '../../../missing/data/missing_case.dart';

/// 사건 선택 모드의 상단 바(F-5.2.1).
///
/// 지금 어느 사건의 경로를 보고 있는지 알린다. 누르면 전체 보기로 돌아가
/// 다른 사건을 고를 수 있다. 지도 위에서 사건 목록을 다시 띄우는 대신,
/// 이미 있는 카드 캐러셀을 사건 고르는 자리로 쓴다.
class MapCaseSelectBar extends StatelessWidget {
  const MapCaseSelectBar({
    required this.summary,
    required this.onTap,
    super.key,
  });

  final MissingCaseSummary summary;

  /// 전체 보기로 돌아간다.
  final VoidCallback onTap;

  static const Key barKey = Key('map_case_select_bar');

  @override
  Widget build(BuildContext context) {
    final resolved = summary.status == CaseStatus.resolved;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: AppColors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: barKey,
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
            child: Row(
              children: [
                MissingThumbnail(
                  photoPath: summary.thumbnail,
                  width: 32,
                  height: 38,
                  radius: 8,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${summary.name} · ${summary.age}세',
                    style: AppTextStyles.subtitle0.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (!resolved)
                  Text(
                    ElapsedTime.fromMinutes(summary.elapsedMinutes).label,
                    style: AppTextStyles.badge.copyWith(
                      color: AppColors.textCareAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: AppColors.textDisabled,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
