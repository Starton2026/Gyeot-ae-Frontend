import 'package:gyeotae/core/push/notification_settings.dart';

/// 알림 설정을 메모리에만 담는다.
class InMemoryNotificationSettingsStorage
    implements NotificationSettingsStorage {
  InMemoryNotificationSettingsStorage([this.saved]);

  NotificationSettings? saved;

  @override
  Future<NotificationSettings> load() async =>
      saved ?? const NotificationSettings();

  @override
  Future<void> save(NotificationSettings settings) async => saved = settings;
}
