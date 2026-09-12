import 'package:flutter/material.dart';

import '../../../../core/format/elapsed_time.dart';
import '../../../../core/format/time_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/missing_thumbnail.dart';
import '../../../missing/data/missing_case.dart';

/// 긴급 배너(F-1.1). 골든타임 안의 긴급도 1위 사건 하나만 크게 보여준다.
///
/// 화면에서 가장 큰 활자를 경과 시간이 가져간다. 이 서비스가 파는 것이
/// 시간이기 때문이다. CTA는 "제보하기"가 아니라 시민이 하는 일을 시민의 말로
/// 적는다.
///
/// **마스코트를 여기에 두지 않는다**(설계 결정 8번). 경과 시간 옆에서 웃는
/// 얼굴은 보호자에게 상처가 된다.
class UrgentCaseBanner extends StatelessWidget {
  const UrgentCaseBanner({required this.summary, this.onReport, super.key});

  final MissingCaseSummary summary;

  /// 제보창(S4)으로 보낸다. null이면 누를 수 없는 상태로 그린다.
  final VoidCallback? onReport;

  static const Key reportButtonKey = Key('home_urgent_report_button');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 15),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _LiveChip(),
          const SizedBox(height: 13),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MissingThumbnail(
                photoPath: summary.thumbnail,
                width: 74,
                height: 88,
                radius: 15,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${summary.name} · ${summary.ageGenderLabel}',
                      style: AppTextStyles.title0.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _ElapsedTimer(elapsedMinutes: summary.elapsedMinutes),
                    const SizedBox(height: 9),
                    Text(
                      _lastSeenLabel(summary),
                      style: AppTextStyles.body0.copyWith(
                        color: AppColors.white.withValues(alpha: 0.9),
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton(
            key: reportButtonKey,
            onPressed: onReport,
            style: AppTheme.cardButton(
              background: AppColors.white,
              foreground: AppColors.textCareAccent,
            ),
            child: Text(summary.category.witnessCtaLabel),
          ),
        ],
      ),
    );
  }
}

/// "지금 찾고 있어요". 사건이 살아 있다는 표시.
class _LiveChip extends StatelessWidget {
  const _LiveChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '지금 찾고 있어요',
            style: AppTextStyles.badge.copyWith(color: AppColors.white),
          ),
        ],
      ),
    );
  }
}

/// "실종 3시간 12분 경과". 숫자만 크게 키운다.
class _ElapsedTimer extends StatelessWidget {
  const _ElapsedTimer({required this.elapsedMinutes});

  final int elapsedMinutes;

  @override
  Widget build(BuildContext context) {
    final parts = ElapsedTime.fromMinutes(elapsedMinutes).parts;
    final unitStyle = AppTextStyles.subtitle0.copyWith(color: AppColors.white);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '실종 ', style: unitStyle),
          for (final part in parts) ...[
            TextSpan(
              text: '${part.value}',
              style: AppTextStyles.heading2.copyWith(color: AppColors.white),
            ),
            TextSpan(text: '${part.unit} ', style: unitStyle),
          ],
          TextSpan(text: '경과', style: unitStyle),
        ],
      ),
    );
  }
}

/// "인천 남동구 구월동 로데오거리 / 오후 2시 40분 마지막 목격".
String _lastSeenLabel(MissingCaseSummary summary) {
  final time = '${koreanTimeLabel(summary.missingAt)} 마지막 목격';
  final address = summary.lastAddress;

  return address == null || address.isEmpty ? time : '$address\n$time';
}
