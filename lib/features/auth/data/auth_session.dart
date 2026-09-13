import '../../../core/network/json.dart';

/// 로그인한 사람. 카카오에서 받는 것은 **닉네임과 프로필 이미지뿐이다**(F-6.3).
///
/// 이메일·전화번호는 요구하지 않는다. 보호자 연락처는 계정이 아니라 등록
/// 폼에서 따로 받는다(F-7.10).
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    this.profileImageUrl,
  });

  final String id;
  final String name;

  /// 카카오에 프로필 사진이 없으면 null이다.
  final String? profileImageUrl;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: jsonString(json['id']),
      name: jsonString(json['name'], fallback: '사용자'),
      profileImageUrl: jsonStringOrNull(json['profile_image_url']),
    );
  }
}

/// 로그인 결과. API 명세서 2) `POST /auth/kakao`.
class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
    this.claimedReports = 0,
  });

  /// 서버가 발급한 자체 토큰. 이후 요청에 `Authorization: Bearer`로 붙는다.
  final String token;

  final AuthUser user;

  /// 로그인하면서 계정으로 옮겨간 게스트 제보 수(F-4.2.7).
  ///
  /// 같은 기기에서 로그인 전에 보낸 제보를 서버가 `X-Device-Hash`로 찾아
  /// 계정에 붙여준다. 제보 완료 화면의 소프트 로그인(F-4.2.5)이 이 숫자를
  /// 쓴다 — "보내주신 제보 2건을 계정으로 옮겼어요".
  final int claimedReports;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final user = json['user'];

    return AuthSession(
      token: jsonString(json['token']),
      user: AuthUser.fromJson(
        user is Map<String, dynamic> ? user : const <String, dynamic>{},
      ),
      claimedReports: jsonInt(json['claimed_reports']),
    );
  }
}
