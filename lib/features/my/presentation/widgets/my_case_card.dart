import 'package:flutter/material.dart';

import '../../../../core/format/time_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/elapsed_badge.dart';
import '../../../../core/widgets/missing_thumbnail.dart';
import '../../../missing/data/missing_case.dart';

/// 내가 등록한 사건 한 건(F-8.3).
///
/// 진행 중이면 경과 시간과 [발견 완료] 버튼을, 끝난 사건이면 언제 찾았는지를
/// 적는다. **끝난 사건도 지우지 않고 흐리게 남긴다**(설계 결정 7번). 남아야
/// 이 서비스가 실제로 작동했다는 증거가 쌓인다.
class MyCaseCard extends StatelessWidget {
  const MyCaseCard({
    required this.summary,
    this.onResolve,
    this.onTap,
    super.key,
  });

  final MissingCaseSummary summary;

  /// 발견 완료로 바꾼다. 진행 중일 때만 준다.
  final VoidCallback? onResolve;

  final VoidCallback? onTap;

  static const Key resolveButtonKey = Key('my_case_resolve');

  bool get _resolved => summary.status == CaseStatus.resolved;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      // 끝난 사건은 투명도만 낮춘다. 목록에서 빼지 않는다.
      opacity: _resolved ? 0.72 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MissingThumbnail(
                photoPath: summary.thumbnail,
                width: 52,
                height: 62,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            summary.name,
                            style: AppTextStyles.title0,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          summary.ageGenderLabel,
                          style: AppTextStyles.body0.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (_resolved)
                      const _FoundTag()
                    else
                      ElapsedBadge(
                        elapsedMinutes: summary.elapsedMinutes,
                        compact: true,
                      ),
                    const SizedBox(height: 7),
                    Text(
                      _subtitle(),
                      style: AppTextStyles.body0.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_resolved && onResolve != null) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  key: resolveButtonKey,
                  onPressed: onResolve,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: AppTextStyles.body1,
                  ),
                  child: const Text('발견 완료'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 진행 중이면 제보가 몇 건인지, 끝났으면 언제 몇 건으로 찾았는지.
  String _subtitle() {
    final reports = '제보 ${summary.reportCount}건';
    final resolvedAt = summary.resolvedAt;

    if (!_resolved) return reports;
    if (resolvedAt == null) return '$reports으로 발견';

    return '${koreanDateLabel(resolvedAt)} · $reports으로 발견';
  }
}

class _FoundTag extends StatelessWidget {
  const _FoundTag();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.neutralGray,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          '발견',
          style: AppTextStyles.badge.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
