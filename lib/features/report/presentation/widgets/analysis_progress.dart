import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/mascot.dart';

/// 분석이 도는 동안 보여주는 진행 표시(S4-1).
///
/// **단계는 시간으로 넘긴다. 서버가 알려주는 진행률이 아니다.** 백엔드는
/// 분석이 끝날 때 결과 한 번을 줄 뿐이라 중간 상태를 알 길이 없다. 그래도
/// 단계를 적는 이유는, 몇 초짜리 기다림에서 사용자가 가장 먼저 의심하는 것이
/// "눌리긴 한 건가"이기 때문이다. 무엇을 하고 있는지 적어두면 기다린다.
///
/// 대신 **기다림을 늘리지는 않는다.** 결과가 먼저 오면 단계가 남아 있어도
/// 그대로 결과로 넘어간다.
///
/// **위에서부터 쌓고 남는 자리는 아래에 둔다.** 시트 높이는 결과 기준으로
/// 고정돼 있는데, 그 높이를 억지로 채우려고 내용을 벌리면 블록 사이가 뜬다.
/// 기다리는 화면에서 눈이 가야 할 곳은 맨 위(이음이와 문구)이고, 단계는 그
/// 아래를 따라 읽는다.
///
/// 이음이가 나오는 것은 여기가 **결과가 아니라 기다림**이기 때문이다. 판단이
/// 적히는 결과 화면에는 그대로 등장하지 않는다(설계 결정 8번).
class AnalysisProgress extends StatefulWidget {
  const AnalysisProgress({super.key});

  static const Key stepsKey = Key('analysis_steps');

  @override
  State<AnalysisProgress> createState() => _AnalysisProgressState();
}

class _AnalysisProgressState extends State<AnalysisProgress> {
  /// 다음 단계로 넘어가는 간격.
  ///
  /// 세 단계가 1초 안에 다 지나가도록 잡았다. 더 느리게 두면 짧은 분석에서는
  /// 첫 단계만 보이고 끝나서, 무엇을 하고 있는지 적어둔 의미가 없어진다.
  static const Duration _pace = Duration(milliseconds: 350);

  static const List<String> _steps = ['사진 업로드', '얼굴 특징 분석', '유사도 계산'];

  Timer? _timer;
  int _step = 0;

  @override
  void initState() {
    super.initState();

    // 마지막 단계에서 멈춘다. 계속 돌면 화면이 끝없이 다시 그려진다.
    _timer = Timer.periodic(_pace, (timer) {
      if (_step >= _steps.length - 1) {
        timer.cancel();
        return;
      }

      setState(() => _step += 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 지난 단계는 "완료", 지금 단계는 "중...", 아직 안 온 단계는 이름만.
  String _label(int index) {
    if (index < _step) return '${_steps[index]} 완료';
    if (index == _step) return '${_steps[index]} 중...';

    return _steps[index];
  }

  /// 블록 사이 간격. 셋 다 같은 간격으로 떨어뜨린다.
  static const double _gap = 24;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 화면이 짧은 기기에서는 이음이를 줄인다. 그대로 두면 단계 카드가
        // 접혀 스크롤해야 보인다.
        final compact = constraints.maxHeight < 500;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: _gap),
              Center(child: _SearchingMascot(compact: compact)),
              const SizedBox(height: _gap),
              Text(
                'AI가 사진을 분석하고 있어요',
                textAlign: TextAlign.center,
                style: AppTextStyles.headline0.copyWith(
                  color: AppColors.primary,
                ),
              ),
              // 제목과 한 덩어리라 여기만 붙인다.
              const SizedBox(height: 10),
              Text(
                '잠시만 기다려주세요.',
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle1.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: _gap),
              _Steps(
                key: AnalysisProgress.stepsKey,
                labels: [
                  for (var index = 0; index < _steps.length; index++)
                    _label(index),
                ],
                step: _step,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 옅은 원 안에서 사진을 들여다보는 이음이.
class _SearchingMascot extends StatelessWidget {
  const _SearchingMascot({required this.compact});

  final bool compact;

  static const double _size = 200;
  static const double _compactSize = 150;

  @override
  Widget build(BuildContext context) {
    final size = compact ? _compactSize : _size;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.brandConnectionSurface,
        shape: BoxShape.circle,
      ),
      // 원 안에서 이음이가 차지하는 비율은 그대로 둔다.
      child: Mascot(MascotPose.find, height: size * 0.75),
    );
  }
}

/// 단계 카드. 시트 맨 아래에 붙는다.
class _Steps extends StatelessWidget {
  const _Steps({required this.labels, required this.step, super.key});

  final List<String> labels;

  /// 지금 돌고 있는 단계의 번호.
  final int step;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var index = 0; index < labels.length; index++) {
      // 앞 단계가 끝났어야 그 단계로 들어오는 선에 색이 찬다.
      if (index > 0) rows.add(_Connector(done: index <= step));

      rows.add(
        _Step(
          label: labels[index],
          done: index < step,
          current: index == step,
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows,
        ),
      ),
    );
  }
}

/// 단계와 단계를 잇는 선. 지나온 구간만 색이 찬다.
///
/// 이 서비스가 하는 일이 흩어진 목격을 이어 길을 만드는 것이라, 기다리는
/// 동안 보는 표시도 같은 모양을 쓴다.
class _Connector extends StatelessWidget {
  const _Connector({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: _StepMark._size,
        child: Center(
          child: AnimatedContainer(
            duration: _StepMark._fill,
            curve: Curves.easeOut,
            width: 2,
            height: 26,
            decoration: BoxDecoration(
              color: done ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.done,
    required this.current,
  });

  final String label;
  final bool done;

  /// 지금 돌고 있는 단계.
  final bool current;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepMark(done: done, current: current),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            // 지금 하고 있는 단계만 굵다. 셋 다 같은 무게면 어디까지
            // 왔는지 표시가 마크 하나에만 걸린다.
            style: current
                ? AppTextStyles.subtitle0.copyWith(color: AppColors.textPrimary)
                : AppTextStyles.subtitle1.copyWith(
                    color: done
                        ? AppColors.textSecondary
                        : AppColors.textDisabled,
                  ),
          ),
        ),
      ],
    );
  }
}

class _StepMark extends StatelessWidget {
  const _StepMark({required this.done, required this.current});

  final bool done;
  final bool current;

  static const double _size = 20;

  /// 빈 동그라미가 차오르는 시간. 단계 간격보다 짧아야 한다.
  static const Duration _fill = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _fill,
      curve: Curves.easeOut,
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppColors.primary : null,
        border: done
            ? null
            : Border.all(
                color: current ? AppColors.primary : AppColors.border,
                width: 2,
              ),
      ),
      child: done
          ? const Icon(Icons.check_rounded, size: 13, color: AppColors.white)
          : current
          ? const SizedBox(
              width: 8,
              height: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}
