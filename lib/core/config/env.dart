/// 빌드 시점에 주입되는 환경 설정.
///
/// `flutter run --dart-define-from-file=env/dev.json` 처럼 실행하면
/// env/dev.json의 값이 여기로 들어온다. (env/dev.json.example 참고)
class Env {
  const Env._();

  /// FastAPI 서버 주소. 안드로이드 에뮬레이터에서 로컬 서버는 10.0.2.2 를 쓴다.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// true면 dio 요청/응답 로그를 콘솔에 찍는다.
  static const bool enableApiLog = bool.fromEnvironment(
    'ENABLE_API_LOG',
    defaultValue: true,
  );
}
