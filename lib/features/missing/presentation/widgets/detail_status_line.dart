import 'package:flutter/material.dart';

import '../../../../core/format/elapsed_time.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/missing_case.dart';

/// 상태 필 + 경과 시간(F-3.2).
///
/// 사진 바로 아래에 붙여서 스크롤하지 않아도 긴급도가 읽히게 한다. 경과 시간은
/// 서버가 계산해 내려준 값이다(설계 결정 6번).
class DetailStatusLine extends StatelessWidget {
  const DetailStatusLine({
    required this.status,
    required this.elapsedMinutes,
    super.key,
  });

  final CaseStatus status;
  final int elapsedMinutes;

  @override
  Widget build(BuildContext context) {
    final resolved = status == CaseStatus.resolved;

    return Row(
      children: [
        if (resolved)
          const _Pill(
            label: '발견완료',
            background: AppColors.backgroundSubtle,
            foreground: AppColors.textSecondary,
          )
        else ...[
          const _Pill(
            label: '찾는 중',
            background: AppColors.accent,
            foreground: AppColors.white,
            live: true,
          ),
          const SizedBox(width: 8),
          Text(
            '${ElapsedTime.fromMinutes(elapsedMinutes).label} 경과',
            style: AppTextStyles.badge.copyWith(
              color: AppColors.textCareAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
    this.live = false,
  });

  final String label;
  final Color background;
  final Color foreground;

  /// 사건이 아직 살아 있다는 표시로 점을 깜빡인다.
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(live ? 8 : 10, 5, 10, 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (live) ...[
            _LiveDot(color: foreground),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTextStyles.badge.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// 천천히 깜빡이는 점.
///
/// 화면에서 움직임을 줄이도록 설정한 기기에서는 깜빡이지 않는다.
class _LiveDot extends StatefulWidget {
  const _LiveDot({required this.color});

  final Color color;

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = DecoratedBox(
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      child: const SizedBox(width: 6, height: 6),
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.32).animate(_controller),
      child: dot,
    );
  }
}
