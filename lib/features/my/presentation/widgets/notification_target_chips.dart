import 'package:flutter/material.dart';

import '../../../../core/push/notification_settings.dart';
import '../../../../core/widgets/app_choice_chip.dart';

/// 알림 대상 칩(F-8.6). 아동 · 어르신을 따로 켜고 끈다.
///
/// 둘 다 켜 두면 '그 외' 구분의 사건까지 모두 받는다. 마지막 하나를 끄는 것은
/// 막는데, 막는 규칙은 설정 쪽([NotificationSettingsNotifier.setTarget])에
/// 있다. 여기는 누른 것을 그대로 전한다.
class NotificationTargetChips extends StatelessWidget {
  const NotificationTargetChips({
    required this.settings,
    required this.onToggle,
    super.key,
  });

  final NotificationSettings settings;

  /// 누른 대상과, 누른 뒤 켜져 있어야 하는지.
  final void Function(AlertTarget target, bool on) onToggle;

  static Key chipKey(AlertTarget target) =>
      Key('notification_target_${target.name}');

  static String _label(AlertTarget target) => switch (target) {
    AlertTarget.child => '아동',
    AlertTarget.elderly => '어르신',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      children: [
        for (final target in AlertTarget.values)
          AppChoiceChip(
            key: chipKey(target),
            label: _label(target),
            selected: settings.isOn(target),
            onTap: () => onToggle(target, !settings.isOn(target)),
          ),
      ],
    );
  }
}
