import 'package:gyeotae/features/auth/data/auth_repository.dart';
import 'package:gyeotae/features/auth/data/auth_session.dart';
import 'package:gyeotae/features/auth/data/kakao_auth_source.dart';

/// 카카오 SDK 대신. [token]이 null이면 사용자가 취소한 것으로 친다.
class FakeKakaoAuthSource implements KakaoAuthSource {
  FakeKakaoAuthSource({
    this.token = 'kakao-access-token',
    this.error,
    this.signOutError,
  });

  final String? token;

  /// 던질 오류. 주면 [token]보다 먼저다.
  final Object? error;

  /// 카카오 로그아웃에서 던질 오류.
  final Object? signOutError;

  int calls = 0;

  int signOutCalls = 0;

  @override
  Future<void> signOut() async {
    signOutCalls += 1;

    final failure = signOutError;
    if (failure != null) throw failure;
  }

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

  /// `me()`가 돌려줄 내 정보. null이면 로그아웃 상태다.
  final AuthProfile? user;

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
  Future<AuthProfile?> me() async => user;
}
