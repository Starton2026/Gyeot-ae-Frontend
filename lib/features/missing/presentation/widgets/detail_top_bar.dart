import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_icon.dart';

/// 상세 화면의 떠 있는 상단바(F-3.6).
///
/// 두 전환을 **따로** 움직인다. 사진이 상단바 밑으로 다 올라오면 배경이 흰색으로
/// 차오르고, 본문의 이름이 가려지는 순간에야 상단바가 그 이름을 이어받는다.
/// 한꺼번에 바꾸면 이름이 본문과 상단바에 동시에 보이는 구간이 생긴다.
///
/// 진행도를 0~1로 이어 받아 그리기 때문에 경계에서 깜빡이지 않는다. 켜고 끄는
/// 방식이었다면 히스테리시스를 둬야 했을 자리다.
class DetailTopBar extends StatelessWidget {
  const DetailTopBar({
    required this.backgroundProgress,
    required this.titleProgress,
    required this.title,
    required this.onLeading,
    this.elapsedLabel,
    this.onShare,
    this.isExternalEntry = false,
    super.key,
  });

  /// 0이면 사진 위에 투명하게 떠 있고, 1이면 흰 상단바다.
  final double backgroundProgress;

  /// 0이면 제목이 없고, 1이면 이름과 경과 시간이 다 보인다.
  final double titleProgress;

  /// 상단바가 이어받는 이름. `김하준 · 7세`.
  final String title;

  /// `3시간 12분`. 끝난 사건이면 null.
  final String? elapsedLabel;

  /// 뒤로(또는 홈으로).
  final VoidCallback onLeading;

  final VoidCallback? onShare;

  /// 공유 링크로 들어와 돌아갈 스택이 없다. 이때만 브랜드를 노출한다(5.5).
  final bool isExternalEntry;

  static const double height = kToolbarHeight;

  static const Key leadingButtonKey = Key('detail_top_bar_leading');

  @override
  Widget build(BuildContext context) {
    final background = backgroundProgress.clamp(0.0, 1.0);
    final titleOpacity = titleProgress.clamp(0.0, 1.0);

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 사진 위에 얹는 어두운 그라데이션. 사진이 밝아도 버튼이 읽힌다.
          IgnorePointer(
            child: Opacity(
              opacity: 1 - background,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x4D17273D), Color(0x0017273D)],
                  ),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: background),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border.withValues(alpha: background),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _RoundButton(
                  key: leadingButtonKey,
                  circleOpacity: 1 - background,
                  onTap: onLeading,
                  semanticsLabel: isExternalEntry ? '홈으로' : '뒤로',
                  child: isExternalEntry
                      ? Image.asset(
                          'assets/images/logo_icon.png',
                          height: 17,
                          excludeFromSemantics: true,
                        )
                      : const AppIcon(
                          AppIcons.leftArrow,
                          size: 17,
                          color: AppColors.textPrimary,
                        ),
                ),
                Expanded(
                  child: Opacity(
                    opacity: titleOpacity,
                    child: Transform.translate(
                      offset: Offset(0, 7 * (1 - titleOpacity)),
                      child: _Title(title: title, elapsedLabel: elapsedLabel),
                    ),
                  ),
                ),
                _RoundButton(
                  circleOpacity: 1 - background,
                  onTap: onShare,
                  semanticsLabel: '공유',
                  child: const AppIcon(
                    AppIcons.share,
                    size: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.title, this.elapsedLabel});

  final String title;
  final String? elapsedLabel;

  @override
  Widget build(BuildContext context) {
    final elapsed = elapsedLabel;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            title,
            style: AppTextStyles.title0,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (elapsed != null) ...[
          const SizedBox(width: 7),
          Text(
            elapsed,
            style: AppTextStyles.badge.copyWith(
              color: AppColors.textCareAccent,
            ),
          ),
        ],
      ],
    );
  }
}

/// 사진 위에서는 흰 원 안에, 흰 상단바에서는 원 없이 놓이는 아이콘 버튼.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.circleOpacity,
    required this.child,
    required this.semanticsLabel,
    this.onTap,
    super.key,
  });

  final double circleOpacity;
  final Widget child;
  final String semanticsLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.white.withValues(
              alpha: 0.94 * circleOpacity.clamp(0.0, 1.0),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
