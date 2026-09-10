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
