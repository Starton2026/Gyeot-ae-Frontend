import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_icon.dart';

/// 상단바(기능정의서 5.5).
///
/// 홈은 가운데에 로고를 두고([AppTopBar.brand]), 실종자·지도·MY는 화면 제목을
/// 둔다([AppTopBar.title]). 오른쪽 알림 버튼은 네 탭이 함께 쓴다.
///
/// 제보창·등록 폼은 탭이 아니라 한 번 쓰고 닫는 화면이라 닫기(X)를 왼쪽에
/// 두고 알림을 빼낸다([AppTopBar.modal]).
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// 홈 전용. 가운데에 워드마크를 둔다.
  const AppTopBar.brand({super.key})
    : title = null,
      onClose = null,
      action = null;

  /// 실종자·지도·MY. 가운데에 화면 제목을 둔다.
  const AppTopBar.title(String this.title, {super.key})
    : onClose = null,
      action = null;

  /// 제보창(S4)·등록 폼(S7). 닫기(X) + 제목.
  ///
  /// 알림 버튼을 두지 않는다. 쓰던 것을 두고 다른 화면으로 새는 길을
  /// 상단바가 열어주면 안 된다. 오른쪽에는 그 화면 안에서 끝나는 일만 둔다
  /// (등록 폼의 임시저장).
  const AppTopBar.modal(
    String this.title, {
    required VoidCallback this.onClose,
    this.action,
    super.key,
  });

  final String? title;

  /// 닫기를 눌렀을 때. null이면 탭 상단바다.
  final VoidCallback? onClose;

  /// 모달 상단바 오른쪽에 두는 것. 없으면 비운다.
  final Widget? action;

  static const Key closeButtonKey = Key('app_top_bar_close');

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final label = title;
    final close = onClose;
    final trailing = action;

    return AppBar(
      title: label == null ? const _Wordmark() : Text(label),
      leading: close == null
          ? null
          : IconButton(
              key: closeButtonKey,
              onPressed: close,
              icon: const Icon(Icons.close_rounded, size: 24),
              color: AppColors.textSecondary,
              tooltip: '닫기',
            ),
      actions: close != null
          ? [
              ?trailing,
              if (trailing != null) const SizedBox(width: 6),
            ]
          : [
              const IconButton(
                // TODO(알림): 알림 화면이 생기면 연결한다.
                onPressed: null,
                icon: AppIcon(
                  AppIcons.bell,
                  size: 22,
                  color: AppColors.textSecondary,
                ),
                tooltip: '알림',
              ),
              const SizedBox(width: 4),
            ],
    );
  }
}

/// 마크 + 워드마크.
///
/// 로고 자리라 `곁愛`를 쓴다(설계 결정 10번). 같은 규칙이 본문·푸시·15px
/// 이하에는 `곁애`를 쓰라고 하는데, 이유가 화면 낭독기가 `愛`를 중국어로
/// 읽거나 건너뛰기 때문이다. 그래서 낭독기에는 [Semantics]로 `곁애`를 준다.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  static final TextStyle _hanja = AppTextStyles.hanja.copyWith(
    color: AppColors.accent,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo_icon.png',
          height: 22,
          excludeFromSemantics: true,
        ),
        const SizedBox(width: 7),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: '곁',
                style: TextStyle(color: AppColors.primary),
              ),
              // Pretendard에 없는 글자라 전용 글꼴을 물린다.
              TextSpan(text: '愛', style: _hanja),
            ],
          ),
          semanticsLabel: '곁애',
          style: AppTextStyles.headline0,
        ),
      ],
    );
  }
}
