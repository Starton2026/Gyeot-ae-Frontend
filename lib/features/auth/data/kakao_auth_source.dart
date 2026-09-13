import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';

/// 카카오에서 `access_token`을 받아오는 자리.
///
/// 서버는 이 토큰을 카카오 API에 직접 물어 확인한다. 그래서 **가짜 토큰으로는
/// 로그인이 되지 않는다.** 앱은 토큰을 받아 넘기는 일만 한다.
abstract interface class KakaoAuthSource {
  /// 카카오 로그인을 띄우고 `access_token`을 받는다.
  ///
  /// 사용자가 취소하면 **null**이다. 취소는 오류가 아니다 — 로그인은 선택이고
  /// 제보는 로그인 없이도 된다.
  Future<String?> requestAccessToken();
}

/// 아직 카카오 SDK를 붙이지 않은 상태.
///
/// TODO(auth): `kakao_flutter_sdk_user`를 추가하고 이 자리를 채운다.
/// 카카오 개발자 콘솔에서 **카카오 로그인 활성화 + 플랫폼(패키지명·키 해시)
/// 등록**이 먼저 되어야 하고, 네이티브 앱 키는 지도와 같은 앱의 키를 쓴다.
/// 채우고 나면 [kakaoAuthSourceProvider] 한 줄만 바꾸면 된다.
class UnavailableKakaoAuthSource implements KakaoAuthSource {
  const UnavailableKakaoAuthSource();

  @override
  Future<String?> requestAccessToken() async {
    // 조용히 실패하면 버튼이 먹통인지 로그인이 실패한 것인지 알 수 없다.
    throw const ApiException('카카오 로그인은 아직 연결되지 않았어요. 조금만 기다려 주세요.');
  }
}

/// 지금은 미구현 구현체를 돌려준다. SDK를 붙이면 이 줄만 바꾼다.
final kakaoAuthSourceProvider = Provider<KakaoAuthSource>((ref) {
  return const UnavailableKakaoAuthSource();
});
