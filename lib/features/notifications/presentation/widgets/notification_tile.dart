import 'package:flutter/material.dart';

import '../../../../core/format/time_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/missing_thumbnail.dart';
import '../../data/app_notification.dart';

/// 알림함 한 줄. 누르면 그 사건으로 간다.
///
/// 새 알림은 바탕을 옅게 칠하고 점을 찍는다. 색 하나로만 가르지 않는다 —
/// 점이 있어야 색각 이상 사용자도 무엇이 새것인지 안다.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    required this.notification,
    required this.fresh,
    required this.onTap,
    this.now,
    super.key,
  });

  final AppNotification notification;

  /// 새로 온 알림으로 강조할지. 알림함을 열 때 안 읽었던 것이다.
  final bool fresh;

  final VoidCallback onTap;

  /// 테스트에서만 넘긴다.
  final DateTime? now;

  static Key tileKey(String id) => Key('notification_tile_$id');

  static const Key unreadDotKey = Key('notification_unread_dot');

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fresh ? AppColors.brandConnectionSurface : AppColors.background,
      child: InkWell(
        key: tileKey(notification.id),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MissingThumbnail(
                photoPath: notification.missingThumbnail,
                width: 44,
                height: 52,
                radius: 10,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _KindLine(
                      kind: notification.kind,
                      when: koreanAgoLabel(notification.createdAt, now: now),
                    ),
                    const SizedBox(height: 4),
                    Text(notification.title, style: AppTextStyles.title0),
                    const SizedBox(height: 3),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body0.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 16,
                child: fresh
                    ? const Padding(
                        padding: EdgeInsets.only(top: 6, left: 8),
                        child: DecoratedBox(
                          key: unreadDotKey,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox.square(dimension: 7),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `주변 실종 신고 · 12분 전`.
class _KindLine extends StatelessWidget {
  const _KindLine({required this.kind, required this.when});

  final NotificationKind kind;
  final String when;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (kind) {
      // 동네 실종 신고는 급한 소식이다. 따뜻한 강조색으로 먼저 눈에 걸리게 한다.
      NotificationKind.missing => ('주변 실종 신고', AppColors.textCareAccent),
      NotificationKind.report => ('내 사건 제보', AppColors.primary),
      NotificationKind.resolved => ('발견 소식', AppColors.textSecondary),
      NotificationKind.unknown => ('알림', AppColors.textSecondary),
    };

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: label,
            style: TextStyle(color: color),
          ),
          TextSpan(text: ' · $when'),
        ],
      ),
      style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
    );
  }
}
