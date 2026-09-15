import 'package:flutter/material.dart';

import '../../../../core/push/notification_settings.dart';
import '../../../../core/widgets/app_choice_chip.dart';

/// 알림 반경 칩(F-8.6). 1 · 3 · 5 · 10km 가운데 하나.
class NotificationRadiusChips extends StatelessWidget {
  const NotificationRadiusChips({
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final int selected;
  final ValueChanged<int> onSelect;

  static Key chipKey(int radiusKm) => Key('notification_radius_$radiusKm');

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      children: [
        for (final radiusKm in NotificationSettings.radiusChoices)
          AppChoiceChip(
            key: chipKey(radiusKm),
            label: '${radiusKm}km',
            selected: radiusKm == selected,
            onTap: () => onSelect(radiusKm),
          ),
      ],
    );
  }
}
