import 'package:flutter/material.dart';

import '../../../../core/format/time_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/missing_thumbnail.dart';
import '../../../../core/widgets/similarity_gauge.dart';
import '../../../missing/data/missing_case.dart';
import '../../data/my_report.dart';

/// 내가 보낸 제보 한 건(F-8.2·F-8.4).
///
/// **"경로에 반영됨"이 이 타일의 핵심이다.** 내가 보낸 사진이 실제로 어딘가에
/// 쓰였다는 것을 본 사람이 다음에도 보낸다. 명세서가 이 값을 "재참여 동기의
/// 핵심 지표"라고 적은 이유다.
class MyReportTile extends StatelessWidget {
  const MyReportTile({required this.report, this.onTap, super.key});

  final MyReport report;

  /// 누르면 그 사건으로. 사건 id를 모르면 null이라 눌리지 않는다.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MissingThumbnail(
              photoPath: report.missingThumbnail,
              width: 46,
              height: 56,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(report.nameLine, style: AppTextStyles.title0),
                  const SizedBox(height: 3),
                  Text(
                    _whenLabel(),
                    style: AppTextStyles.body0.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      // 게이지는 색·숫자·글자 세 가지로 같은 말을 한다. 색
                      // 하나로만 구분하면 색각 이상 사용자가 못 읽는다.
                      SizedBox(
                        width: 96,
                        child: SimilarityGauge(
                          similarity: report.similarity,
                          grade: report.grade,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _PathTag(onPath: report.contributedToPath),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `오늘 오후 5시 12분 제보` · 끝난 사건이면 `· 발견 완료`를 덧붙인다.
  String _whenLabel() {
    final when = '${koreanDateTimeLabel(report.observedAt)} 제보';

    return report.missingStatus == CaseStatus.resolved ? '$when · 발견 완료' : when;
  }
}

/// 내 제보가 경로에 들어갔는지.
///
/// 안 들어간 제보를 "실패"로 적지 않는다. 유사도가 낮아도 저장은 되고, 옷을
/// 갈아입었거나 뒷모습이었을 뿐일 수 있다(설계 결정 3번).
class _PathTag extends StatelessWidget {
  const _PathTag({required this.onPath});

  final bool onPath;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: onPath
            ? AppColors.brandConnectionSurface
            : AppColors.neutralGray,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          onPath ? '경로에 반영됨' : '확인 필요',
          style: AppTextStyles.small.copyWith(
            color: onPath ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
