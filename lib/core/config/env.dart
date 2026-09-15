/// 빌드 시점에 주입되는 환경 설정.
///
/// `flutter run --dart-define-from-file=env/dev.json` 처럼 실행하면
/// env/dev.json의 값이 여기로 들어온다. (env/dev.json.example 참고)
class Env {
  const Env._();

  /// Flask 서버 주소 (기본 포트 5001).
  ///
  /// 안드로이드 에뮬레이터에서 호스트의 localhost는 10.0.2.2 로 접근한다.
  /// 실기기나 데모에서는 ngrok URL을 넣는다.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5001',
  );

  /// 서버가 준 상대 경로(`/uploads/xxx.jpg`)를 절대 URL로 바꾼다.
  ///
  /// 이미 `http`로 시작하는 값이면 그대로 돌려준다. 백엔드가 절대 URL을 주기
  /// 시작해도 화면을 고치지 않기 위한 것이다.
  static String photoUrl(String path) {
    if (path.startsWith('http')) return path;

    final base = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    final suffix = path.startsWith('/') ? path : '/$path';

    return '$base$suffix';
  }

  /// 카카오맵 **네이티브 앱 키**. 비어 있으면 지도 SDK를 초기화하지 않는다.
  ///
  /// Kakao Developers에서 앱 등록 후 발급받아 env/dev.json에 넣는다.
  static const String kakaoMapKey = String.fromEnvironment('KAKAO_MAP_KEY');

  /// 카카오 **네이티브 앱 키**. 지도와 로그인이 같은 값을 쓴다.
  ///
  /// 카카오 개발자 콘솔의 앱 하나에 지도와 로그인이 함께 붙어 있어서 키도
  /// 하나다. 설정 이름이 `KAKAO_MAP_KEY`인 것은 지도를 먼저 붙였기 때문이고,
  /// 값은 같다. 안드로이드 매니페스트의 로그인 리디렉트 스킴도 빌드할 때 이
  /// 값을 읽어 간다(android/app/build.gradle.kts).
  static const String kakaoNativeAppKey = kakaoMapKey;

  /// 카카오 **REST API 키**. 좌표를 주소로 바꾸는 로컬 API가 쓴다.
  ///
  /// 네이티브 앱 키와 다른 값이다. 콘솔의 같은 앱 → 앱 키에서 복사한다.
  /// 비어 있으면 주소를 조회하지 않고, 등록 폼이 주소를 직접 적게 한다.
  static const String kakaoRestApiKey = String.fromEnvironment(
    'KAKAO_REST_API_KEY',
  );

  /// true면 dio 요청/응답 로그를 콘솔에 찍는다.
  static const bool enableApiLog = bool.fromEnvironment(
    'ENABLE_API_LOG',
    defaultValue: true,
  );
}
