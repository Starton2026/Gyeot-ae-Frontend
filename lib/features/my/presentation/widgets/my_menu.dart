import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_icon.dart';

/// MY 아래쪽 메뉴.
///
/// 알림 설정(F-8.6)은 **로그인해야 쓸 수 있다.** 감추지 않고 자물쇠를 달아
/// 둔다. 감추면 로그인하면 뭐가 생기는지 알 수 없고, 그냥 눌리게 두면 눌러도
/// 아무 일이 없다.
///
/// 로그아웃은 반대로 **로그인한 사람에게만 보인다.** 게스트에게 자물쇠 달린
/// 로그아웃은 뜻이 없다. 맨 끝에 두어 다른 메뉴를 누르려다 잘못 누르지 않게 한다.
class MyMenu extends StatelessWidget {
  const MyMenu({
    required this.signedIn,
    this.onNotificationSettings,
    this.onSignOut,
    super.key,
  });

  final bool signedIn;

  /// 알림 설정을 눌렀을 때. 게스트면 자물쇠라 불리지 않는다.
  final VoidCallback? onNotificationSettings;

  /// 로그아웃을 눌렀을 때. 확인은 부르는 쪽이 받는다.
  final VoidCallback? onSignOut;

  static const Key notificationKey = Key('my_menu_notification');
  static const Key signOutKey = Key('my_menu_sign_out');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MenuRow(
          key: notificationKey,
          icon: Icons.notifications_none_rounded,
          label: '알림 설정',
          locked: !signedIn,
          onTap: signedIn ? onNotificationSettings : null,
        ),
        const _MenuRow(icon: Icons.info_outline, label: '곁애 소개'),
        const _MenuRow(icon: Icons.description_outlined, label: '약관 및 개인정보'),
        if (signedIn)
          _MenuRow(
            key: signOutKey,
            icon: Icons.logout_rounded,
            label: '로그아웃',
            onTap: onSignOut,
            muted: true,
          ),
      ],
    );
  }
}

/// 메뉴 한 줄.
///
/// TODO(S8): 곁애 소개·약관 화면이 생기면 누를 수 있게 한다. 지금은 알림
/// 설정과 로그아웃만 눌린다 — 눌러도 아무 일이 없는 것보다 안 눌리는 쪽이 덜
/// 헷갈린다.
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.locked = false,
    this.onTap,
    this.muted = false,
    super.key,
  });

  final IconData icon;
  final String label;

  /// 로그인해야 쓸 수 있는 항목.
  final bool locked;

  final VoidCallback? onTap;

  /// 다른 화면으로 가지 않는 동작(로그아웃). 한 톤 낮추고 꺾쇠를 달지 않는다.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = locked
        ? AppColors.textDisabled
        : muted
        ? AppColors.textSecondary
        : AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.subtitle1.copyWith(color: color),
              ),
            ),
            if (locked)
              const Icon(
                Icons.lock_outline,
                size: 15,
                color: AppColors.textDisabled,
              )
            else if (!muted)
              const AppIcon(
                AppIcons.rightAngleBracket,
                size: 14,
                color: AppColors.textDisabled,
              ),
          ],
        ),
      ),
    );
  }
}
