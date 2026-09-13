import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/similarity_gauge.dart';
import '../../data/analysis.dart';
import '../../data/report.dart';
import 'dashed_box.dart';
import 'report_field_label.dart';

/// 사진 분석 자리(F-4.5).
///
/// 분석 전에는 비어 있는 것이 보여야 한다. 버튼만 두면 눌러야 하는 줄 모르고
/// 제보 버튼이 왜 회색인지 알 수 없다(F-4.6).
///
/// 분석을 마치면 결과가 여기에 남는다. S4-1 바텀시트를 닫아도 "첨부 완료"
/// 상태가 화면에 보이는 자리다(F-4.1.7).
class ReportAnalysisSlot extends StatelessWidget {
  const ReportAnalysisSlot({
    required this.analysis,
    required this.hasPhoto,
    required this.onAnalyze,
    super.key,
  });

  /// 값이 null이면 아직 분석 전이다.
  final AsyncValue<AnalysisResult?> analysis;

  final bool hasPhoto;
  final VoidCallback onAnalyze;

  static const Key analyzeButtonKey = Key('report_analyze_button');

  @override
  Widget build(BuildContext context) {
    final result = analysis.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ReportFieldLabel('AI 분석 결과', required: true),
        const SizedBox(height: 8),
        if (result != null)
          _Done(result: result, onRetry: onAnalyze)
        else
          DashedBox(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: analysis.isLoading
                  ? const _Analyzing()
                  : _Idle(
                      error: analysis.error,
                      hasPhoto: hasPhoto,
                      onAnalyze: onAnalyze,
                    ),
            ),
          ),
      ],
    );
  }
}

/// 아직 분석하지 않았다. 실패한 직후도 여기로 온다.
class _Idle extends StatelessWidget {
  const _Idle({
    required this.error,
    required this.hasPhoto,
    required this.onAnalyze,
  });

  final Object? error;
  final bool hasPhoto;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    final failure = error;

    return Column(
      children: [
        Text(
          switch (failure) {
            null => '사진을 분석하면 등록 사진과의 유사도가\n여기에 담깁니다',
            ApiException() => failure.message,
            _ => '분석하지 못했어요. 잠시 후 다시 시도해 주세요.',
          },
          textAlign: TextAlign.center,
          style: AppTextStyles.body0.copyWith(
            color: failure == null
                ? AppColors.textSecondary
                : AppColors.error,
          ),
        ),
        const SizedBox(height: 11),
        FilledButton.icon(
          key: ReportAnalysisSlot.analyzeButtonKey,
          // 사진이 없으면 분석할 것이 없다. 숨기지 않고 회색으로 둔다.
          onPressed: hasPhoto ? onAnalyze : null,
          style: AppTheme.cardButton(
            background: hasPhoto
                ? AppColors.primary
                : AppColors.primaryDisabled,
            foreground: AppColors.white,
          ),
          icon: const Icon(Icons.search_rounded, size: 18),
          label: Text(failure == null ? '사진 분석하기' : '다시 분석하기'),
        ),
      ],
    );
  }
}

class _Analyzing extends StatelessWidget {
  const _Analyzing();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
        const SizedBox(height: 12),
        Text(
          '등록된 사진과 얼굴을 맞춰보는 중이에요',
          style: AppTextStyles.body0.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

/// 분석을 마쳤다. 숫자와 등급이 제보창에 남는다.
class _Done extends StatelessWidget {
  const _Done({required this.result, required this.onRetry});

  final AnalysisResult result;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        // 아래가 8인 것은 버튼이 제 여백을 6 갖고 있어서다. 합쳐서 14,
        // 좌우와 같아진다.
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SimilarityGauge(
              similarity: result.similarity,
              grade: result.grade,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    result.grade.analysisHeadline,
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  key: ReportAnalysisSlot.analyzeButtonKey,
                  onPressed: onRetry,
                  // 기본 버튼은 글자가 17인데도 터치 영역 48을 잡는다. 그
                  // 차이가 카드 아래에 빈 공간으로 남는다.
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('다시 분석'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
