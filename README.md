# 곁애 (Gyeot-ae) — Frontend

[해커톤] 곁에 있다 + 사랑

Flutter 앱. 백엔드는 FastAPI 서버(+ Firebase, AWS, Python AI)를 사용한다.

## 요구 환경

| 항목 | 버전 |
| --- | --- |
| Flutter | 3.41.x (stable) |
| Dart | 3.11.x |
| Android minSdk | 23 |

대상 플랫폼은 **Android · iOS**뿐이다. 웹/데스크톱(`web`, `linux`, `macos`,
`windows`) 폴더는 제거했다. 나중에 필요해지면 `flutter create --platforms=web .`
로 다시 만들 수 있다.

## 시작하기

```bash
git clone <repo> && cd gyeotae
flutter pub get
cp env/dev.json.example env/dev.json   # 서버 주소 등 로컬 설정
flutter run --dart-define-from-file=env/dev.json
```

VS Code는 `F5`(실행 구성 "곁애 (dev)")로 바로 실행된다.
Android Studio를 쓰면 Run/Debug Configurations → Additional run args에
`--dart-define-from-file=env/dev.json`을 추가한다.

### 환경 설정 (`env/dev.json`)

| 키 | 설명 |
| --- | --- |
| `API_BASE_URL` | FastAPI 서버 주소. 안드로이드 에뮬레이터에서 로컬 서버는 `http://10.0.2.2:8000` |
| `ENABLE_API_LOG` | dio 요청/응답 로그 출력 여부 |

`env/dev.json`은 git에 올라가지 않는다. 키를 추가하면 `env/dev.json.example`과
`lib/core/config/env.dart`에도 같이 추가하고 커밋한다.

## 폴더 구조

```
lib/
├─ main.dart                    진입점
├─ app.dart                     MaterialApp.router (테마 · 라우터 · 한국어 로케일)
├─ core/                         기능 전반에서 함께 쓰는 것들
│  ├─ config/env.dart           빌드 시 주입되는 환경 설정
│  ├─ network/
│  │  ├─ dio_provider.dart      dio 인스턴스 (baseUrl · 타임아웃 · 인터셉터)
│  │  ├─ auth_interceptor.dart  토큰 첨부 / 401이면 토큰 정리
│  │  └─ api_exception.dart     FastAPI 오류 응답 → 화면에 쓸 메시지
│  ├─ router/app_router.dart    경로 정의 (`AppRoute` 상수)
│  ├─ storage/token_storage.dart
│  ├─ theme/app_theme.dart      Material 3 · seedColor 하나로 색 조정
│  └─ widgets/                  LoadingView · ErrorView
└─ features/                     기능별 폴더 — 각자 여기서 작업
   ├─ auth/{data,presentation}
   └─ home/presentation
```

**기능 하나 = 폴더 하나.** 서로 다른 기능을 맡으면 파일이 겹치지 않아
merge 충돌이 거의 없다. `core/`를 고칠 때만 팀에 공유한다.

- `data/` — API 호출, 모델(`fromJson`), 리포지토리
- `presentation/` — 화면, 위젯, Riverpod 컨트롤러
- `domain/` — 로직이 복잡해진 기능에만 나중에 추가 (지금은 없음)

## 기능 추가하는 법

`features/<기능>/` 폴더를 만들고 아래 패턴을 따른다.

**1. API 호출 (`data/xxx_api.dart`)**

```dart
class DiaryApi {
  DiaryApi(this._dio);
  final Dio _dio;

  Future<List<Diary>> fetchAll() async {
    try {
      final response = await _dio.get<List<dynamic>>('/diaries');
      return response.data!
          .map((json) => Diary.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e); // 화면에 보여줄 메시지로 변환
    }
  }
}

final diaryApiProvider = Provider((ref) => DiaryApi(ref.watch(dioProvider)));
```

**2. 모델 (`data/diary.dart`)** — 코드 생성(freezed 등)은 쓰지 않는다. 손으로 쓴다.

```dart
class Diary {
  const Diary({required this.id, required this.content});

  final int id;
  final String content;

  factory Diary.fromJson(Map<String, dynamic> json) => Diary(
    id: json['id'] as int,
    content: json['content'] as String,
  );
}
```

**3. 상태 (`presentation/diary_controller.dart`)**

```dart
final diaryListProvider = FutureProvider<List<Diary>>(
  (ref) => ref.watch(diaryApiProvider).fetchAll(),
);
```

**4. 화면 (`presentation/diary_screen.dart`)**

```dart
class DiaryScreen extends ConsumerWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(diaryListProvider)) {
      AsyncData(:final value) => ListView(/* ... */),
      AsyncError(:final error) => ErrorView(
        message: error is ApiException ? error.message : '오류가 발생했어요.',
        onRetry: () => ref.invalidate(diaryListProvider),
      ),
      _ => const LoadingView(),
    };
  }
}
```

**5. 경로 추가** — `core/router/app_router.dart`의 `AppRoute`에 상수를 넣고
`routes`에 `GoRoute`를 추가한다. 이동은 `context.push(AppRoute.diary)`.

## 로그인

로그인은 **선택 사항**이다. 첫 화면은 홈이고 로그인 없이 모든 기본 화면을 볼 수 있다.

- 토큰이 저장돼 있으면 모든 요청에 `Authorization: Bearer <token>`이 자동으로 붙는다.
- 401을 받으면 저장된 토큰만 지우고, 로그인 화면으로 강제 이동시키지 않는다.
- 로그인이 꼭 필요한 화면이 생기면 그 `GoRoute`에만 `redirect`를 건다.

## Firebase 설정

패키지(`firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`)는
이미 들어 있고, 초기화 코드만 주석 처리돼 있다. 한 사람이 아래를 실행한 뒤
팀에 공유한다.

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

그다음 `lib/main.dart`의 `TODO(firebase)` 블록 주석을 풀면 된다.
생성된 설정 파일(`lib/firebase_options.dart`, `google-services.json`,
`GoogleService-Info.plist`)은 git에 올라가지 않으니 팀원끼리 직접 전달한다.

## 명령어

```bash
flutter analyze                                      # 정적 분석 (커밋 전 필수)
flutter test                                         # 전체 테스트
dart format .                                         # 포맷
flutter run --dart-define-from-file=env/dev.json     # 실행
flutter build apk --dart-define-from-file=env/dev.json
```

## 브랜치 전략

```
main            배포/발표용 — 동작이 검증된 것만
└─ dev          기본 통합 브랜치. 여기서 따고 여기로 합친다
   └─ feat/<기능>   각자 작업 브랜치 (예: feat/diary-list)
```

커밋 전에 `flutter analyze`와 `flutter test`가 통과하는지 확인한다.
