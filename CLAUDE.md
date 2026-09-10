# 곁애 (gyeotae) — Flutter 앱

해커톤 프로젝트. 백엔드는 FastAPI(+ Firebase, AWS, Python AI).

## 아키텍처

- **feature-first**: `lib/features/<기능>/{data,presentation}`. 기능 하나가 폴더 하나.
- `lib/core/`: 여러 기능이 함께 쓰는 것만 (network, router, theme, storage, config, widgets).
- 상태관리 Riverpod 3 / 라우팅 go_router / HTTP dio.
- **코드 생성(freezed, json_serializable, riverpod_generator)은 쓰지 않는다.** 모델은 손으로 `fromJson`을 쓴다.
- Riverpod은 `Provider`, `FutureProvider`, `Notifier`, `AsyncNotifier`만 쓴다 (레거시 `StateProvider`, `StateNotifierProvider` 금지).

## 규칙

- 새 기능은 `features/` 안에서 끝낸다. `core/`를 고쳐야 할 때만 범위를 넓힌다.
- 네트워크 오류는 `DioException`을 잡아 `ApiException.from(e)`로 바꿔서 던진다.
- 로딩/에러 UI는 `core/widgets`의 `LoadingView`, `ErrorView`를 쓴다.
- 경로 문자열은 `core/router/app_router.dart`의 `AppRoute` 상수만 참조한다.
- 환경 값은 `String.fromEnvironment`가 아니라 `Env` 클래스에 추가해서 쓴다.
- 로그인은 선택 사항이다. 로그인을 강제하는 리다이렉트를 추가하지 않는다.
- `print` 대신 `debugPrint`.

## 명령어

```bash
flutter analyze                                    # 커밋 전 필수
flutter test
flutter run --dart-define-from-file=env/dev.json
```

## 테스트

- 로직(인터셉터, 예외 변환, 저장소)은 테스트를 먼저 쓴다.
- 테스트 헬퍼는 `test/support/`에 둔다 (`InMemoryTokenStorage`, `FakeHttpAdapter`).
- dio를 쓰는 테스트는 `FakeHttpAdapter`로 갈아끼운다. 실제 네트워크를 타지 않는다.
- Riverpod 테스트는 `ProviderContainer.test()`를 쓰고, `apiLogEnabledProvider`를 `false`로 override해 출력을 깨끗하게 유지한다.
