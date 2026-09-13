import 'package:gyeotae/features/auth/data/auth_repository.dart';
import 'package:gyeotae/features/auth/data/auth_session.dart';
import 'package:gyeotae/features/auth/data/kakao_auth_source.dart';

/// 카카오 SDK 대신. [token]이 null이면 사용자가 취소한 것으로 친다.
class FakeKakaoAuthSource implements KakaoAuthSource {
  FakeKakaoAuthSource({this.token = 'kakao-access-token', this.error});

  final String? token;

  /// 던질 오류. 주면 [token]보다 먼저다.
  final Object? error;

  int calls = 0;

  @override
  Future<String?> requestAccessToken() async {
    calls += 1;

    final failure = error;
    if (failure != null) throw failure;

    return token;
  }
}

/// 서버 대신. 로그인 성공 응답을 정해두고 돌려준다.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthSession? session, this.user, this.error})
    : session =
          session ??
          const AuthSession(
            token: 'server-token',
            user: AuthUser(id: 'u_1', name: '김보호'),
            claimedReports: 2,
          );

  final AuthSession session;

  /// `me()`가 돌려줄 사람. null이면 로그아웃 상태다.
  final AuthUser? user;

  final Object? error;

  String? lastAccessToken;

  @override
  Future<AuthSession> loginWithKakao(String accessToken) async {
    lastAccessToken = accessToken;

    final failure = error;
    if (failure != null) throw failure;

    return session;
  }

  @override
  Future<AuthUser?> me() async => user;
}
