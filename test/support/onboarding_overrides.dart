import 'package:flutter_riverpod/misc.dart';
import 'package:gyeotae/core/storage/onboarding_storage.dart';
import 'package:gyeotae/features/onboarding/presentation/splash_screen.dart';

/// 온보딩을 본 적 있는지 기억하는 가짜 저장소.
class FakeOnboardingStorage implements OnboardingStorage {
  FakeOnboardingStorage({this.hasSeen = true});

  bool hasSeen;

  @override
  Future<bool> seen() async => hasSeen;

  @override
  Future<void> markSeen() async => hasSeen = true;
}

/// 스플래시를 지나 홈에서 시작한다.
///
/// 앱은 스플래시에서 서지만 대부분의 테스트는 그다음 화면을 본다. 기다리는
/// 시간을 0으로 두고 온보딩을 이미 본 것으로 해서, `pumpAndSettle` 한 번이면
/// 홈에 닿는다.
///
/// [hold]를 주면 스플래시에 그만큼 머문다. 스플래시 중에 들어온 일을 볼 때 쓴다.
List<Override> startAfterOnboarding({
  bool seen = true,
  Duration hold = Duration.zero,
}) => [
  onboardingStorageProvider.overrideWithValue(
    FakeOnboardingStorage(hasSeen: seen),
  ),
  splashHoldProvider.overrideWithValue(hold),
  // 그림 디코딩은 진짜 비동기라 가짜 시계 안에서는 끝나지 않는다.
  splashWarmupProvider.overrideWithValue((_) async {}),
];
