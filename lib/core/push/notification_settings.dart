import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 알림 대상 구분(F-8.6). 명세가 아동·어르신 둘만 고르게 한다.
enum AlertTarget { child, elderly }

/// 주변 실종 신고를 어떻게 받을지(F-8.6). API 명세서 4) `POST /devices`로 간다.
///
/// **이 설정은 주변 실종 신고에만 걸린다.** 내가 등록한 사건의 제보 알림과
/// 내가 제보한 사건의 발견 소식은 서버가 이 값을 보지 않고 항상 보낸다. 내
/// 아이를 봤다는 제보가 새벽 3시에 와도 알아야 하기 때문이다.
///
/// 기기마다 따로 둔다. 서버에 설정을 돌려받는 경로가 없고, 알림을 받는 단위도
/// 계정이 아니라 기기다.
@immutable
class NotificationSettings {
  const NotificationSettings({
    this.radiusKm = defaultRadiusKm,
    this.child = true,
    this.elderly = true,
    this.nightAlerts = true,
  });

  /// 고를 수 있는 반경. 기능정의서 F-8.6.
  static const List<int> radiusChoices = [1, 3, 5, 10];

  static const int defaultRadiusKm = 5;

  /// 야간 알림을 끄면 이 시간에는 주변 실종 신고를 보내지 않는다.
  static const ({String from, String to}) nightHours = (
    from: '23:00',
    to: '07:00',
  );

  final int radiusKm;
  final bool child;
  final bool elderly;

  /// 밤에도 받는가. 기본은 받는다 — 골든타임은 밤이라고 멈추지 않는다.
  final bool nightAlerts;

  bool isOn(AlertTarget target) => switch (target) {
    AlertTarget.child => child,
    AlertTarget.elderly => elderly,
  };

  /// 서버에 보낼 구분. **둘 다 켰으면 보내지 않는다.**
  ///
  /// 서버는 구분이 없는 기기에 '그 외' 사건까지 전부 보낸다. 둘 다 켰는데
  /// `["child", "elderly"]`를 보내면 '그 외' 사건만 조용히 빠진다.
  List<String>? get categories =>
      child && elderly ? null : [if (child) 'child', if (elderly) 'elderly'];

  /// 서버에 보낼 방해 금지 시간. 야간에도 받으면 없다.
  ({String from, String to})? get quietHours => nightAlerts ? null : nightHours;

  NotificationSettings copyWith({
    int? radiusKm,
    bool? child,
    bool? elderly,
    bool? nightAlerts,
  }) {
    return NotificationSettings(
      radiusKm: radiusKm ?? this.radiusKm,
      child: child ?? this.child,
      elderly: elderly ?? this.elderly,
      nightAlerts: nightAlerts ?? this.nightAlerts,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NotificationSettings &&
      other.radiusKm == radiusKm &&
      other.child == child &&
      other.elderly == elderly &&
      other.nightAlerts == nightAlerts;

  @override
  int get hashCode => Object.hash(radiusKm, child, elderly, nightAlerts);

  @override
  String toString() =>
      'NotificationSettings($radiusKm km, child: $child, '
      'elderly: $elderly, night: $nightAlerts)';
}

/// 알림 설정을 기기에 둔다. 테스트에서는 메모리 구현으로 갈아끼운다.
abstract interface class NotificationSettingsStorage {
  /// 저장한 적이 없으면 기본값이다.
  Future<NotificationSettings> load();

  Future<void> save(NotificationSettings settings);
}

class PrefsNotificationSettingsStorage implements NotificationSettingsStorage {
  const PrefsNotificationSettingsStorage();

  static const _radiusKey = 'notify_radius_km';
  static const _childKey = 'notify_child';
  static const _elderlyKey = 'notify_elderly';
  static const _nightKey = 'notify_night';

  @override
  Future<NotificationSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final radius = prefs.getInt(_radiusKey);
    final child = prefs.getBool(_childKey) ?? true;
    final elderly = prefs.getBool(_elderlyKey) ?? true;

    return NotificationSettings(
      // 선택지에 없는 값이 들어 있으면 버린다. 반경 7km 같은 값은 화면에서
      // 어느 칩도 켜지지 않은 채로 남는다.
      radiusKm: NotificationSettings.radiusChoices.contains(radius)
          ? radius!
          : NotificationSettings.defaultRadiusKm,
      // 둘 다 꺼진 채 저장될 수는 없지만, 그렇게 읽히면 둘 다 켠다.
      child: child || !elderly,
      elderly: elderly || !child,
      nightAlerts: prefs.getBool(_nightKey) ?? true,
    );
  }

  @override
  Future<void> save(NotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_radiusKey, settings.radiusKm);
    await prefs.setBool(_childKey, settings.child);
    await prefs.setBool(_elderlyKey, settings.elderly);
    await prefs.setBool(_nightKey, settings.nightAlerts);
  }
}

final notificationSettingsStorageProvider =
    Provider<NotificationSettingsStorage>((ref) {
      return const PrefsNotificationSettingsStorage();
    });

/// 지금 알림 설정. 바뀌면 푸시 등록이 이 값을 보고 서버에 다시 올린다.
class NotificationSettingsNotifier extends AsyncNotifier<NotificationSettings> {
  @override
  Future<NotificationSettings> build() async {
    try {
      return await ref.read(notificationSettingsStorageProvider).load();
    } on Object catch (error) {
      // 못 읽었다고 알림 등록까지 멈추면 안 된다. 기본값으로 받는다.
      debugPrint('알림 설정을 읽지 못해 기본값을 씁니다: $error');

      return const NotificationSettings();
    }
  }

  Future<void> setRadius(int radiusKm) async {
    if (!NotificationSettings.radiusChoices.contains(radiusKm)) return;

    await _update((settings) => settings.copyWith(radiusKm: radiusKm));
  }

  /// **마지막 하나 남은 대상은 끄지 않는다.** 둘 다 끄면 보낼 구분이 빈 목록인데,
  /// 서버는 빈 목록을 "전부 받음"으로 읽는다. 끄려던 사람에게 오히려 전부 간다.
  Future<void> setTarget(AlertTarget target, {required bool on}) async {
    await _update((settings) {
      final next = switch (target) {
        AlertTarget.child => settings.copyWith(child: on),
        AlertTarget.elderly => settings.copyWith(elderly: on),
      };

      return next.child || next.elderly ? next : settings;
    });
  }

  Future<void> setNightAlerts({required bool on}) async {
    await _update((settings) => settings.copyWith(nightAlerts: on));
  }

  Future<void> _update(
    NotificationSettings Function(NotificationSettings current) change,
  ) async {
    final current = await future;
    final next = change(current);
    if (next == current) return;

    state = AsyncData(next);

    try {
      await ref.read(notificationSettingsStorageProvider).save(next);
    } on Object catch (error) {
      // 이번 실행에서는 바뀐 값으로 돈다. 다음에 켜면 옛 값으로 돌아갈 뿐이다.
      debugPrint('알림 설정을 저장하지 못했습니다: $error');
    }
  }
}

final notificationSettingsProvider =
    AsyncNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
      NotificationSettingsNotifier.new,
    );
