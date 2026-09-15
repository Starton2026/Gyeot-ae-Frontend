import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 야간 알림 켜기·끄기(F-8.6).
///
/// 시간을 고르게 하지 않는다. 끄면 밤 11시부터 아침 7시까지 주변 실종 신고를
/// 받지 않는다 — 조작이 하나라 헷갈릴 일이 없다.
class NotificationNightRow extends StatelessWidget {
  const NotificationNightRow({
    required this.on,
    required this.onChanged,
    super.key,
  });

  final bool on;
  final ValueChanged<bool> onChanged;

  static const Key switchKey = Key('notification_night_switch');

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('야간 알림', style: AppTextStyles.title0),
              const SizedBox(height: 4),
              Text(
                // 켜고 끈 결과를 문장으로 적는다. 스위치만으로는 켜진 쪽이
                // "받는다"인지 "막는다"인지 알 수 없다.
                on ? '밤 11시~아침 7시에도 받아요' : '밤 11시~아침 7시에는 받지 않아요',
                style: AppTextStyles.body0.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(key: switchKey, value: on, onChanged: onChanged),
      ],
    );
  }
}
