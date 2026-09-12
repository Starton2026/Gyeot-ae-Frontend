# 곁애 (gyeotae) — Flutter 앱

실종 아동·어르신 조기 발견 서비스의 모바일 앱 (Android · iOS).
시민이 목격 사진을 제보하면 백엔드 AI가 얼굴을 대조하고, 매칭된 제보를
시간순으로 이어 이동 경로를 지도에 그린다.

백엔드는 별도 레포(Flask + face_recognition + JSON 파일 DB, 기본 포트 5001).
Firestore는 관제 화면 실시간 갱신용으로 선택 사용. 자세한 API는 README 참고.

## 서비스 개요

실종 아동·어르신의 골든타임 확보를 위해, 시민의 목격 제보를 AI 얼굴 유사도 분석으로
검증하고, 검증된 제보를 시간순 이동 경로로 지도에 복원하는 서비스.

기존 앰버 경보가 일방향 전달에서 멈추는 것과 달리, 시민의 목격이 보호자에게
되돌아오는 양방향 구조를 만드는 것이 목표.

### 핵심 루프

```
보호자 등록 → 주변 시민 알림 → 시민 제보(사진) → AI 유사도 분석
→ 검증된 제보를 시간순 연결 → 이동 경로 복원 → 보호자 확인 → 발견
```

### 사용자 역할

역할은 계정 속성이 아니라 행동에서 파생된다. 등록한 사람이 그 사건의 보호자,
제보한 사람이 그 사건의 제보자다. 한 사용자가 두 역할을 모두 가질 수 있다.

| 역할 | 로그인 |
|---|---|
| 게스트 (기본 상태) | 불필요 |
| 제보자 | 불필요 |
| 보호자 (사건 등록자) | 필요 |

### 화면 구성

하단 네비게이션 4탭: `홈` · `실종자` · `지도` · `MY`

| ID | 화면 | 로그인 | 네비바 |
|---|---|---|---|
| S0 | 스플래시·온보딩 | — | X |
| S1 | 홈 | 불필요 | O |
| S2 | 실종자 목록 | 불필요 | O |
| S3 | 실종자 상세 | 불필요 | X |
| S4 | 제보창 | 불필요 | X |
| S4-1 | AI 분석 결과 (바텀시트) | 불필요 | X |
| S4-2 | 제보 완료 | 불필요 | X |
| S5 | 지도 (전체 보기 / 사건 선택) | 불필요 | O |
| S6 | 로그인 (모달) | — | X |
| S7 | 실종자 등록 | 필요 | X |
| S8 | MY | 분기 | O |

### 도메인 용어

| 용어 | 의미 |
|---|---|
| 사건 (MissingCase) | 실종자 1명에 대한 등록 건 |
| 제보 (Report) | 시민이 올린 목격 사진 1건 |
| 유사도 (similarity) | AI 얼굴 대조 결과 0~100 |
| 등급 (grade) | high(70↑) / medium(40~70) / low(40↓) / no_face |
| route_index | 경로 위의 순번. 40% 이상에만 부여. 지도 핀 번호와 동일 |
| 경로 (path) | route_index가 있는 제보를 observed_at 순으로 연결한 선 |
| 골든타임 | 실종 후 3시간. 긴급도 최상위 가중 |
| 긴급도 (urgency) | 골든타임 × 취약도 × 거리 × 제보공백 |

### 절대 바꾸면 안 되는 설계 결정

아래는 여러 차례 검토를 거쳐 확정된 사항이다. 구현 편의를 위해 임의로 변경하지 말 것.
변경이 필요하다고 판단되면 코드를 고치기 전에 먼저 사람에게 물어볼 것.

1. **제보는 로그인 없이 가능하다.** 목격자는 대부분 우연히 지나가는 사람이며,
   회원가입 절차는 제보 자체를 소멸시킨다. 로그인은 실종자 등록·사건 관리에만 요구한다.
2. **분석과 제보는 2단계다.** `POST /reports/analyze`로 결과를 먼저 보여주고,
   사용자가 확인한 뒤 `POST /reports`로 확정한다. 한 번에 처리하면 "취소" 버튼이
   의미를 잃는다.
3. **유사도 40% 미만 제보도 저장한다.** 임계값은 삭제 기준이 아니라 표시 등급과
   경로 포함 여부만 결정한다. 옷을 갈아입었거나 뒷모습만 찍힌 진짜 제보가 있고,
   고령자는 얼굴 인식 정확도가 구조적으로 낮다.
4. **제보 시 얼굴 미검출은 에러가 아니다.** `face_found: false`로 저장한다. 위치와
   시간만으로도 경로 복원에 기여한다. (단, 실종자 등록 시에는 얼굴 미검출을 거부한다.)
5. **경로 정렬은 `observed_at` 기준이다.** `created_at`(서버 전송 시각)이 아니다.
   사진첩에서 나중에 올리는 경우가 있다.
6. **경과 시간은 서버가 계산한다.** 사용자가 리셋할 수 없다. 사건의 사실이지
   상태값이 아니다. 목록 상위 노출은 긴급도 알고리즘이 담당하며, "재등록" 같은
   사용자 조작으로 순위를 올리는 기능을 만들지 않는다.
7. **발견 완료된 사건을 목록에서 삭제하지 않는다.** 투명도를 낮춰 유지한다.
   남겨야 서비스가 작동한다는 증거가 쌓인다.
8. **마스코트 이음이는 긴급 화면에 등장하지 않는다.** 긴급 배너, 등록 폼, AI 분석 결과,
   제보 타임라인에는 쓰지 않는다. 제보 완료·발견 완료·빈 상태·온보딩에만 등장한다.
   기능정의서 5.4의 "곁이"는 옛 이름이다. 화면 문구에는 "이음이"를 쓴다.
9. **브랜드 컬러 5색 외의 색을 임의로 추가하지 않는다.**
   `#3B6CB7` 신뢰·안전 / `#7FB3FF` 연결·기술 / `#FF7E7E` 관심·따뜻함 /
   `#FFE5E1` 배려·희망 / `#DEE6F0` 균형·신뢰감
   (텍스트용 중립 그레이 파생색은 예외)
10. **워드마크는 두 가지다.** 로고·앱 아이콘·스플래시에는 `곁愛`, 본문·푸시 알림·
    15px 이하·고령자 안내문에는 `곁애`를 쓴다. 화면 낭독기가 `愛`를 중국어로 읽거나
    건너뛴다.

## 참고 문서 (READ ONLY)

개발 시 아래 두 문서를 반드시 먼저 읽고 작업할 것.

- `docs/gyeot_ae_feature_spec.md` — 기능정의서. 화면별 기능, 권한, 긴급도·유사도 규칙,
  데이터 모델
- `docs/gyeot_ae_api_spec.md` — API 명세서. 엔드포인트, 요청·응답 스키마, 계산 규칙,
  구현 우선순위

**이 두 파일은 READ ONLY다. 어떤 이유로도 수정·삭제·이동하지 말 것.**

- 구현이 명세와 다르면 명세를 고치지 말고 코드를 고친다
- 명세에 오류가 있다고 판단되면 파일을 수정하지 말고 사람에게 보고한다
- 명세에 없는 기능이 필요하면 임의로 문서에 추가하지 말고 사람에게 물어본다
- 두 파일은 디자인 확정본 기준으로 작성되었으며, 백엔드 README보다 우선한다

## 아키텍처

- **feature-first**: `lib/features/<기능>/{data,presentation}`. 기능 하나가 폴더 하나.
  home(S1 홈) · missing(S2 목록·S3 상세·S7 등록) · map(S5 지도) · report(S4 제보) ·
  auth(S6 로그인).
- `lib/core/`: 여러 기능이 함께 쓰는 것만 (network, router, theme, storage, config, widgets).
- 상태관리 Riverpod 3 / 라우팅 go_router / HTTP dio.
- 사진 image_picker · 위치 geolocator · 권한 permission_handler (네이티브 권한 설정 완료).
- 지도는 kakao_map_sdk(네이티브 카카오맵). 키는 `Env.kakaoMapKey`로 주입한다.
- **코드 생성(freezed, json_serializable, riverpod_generator)은 쓰지 않는다.** 모델은 손으로 `fromJson`을 쓴다.
- Riverpod은 `Provider`, `FutureProvider`, `Notifier`, `AsyncNotifier`만 쓴다 (레거시 `StateProvider`, `StateNotifierProvider` 금지).

## 위젯 · 컴포넌트

화면은 위젯을 조립하는 자리다. 화면 파일에 UI를 직접 그리지 않는다.

### 배치와 승격

- 한 기능 안에서만 쓰는 위젯 → `features/<기능>/presentation/widgets/<위젯>.dart`
- **두 개 이상의 기능이 쓰는 위젯 → `core/widgets/`로 옮긴다.** 세 번째가 아니라
  두 번째가 쓸 때 옮긴다.
- 기능 폴더끼리 위젯을 직접 import하지 않는다. 필요하면 `core/widgets/`로 승격시킨다.
- 파일 하나에 공개 위젯 하나. 그 위젯만 쓰는 비공개 하위 위젯(`_XxxRow`)은 같은 파일에 둔다.

### 작성 규칙

- `StatelessWidget` 기본, 생성자에 `const`를 붙인다.
- `build` 안에서 `_buildXxx()` 메서드로 UI를 쪼개지 않는다. 별도 위젯 클래스로 뺀다.
  메서드는 리빌드 범위를 줄이지 못한다.
- 화면(`*_screen.dart`)은 라우팅·상태 구독·조립만 한다. 300줄을 넘으면 위젯을 덜 뺀 것이다.
- **공용 위젯은 Riverpod을 직접 읽지 않는다.** 값과 콜백을 파라미터로 받는다.
  `ref.watch`는 화면이나 기능 전용 위젯에서 한다.
- 위젯 클래스 위에 `///` 한 줄로 쓰임새를 적는다 (`LoadingView`, `ErrorView` 참고).
- 테스트에서 찾아야 하는 버튼·입력은 `static const Key`로 노출한다
  (`ErrorView.retryButtonKey` 참고).

### 색과 글자, 모양

- 색은 `core/theme/app_colors.dart`의 `AppColors`로만 쓴다. 브랜드 5색이 원본이고
  `primary`·`accent`·`border`는 그것을 가리킨다.
- 글자는 `core/theme/app_text_styles.dart`의 `AppTextStyles`로만 쓴다. 위젯에서
  `TextStyle(fontSize: ...)`을 직접 만들지 않는다. 색은
  `.copyWith(color: AppColors.textSecondary)`로 얹는다.
- 폰트는 Pretendard 하나다. 위젯에서 `fontFamily`를 지정하지 않는다.
- `features/` 코드에 `Color(0x...)` 리터럴이나 새 글자 크기를 만들지 않는다.
  없는 값이 필요하면 임의로 만들지 말고 물어본다.
- 버튼·입력·카드 모양은 `AppTheme`이 이미 정한다. 위젯에서 `shape`·`borderRadius`를
  다시 지정하지 않는다.
- 다크 테마는 없다. 디자인 토큰이 라이트 전용이라 `ThemeMode.light`로 고정돼 있다.

### 공용 위젯 후보

두 화면 이상에서 반복된다. 새로 그리기 전에 `core/widgets/`에 이미 있는지 본다.

| 위젯 | 쓰이는 곳 |
|---|---|
| 사건 카드 | S1 주변 사건 · S2 목록 |
| 실종자 썸네일 | S1 · S2 · S3 · S5 |
| 경과 시간 뱃지 | S1 · S2 · S3 |
| 유사도 등급 뱃지 | S3 타임라인 · S4-1 · S5 |
| 마스코트 블록 | S1 평상시 · S4-2 · 빈 상태 · 온보딩 |
| 상단바 | 5.5 규칙의 5종 변형 |

## 규칙

- 새 기능은 `features/` 안에서 끝낸다. `core/`를 고쳐야 할 때만 범위를 넓힌다.
- 네트워크 오류는 `DioException`을 잡아 `ApiException.from(e)`로 바꿔서 던진다.
  서버 오류 본문은 `{"error": {"code", "message", "field"}}` 형식이다(API 명세서 1절).
  화면이 오류마다 다르게 굴어야 하면 메시지 문자열이 아니라 `ApiException.code`를
  본다. 코드 상수는 `ApiErrorCode`에 있다.
- 데이터는 `features/<기능>/data/`의 Repository 추상 타입으로만 가져온다. 화면이
  dio를 직접 쓰지 않는다. 지금은 `core/mock/`의 인메모리 구현이 물려 있고,
  백엔드가 붙으면 `missingRepositoryProvider`·`reportRepositoryProvider` 두 줄만
  바꾼다. **`core/mock/`은 그때 통째로 지운다.**
- 사진 업로드는 `FormData` + `MultipartFile.fromFile`. 사진 URL은
  `${Env.apiBaseUrl}/uploads/<filename>`.
- 로딩/에러 UI는 `core/widgets`의 `LoadingView`, `ErrorView`를 쓴다.
- SVG 아이콘은 `core/widgets`의 `AppIcon`을 쓰고 경로는 `AppIcons` 상수로 넘긴다.
  `SvgPicture`를 직접 부르지 않는다.
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
