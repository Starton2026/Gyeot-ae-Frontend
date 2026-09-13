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
  const AppTopBar.brand({super.key}) : title = null, onClose = null;

  /// 실종자·지도·MY. 가운데에 화면 제목을 둔다.
  const AppTopBar.title(String this.title, {super.key}) : onClose = null;

  /// 제보창(S4)·등록 폼(S7). 닫기(X) + 제목.
  ///
  /// 알림 버튼을 두지 않는다. 쓰던 것을 두고 다른 화면으로 새는 길을
  /// 상단바가 열어주면 안 된다.
  const AppTopBar.modal(
    String this.title, {
    required VoidCallback this.onClose,
    super.key,
  });

  final String? title;

  /// 닫기를 눌렀을 때. null이면 탭 상단바다.
  final VoidCallback? onClose;

  static const Key closeButtonKey = Key('app_top_bar_close');

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final label = title;
    final close = onClose;

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
          ? const []
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
/// 화면 낭독기가 `愛`를 중국어로 읽거나 건너뛰기 때문에, 앱 안에서는 한글
/// `곁애`를 쓴다(설계 결정 10번). `곁愛`는 앱 아이콘·스플래시가 맡는다.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

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
        const Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '곁', style: TextStyle(color: AppColors.primary)),
              TextSpan(text: '애', style: TextStyle(color: AppColors.accent)),
            ],
          ),
          style: AppTextStyles.headline0,
        ),
      ],
    );
  }
}
