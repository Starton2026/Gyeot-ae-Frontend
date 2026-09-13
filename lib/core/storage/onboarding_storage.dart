import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 온보딩을 봤는지 기억한다. 첫 실행에 한 번만 보여주기 위한 것이다.
///
/// 테스트에서는 가짜 구현으로 갈아끼운다(test/support 참고).
abstract class OnboardingStorage {
  /// 온보딩을 이미 봤다.
  Future<bool> seen();

  /// 봤다고 표시한다. 건너뛰어도 본 것으로 친다.
  Future<void> markSeen();
}

class PrefsOnboardingStorage implements OnboardingStorage {
  const PrefsOnboardingStorage();

  static const _key = 'onboarding_seen';

  @override
  Future<bool> seen() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_key) ?? false;
  }

  @override
  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}

final onboardingStorageProvider = Provider<OnboardingStorage>((ref) {
  return const PrefsOnboardingStorage();
});
