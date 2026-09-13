import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/auth_repository.dart';
import '../data/auth_session.dart';
import '../data/kakao_auth_source.dart';

/// 지금 로그인한 사람. 로그아웃 상태면 null이다.
///
/// **로그인은 선택이다.** null이 정상 상태이고, 앱 대부분은 이 값을 보지
/// 않는다. 등록(S7)과 내 사건 관리만 로그인을 요구한다.
class AuthNotifier extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    // 지난번 토큰이 남아 있으면 그 사람으로 시작한다. 토큰이 없거나 죽었으면
    // 게스트다.
    final token = await ref.read(tokenStorageProvider).read();
    if (token == null || token.isEmpty) return null;

    return ref.read(authRepositoryProvider).me();
  }

  /// 카카오 로그인. 성공하면 세션을, **사용자가 취소하면 null**을 돌려준다.
  ///
  /// 취소와 실패를 구분한다. 취소는 조용히 시트만 닫히면 되고, 실패는 왜
  /// 안 됐는지 적어줘야 한다.
  Future<AuthSession?> signInWithKakao() async {
    final accessToken = await ref
        .read(kakaoAuthSourceProvider)
        .requestAccessToken();
    if (accessToken == null) return null;

    final session = await ref
        .read(authRepositoryProvider)
        .loginWithKakao(accessToken);

    // 토큰을 먼저 저장해야 뒤따르는 요청에 실려 나간다(AuthInterceptor).
    await ref.read(tokenStorageProvider).write(session.token);
    state = AsyncData(session.user);

    return session;
  }

  Future<void> signOut() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AsyncData(null);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthUser?>(
  AuthNotifier.new,
);

/// 로그인했는가. 화면이 분기할 때 쓴다.
final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).value != null;
});
