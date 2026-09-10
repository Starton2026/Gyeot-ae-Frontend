# 곁애 (gyeotae) — Flutter 앱

실종 아동·치매노인 조기 발견 서비스의 모바일 앱 (Android · iOS).
시민이 목격 사진을 제보하면 백엔드 AI가 얼굴을 대조하고, 매칭된 제보를
시간순으로 이어 이동 경로를 지도에 그린다.

백엔드는 별도 레포(Flask + face_recognition + JSON 파일 DB, 기본 포트 5001).
Firestore는 관제 화면 실시간 갱신용으로 선택 사용. 자세한 API는 README 참고.

## 아키텍처

- **feature-first**: `lib/features/<기능>/{data,presentation}`. 기능 하나가 폴더 하나.
  화면은 home(실종자 목록) · missing(신고 등록) · report(제보) · monitor(관제 지도) · auth(선택 로그인).
- `lib/core/`: 여러 기능이 함께 쓰는 것만 (network, router, theme, storage, config, widgets).
- 상태관리 Riverpod 3 / 라우팅 go_router / HTTP dio.
- 사진 image_picker · 위치 geolocator · 권한 permission_handler (네이티브 권한 설정 완료).
- 지도는 kakao_map_sdk(네이티브 카카오맵). 키는 `Env.kakaoMapKey`로 주입한다.
- **코드 생성(freezed, json_serializable, riverpod_generator)은 쓰지 않는다.** 모델은 손으로 `fromJson`을 쓴다.
- Riverpod은 `Provider`, `FutureProvider`, `Notifier`, `AsyncNotifier`만 쓴다 (레거시 `StateProvider`, `StateNotifierProvider` 금지).

## 규칙

- 새 기능은 `features/` 안에서 끝낸다. `core/`를 고쳐야 할 때만 범위를 넓힌다.
- 네트워크 오류는 `DioException`을 잡아 `ApiException.from(e)`로 바꿔서 던진다.
  서버 오류 본문은 `{"error": "..."}` 형식이다.
- 사진 업로드는 `FormData` + `MultipartFile.fromFile`. 사진 URL은
  `${Env.apiBaseUrl}/uploads/<filename>`.
- 로딩/에러 UI는 `core/widgets`의 `LoadingView`, `ErrorView`를 쓴다.
- 경로 문자열은 `core/router/app_router.dart`의 `AppRoute` 상수만 참조한다.
- 환경 값은 `String.fromEnvironment`가 아니라 `Env` 클래스에 추가해서 쓴다.
- 로그인은 선택 사항이다. 로그인을 강제하는 리다이렉트를 추가하지 않는다.
- 위치·카메라 권한 거부는 정상 경로다. 기능을 막지 말고 대안(위치 없이 제보 등)을 준다.
- `print` 대신 `debugPrint`.

## Git 규칙

**커밋은 사용자가 요청할 때만 한다.** 실기기 테스트가 OK일 때만 커밋하기 때문이다.
작업이 끝나면 변경 사항을 working tree에 그대로 두고, 커밋하지 않은 상태로 보고한다.

- `git push` **금지.** 사용자가 직접 한다.
- **PR 생성 금지.** 사용자가 직접 한다. 단 **PR 메시지 작성은 요청하면 해준다**
  (양식은 `.github/pull_request_template.md`).
- 브랜치 생성과 `git switch`도 사용자가 하고 공지한다. 먼저 만들지 않는다.

### 커밋 메시지

```
[커밋태그/#이슈번호] 제목

본문(선택)
```

이슈 번호가 없는 간단한 수정이면 번호를 생략하고 `[커밋태그] 제목`.

- `[feat/#12] 제보 사진 업로드 연결`
- `[chore] 린트 규칙 정리`

커밋 태그: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

### 브랜치 이름

`커밋태그/#이슈번호-설명` (예: `feat/#12-report-upload`)

이슈는 사용자가 만든다. 해커톤 기간이 짧아 이슈는 번호를 알기 위한 용도로만 쓴다.

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
