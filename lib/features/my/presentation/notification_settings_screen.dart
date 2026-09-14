import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/push/notification_settings.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/loading_view.dart';
import 'widgets/notification_always_note.dart';
import 'widgets/notification_night_row.dart';
import 'widgets/notification_radius_chips.dart';
import 'widgets/notification_section.dart';
import 'widgets/notification_target_chips.dart';

/// 알림 설정(F-8.6). 반경 · 대상 · 야간 알림.
///
/// **저장 버튼이 없다.** 누르는 순간 기기에 저장되고, 푸시 등록이 바뀐 값을
/// 보고 서버에 다시 올린다. 저장을 따로 누르게 하면 바꾸고 그냥 나간 사람의
/// 설정이 조용히 사라진다.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider).value;
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return Scaffold(
      appBar: AppTopBar.back('알림 설정', onBack: () => context.pop()),
      body: settings == null
          // 기기에서 읽어 오류가 나지 않는다. 읽는 한순간만 비운다.
          ? const LoadingView()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                NotificationSection(
                  title: '알림 반경',
                  description: '내 위치에서 이 거리 안의 실종 신고만 알려드려요.',
                  child: NotificationRadiusChips(
                    selected: settings.radiusKm,
                    onSelect: (radiusKm) =>
                        unawaited(notifier.setRadius(radiusKm)),
                  ),
                ),
                const SizedBox(height: 28),
                NotificationSection(
                  title: '알림 대상',
                  description: '고른 대상의 실종 신고만 알려드려요. 하나는 켜 두어야 해요.',
                  child: NotificationTargetChips(
                    settings: settings,
                    onToggle: (target, on) =>
                        unawaited(notifier.setTarget(target, on: on)),
                  ),
                ),
                const SizedBox(height: 28),
                NotificationNightRow(
                  on: settings.nightAlerts,
                  onChanged: (on) => unawaited(notifier.setNightAlerts(on: on)),
                ),
                const SizedBox(height: 28),
                const NotificationAlwaysNote(),
              ],
            ),
    );
  }
}
