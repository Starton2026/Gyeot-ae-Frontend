import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import '../../../core/config/env.dart';
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

/// 카카오 SDK로 로그인한다.
///
/// **카카오톡이 깔려 있으면 톡으로, 없으면 카카오계정으로** 연다. 톡이 있는
/// 사람은 비밀번호를 칠 일이 없어서 정말 3초면 끝난다(시트 문구가 그렇게
/// 적혀 있다).
class KakaoSdkAuthSource implements KakaoAuthSource {
  const KakaoSdkAuthSource();

  @override
  Future<String?> requestAccessToken() async {
    if (Env.kakaoNativeAppKey.isEmpty) {
      throw const ApiException(
        '카카오 앱 키가 없어 로그인할 수 없어요. env/dev.json을 확인해 주세요.',
      );
    }

    try {
      final token = await _login();

      return token.accessToken;
    } on KakaoClientException catch (error) {
      if (error.reason == ClientErrorCause.cancelled) return null;

      throw _failed(error);
    } catch (error) {
      throw _failed(error);
    }
  }

  /// 톡이 있으면 톡으로, 아니면 카카오계정으로.
  Future<OAuthToken> _login() async {
    if (await isKakaoTalkInstalled()) {
      try {
        return await UserApi.instance.loginWithKakaoTalk();
      } on KakaoClientException catch (error) {
        // 사용자가 톡에서 취소한 것이면 계정 로그인으로 밀어붙이지 않는다.
        // 취소했는데 다른 창이 또 뜨면 갇힌 느낌이 든다.
        if (error.reason == ClientErrorCause.cancelled) rethrow;
      } catch (error) {
        // 톡으로 못 하는 경우(톡에 로그인 안 되어 있는 등)는 계정으로 넘어간다.
        debugPrint('카카오톡 로그인 실패, 카카오계정으로 넘어갑니다: $error');
      }
    }

    return UserApi.instance.loginWithKakaoAccount();
  }

  /// 실패는 화면에 한 줄로 적고, 원인은 콘솔에 남긴다.
  ///
  /// 키 해시가 콘솔에 등록된 것과 다르면 여기로 온다. 그때 SDK 로그에 **실제
  /// 키 해시가 찍히므로**, 그 값을 카카오 콘솔에 추가하면 풀린다.
  ApiException _failed(Object error) {
    debugPrint('카카오 로그인 실패: $error');

    return const ApiException('카카오 로그인을 마치지 못했어요. 잠시 후 다시 시도해 주세요.');
  }
}

final kakaoAuthSourceProvider = Provider<KakaoAuthSource>((ref) {
  return const KakaoSdkAuthSource();
});
