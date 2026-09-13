import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_icon.dart';

/// MY 아래쪽 메뉴.
///
/// 알림 설정(F-8.6)은 **로그인해야 쓸 수 있다.** 감추지 않고 자물쇠를 달아
/// 둔다. 감추면 로그인하면 뭐가 생기는지 알 수 없고, 그냥 눌리게 두면 눌러도
/// 아무 일이 없다.
class MyMenu extends StatelessWidget {
  const MyMenu({required this.signedIn, super.key});

  final bool signedIn;

  static const Key notificationKey = Key('my_menu_notification');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MenuRow(
          key: notificationKey,
          icon: Icons.notifications_none_rounded,
          label: '알림 설정',
          // TODO(S8): 알림 설정 화면(반경·대상·야간 수신)이 생기면 연결한다.
          locked: !signedIn,
        ),
        const _MenuRow(icon: Icons.info_outline, label: '곁애 소개'),
        const _MenuRow(icon: Icons.description_outlined, label: '약관 및 개인정보'),
      ],
    );
  }
}

/// 메뉴 한 줄.
///
/// TODO(S8): 알림 설정·곁애 소개·약관 화면이 생기면 누를 수 있게 한다. 지금은
/// 어떤 줄도 눌리지 않는다 — 눌러도 아무 일이 없는 것보다 안 눌리는 쪽이
/// 덜 헷갈린다.
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.locked = false,
    super.key,
  });

  final IconData icon;
  final String label;

  /// 로그인해야 쓸 수 있는 항목.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final color = locked ? AppColors.textDisabled : AppColors.textPrimary;

    return Padding(
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
          else
            const AppIcon(
              AppIcons.rightAngleBracket,
              size: 14,
              color: AppColors.textDisabled,
            ),
        ],
      ),
    );
  }
}
