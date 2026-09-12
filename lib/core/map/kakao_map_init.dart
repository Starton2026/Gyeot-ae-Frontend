import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart';

import '../config/env.dart';

/// 카카오맵 네이티브 SDK를 초기화한다.
///
/// 키가 비어 있으면 초기화를 건너뛰고 false를 돌려준다. 키를 아직 발급받지
/// 못한 팀원도 앱을 실행할 수 있어야 하므로, 여기서 예외를 던지지 않는다.
/// (지도 화면만 동작하지 않는다.)
Future<bool> initKakaoMapSdk({
  String key = Env.kakaoMapKey,
  Future<void> Function(String key)? initialize,
}) async {
  if (key.isEmpty) return false;

  final init = initialize ?? KakaoMapSdk.instance.initialize;
  await init(key);
  return true;
}

/// 지도를 그릴 수 있는 상태인가.
///
/// 키가 비어 있으면 [initKakaoMapSdk]가 초기화를 건너뛰고, 그 상태로 지도를
/// 올리면 **아무 설명 없는 흰 판**이 된다. 키를 못 받은 팀원도 앱은 그대로
/// 써야 하므로, 지도 화면은 이 값을 보고 이유를 적어 보여준다.
final kakaoMapReadyProvider = Provider<bool>((ref) {
  return Env.kakaoMapKey.isNotEmpty;
});
