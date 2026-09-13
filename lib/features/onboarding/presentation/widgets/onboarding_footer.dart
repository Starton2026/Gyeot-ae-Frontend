import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// 온보딩 아래 고정. 진행 점과 버튼.
///
/// PageView 밖에 둔다. 안에 넣으면 세 장이 같은 버튼을 각자 그리면서 넘길
/// 때 버튼까지 같이 밀려간다.
class OnboardingFooter extends StatelessWidget {
  const OnboardingFooter({
    required this.pageCount,
    required this.page,
    required this.onNext,
    required this.onAllowLocation,
    required this.onLater,
    super.key,
  });

  final int pageCount;

  /// 0부터.
  final int page;

  final VoidCallback onNext;
  final VoidCallback onAllowLocation;
  final VoidCallback onLater;

  static const Key nextButtonKey = Key('onboarding_next');
  static const Key allowLocationKey = Key('onboarding_allow_location');
  static const Key laterKey = Key('onboarding_later');

  bool get _isLast => page == pageCount - 1;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 0, 26, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < pageCount; index++)
                _Dot(active: index == page),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLast) ...[
            FilledButton(
              key: allowLocationKey,
              onPressed: onAllowLocation,
              child: const Text('위치 권한 허용하기'),
            ),
            TextButton(
              key: laterKey,
              onPressed: onLater,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              child: const Text('나중에 할게요'),
            ),
          ] else
            FilledButton(
              key: nextButtonKey,
              onPressed: onNext,
              child: const Text('다음'),
            ),
        ],
      ),
    );
  }
}

/// 지금 몇 장째인지. 지난 장은 점, 이번 장은 막대다.
class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: active ? 18 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.border,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
