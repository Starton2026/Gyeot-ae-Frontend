import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/mascot.dart';

/// 평상시 블록(F-1.2). 골든타임 안의 사건이 없을 때 긴급 배너 자리를 대신한다.
///
/// 빈 화면 대신 "계속 찾고 있다"는 상태를 전한다. 조용한 날에도 서비스가
/// 살아 있음을 보여주는 자리라서, 여기는 마스코트가 말해도 되는 몇 안 되는
/// 화면이다(설계 결정 8번).
class QuietStateCard extends StatelessWidget {
  const QuietStateCard({required this.nearbyCount, super.key});

  /// 주변에서 진행 중인 사건 수.
  final int nearbyCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(19, 16, 12, 16),
      decoration: BoxDecoration(
        color: AppColors.brandHope,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('현재 긴급 제보가 없어요', style: AppTextStyles.title0),
                const SizedBox(height: 3),
                Text(
                  _subtitle(nearbyCount),
                  style: AppTextStyles.body0.copyWith(
                    color: AppColors.textCareAccent,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Mascot(MascotPose.find, height: 75),
        ],
      ),
    );
  }
}

String _subtitle(int nearbyCount) {
  if (nearbyCount == 0) return '이음이가 주변을 계속 지켜보고 있어요';

  return '근처 사건 $nearbyCount건은 이음이가 계속 찾고 있어요';
}
