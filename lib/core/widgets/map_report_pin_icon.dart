import 'package:flutter/material.dart';

import '../../features/report/data/report.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 지도에 찍는 제보 핀(F-5.2.2).
///
/// 번호는 타임라인의 번호와 같은 숫자다. 두 화면을 오갈 때 같은 제보를 찾을 수
/// 있어야 한다. **경로에 들어가지 못한 제보(40% 미만·미검출)는 번호 없이 작은
/// 회색 점**으로 남는다. 지우지 않는다(설계 결정 3번).
///
/// 실종 위치 핀은 물방울 모양이고 제보 핀은 원이다. 모양이 다른 것이 의도다.
/// 하나는 사건이 시작된 자리이고 나머지는 지나간 자리다.
class MapReportPinIcon extends StatelessWidget {
  const MapReportPinIcon({required this.grade, this.routeIndex, super.key});

  final SimilarityGrade grade;

  /// 경로 위의 순번. null이면 번호를 찍지 않는다.
  final int? routeIndex;

  /// 번호가 붙는 핀의 그림 크기.
  static const Size numberedSize = Size(34, 34);

  /// 번호가 없는 핀의 그림 크기.
  static const Size dotSize = Size(22, 22);

  static Size sizeOf(SimilarityGrade grade) =>
      grade.countsTowardPath ? numberedSize : dotSize;

  @override
  Widget build(BuildContext context) {
    final size = sizeOf(grade);
    final numbered = routeIndex != null;

    return Opacity(
      // 확인이 필요한 제보는 한 겹 가라앉힌다.
      opacity: grade.countsTowardPath ? 1 : 0.78,
      child: Container(
        width: size.width,
        height: size.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _color,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: 2.6),
        ),
        child: numbered
            ? Text(
                '$routeIndex',
                // `decoration`을 반드시 꺼야 한다. 이 위젯은 화면이 아니라
                // `KImage.fromWidget`의 고립된 트리에서 그려지는데, 거기에는
                // Material이 없어서 Flutter가 스타일 없는 글자로 보고 노란
                // 이중 밑줄(디버그 표시)을 그어버린다.
                style: AppTextStyles.subtitle0.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
                ),
              )
            : null,
      ),
    );
  }

  Color get _color => switch (grade) {
    SimilarityGrade.high => AppColors.gradeHigh,
    SimilarityGrade.medium => AppColors.gradeMedium,
    SimilarityGrade.low || SimilarityGrade.noFace => AppColors.gradeLow,
  };
}
