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

  /// true면 dio 요청/응답 로그를 콘솔에 찍는다.
  static const bool enableApiLog = bool.fromEnvironment(
    'ENABLE_API_LOG',
    defaultValue: true,
  );
}
