import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/time_label.dart';
import '../../../../core/location/current_location.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/similarity_arc_gauge.dart';
import '../../../missing/data/missing_repository.dart';
import '../../data/analysis.dart';
import '../report_draft_providers.dart';
import 'analysis_compare_row.dart';

/// "분석 확인". 누르면 제보창으로 돌아간다(F-4.1.7).
const Key analysisConfirmKey = Key('analysis_confirm');

/// 분석이 실패했을 때의 "다시 분석하기".
const Key analysisRetryKey = Key('analysis_retry');

/// AI 분석 결과(S4-1).
///
/// **별도 화면이 아니라 바텀시트인 이유**는 제보창 입력값이 살아 있는 채로
/// 겹쳐 뜨기 때문이다. 화면 전환 비용이 0이다.
///
/// **이 화면의 목적은 필터링이 아니라 심리적 면죄부다.** 목격자가 망설이는
/// 가장 큰 이유는 "틀렸을까 봐"이고, 그 부담을 AI가 대신 진다. 낮은 점수일
/// 때의 안내 문구가 이 화면의 핵심이다(F-4.1.5).
Future<void> showAnalysisSheet(
  BuildContext context, {
  required String caseId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    // 시안의 짙은 남색 막. 검정으로 덮으면 뒤의 제보창이 죽어 보인다.
    barrierColor: AppColors.textPrimary.withValues(alpha: 0.45),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (context) => _AnalysisSheet(caseId: caseId),
  );
}

class _AnalysisSheet extends ConsumerWidget {
  const _AnalysisSheet({required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(reportDraftProvider(caseId));
    final analysis = draft.analysis;
    final result = analysis.value;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Handle(),
              const Text(
                '분석 결과',
                textAlign: TextAlign.center,
                style: AppTextStyles.title0,
              ),
              if (result != null)
                _Result(caseId: caseId, draft: draft, result: result)
              else if (analysis.isLoading)
                const _Analyzing()
              else
                _Failed(
                  error: analysis.error,
                  onRetry: () => ref
                      .read(reportDraftProvider(caseId).notifier)
                      .analyze(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 38,
        height: 4,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

/// 분석이 도는 동안. 시트를 먼저 열어두면 기다리는 몇 초가 화면에 보인다.
class _Analyzing extends StatelessWidget {
  const _Analyzing();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 52),
      child: Column(
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
          const SizedBox(height: 16),
          Text(
            '등록된 사진과 얼굴을 맞춰보는 중이에요',
            style: AppTextStyles.subtitle1.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 분석 자체가 실패했다. 얼굴 미검출과 다르다 — 그쪽은 정상 결과다.
class _Failed extends StatelessWidget {
  const _Failed({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failure = error;

    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            failure is ApiException
                ? failure.message
                : '분석하지 못했어요. 잠시 후 다시 시도해 주세요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle1.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: analysisRetryKey,
            onPressed: onRetry,
            child: const Text('다시 분석하기'),
          ),
        ],
      ),
    );
  }
}

/// 유사도 → 대조 사진 → 위치·시간 → 안내 문구 → 확인.
class _Result extends StatelessWidget {
  const _Result({
    required this.caseId,
    required this.draft,
    required this.result,
  });

  final String caseId;
  final ReportDraft draft;
  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final location = ref.watch(currentLocationProvider);
        final detail = ref.watch(missingDetailProvider(caseId)).value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 14),
            Center(
              child: SimilarityArcGauge(
                similarity: result.similarity,
                grade: result.grade,
              ),
            ),
            const SizedBox(height: 16),
            AnalysisCompareRow(
              // 얼굴을 못 찾았으면 대조한 사진이 없다. 대표 사진을 대신
              // 보여준다. 눈으로 맞춰보는 것은 여전히 할 수 있다.
              registeredPhoto:
                  result.matchedPhotoUrl ?? detail?.photos.firstOrNull,
              capturedPath: draft.photoPath,
            ),
            const SizedBox(height: 16),
            _FactCard(
              // 제보창에 적힌 것과 같은 말이어야 한다. 여기서 마지막으로
              // 확인하는 값이 실제로 나갈 값이다(F-4.1.4).
              address: draft.locationName(location.label),
              placeName: draft.placeName,
              observedAt: draft.observedAt,
            ),
            const SizedBox(height: 13),
            _Reassurance(faceFound: result.faceFound),
            const SizedBox(height: 14),
            FilledButton(
              key: analysisConfirmKey,
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('분석 확인'),
            ),
          ],
        );
      },
    );
  }
}

/// 위치·시간 재확인(F-4.1.4). 보내기 전 마지막으로 눈에 걸리는 자리다.
class _FactCard extends StatelessWidget {
  const _FactCard({
    required this.address,
    required this.placeName,
    required this.observedAt,
  });

  final String address;
  final String placeName;
  final DateTime observedAt;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FactRow(
              label: '위치',
              value: placeName.isEmpty ? address : '$address\n$placeName',
            ),
            const SizedBox(height: 8),
            _FactRow(label: '시간', value: koreanDateTimeLabel(observedAt)),
          ],
        ),
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: AppTextStyles.subtitle0.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.subtitle1.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// 안내 문구(F-4.1.5·F-4.1.6). **이 시트에서 가장 중요한 블록이다.**
///
/// 낮은 점수를 본 목격자가 "역시 아닌가 보다" 하고 닫아버리면 경로에 구멍이
/// 생긴다. 판단은 보호자가 한다고 못 박아서 그 부담을 덜어준다.
class _Reassurance extends StatelessWidget {
  const _Reassurance({required this.faceFound});

  final bool faceFound;

  @override
  Widget build(BuildContext context) {
    final base = AppTextStyles.body0.copyWith(
      color: AppColors.textCareAccent,
      height: 1.55,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandHope,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
        child: Text.rich(
          TextSpan(
            text: faceFound
                ? '옷을 갈아입었거나 각도가 달라 낮게 나올 수 있습니다. '
                : '사진에서 얼굴을 찾지 못했습니다. 뒷모습이나 먼 거리도 그렇습니다. ',
            children: [
              TextSpan(
                text: faceFound
                    ? '확신이 없어도 제보해 주세요. 확인은 보호자가 합니다.'
                    : '위치와 시간만으로도 경로를 잇는 데 도움이 됩니다. 그대로 제보해 주세요.',
                style: base.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          style: base,
        ),
      ),
    );
  }
}
