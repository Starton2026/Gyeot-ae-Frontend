# 🧡 곁애 (Gyeot-ae) — Frontend

> **실종 아동·치매노인 조기 발견 네트워크**
> "곁에 있다 + 사랑" — 시민의 눈이 모여 실종자의 골든타임을 지킵니다.

Flutter 앱(Android · iOS). 백엔드는 별도 레포(`Gyeot-ae-Backend`, Flask + face_recognition).

---

## 📌 어떤 서비스인가요?

실종자(아동·치매노인)가 발생하면 시민이 목격 사진을 제보합니다.
**AI가 실종자 원본 사진과 얼굴을 대조**해 진짜 후보만 걸러내고,
매칭된 제보를 **시간순 위치로 이어 이동 경로를 지도에 그려줍니다.**

```
보호자: 실종 신고 등록 (사진 + 인상착의 + 마지막 위치)
   ↓
시민: 목격 사진 제보 (사진 + GPS 자동 첨부)
   ↓
AI: 얼굴대조 → 유사도 % 계산 → 60% 이상이면 매칭!
   ↓
관제: 매칭된 제보를 시간순으로 연결 → 이동 경로 시각화 🗺️
```

앱이 담당하는 역할은 셋입니다.

- **보호자** — 실종 신고를 등록한다
- **시민(목격자)** — 실종자 목록을 보고, 목격하면 사진 + 위치를 제보한다
- **관제(경찰/보호자)** — 들어온 제보를 지도와 타임라인으로 보며 경로를 추적한다

> 해커톤 데모 범위에서는 **로그인이 필수가 아닙니다.** 첫 화면은 홈이고,
> 역할별 화면 진입만 구분합니다. 로그인은 선택 사항으로만 열려 있습니다.

---

## 🗺️ 화면 구성

| 화면 | 경로 | 역할 | 호출 API | 상태 |
|---|---|---|---|---|
| 홈 (실종자 목록) | `/` | 시민 | `GET /missing` | 골격만 |
| 실종 신고 등록 | `/missing/new` | 보호자 | `POST /missing` | 미구현 |
| 제보하기 | `/report/:missingId` | 시민 | `POST /report` | 미구현 |
| 관제 지도 | `/monitor/:missingId` | 관제 | `GET /reports/<id>?only_match=1` | 미구현 |
| 로그인 (선택) | `/login` | 공통 | 미정 | 자리만 |

현재 커밋된 것은 **홈 · 로그인 골격과 공통 기반(네트워크 · 라우팅 · 테마 · 오류 처리)** 까지입니다.
나머지 세 화면이 이번 해커톤에서 만들 부분입니다.

---

## 🛠️ 기술 스택

| 영역 | 선택 | 비고 |
|---|---|---|
| 프레임워크 | **Flutter 3.41.x / Dart 3.11.x** | Android · iOS만 대상 |
| 상태관리 | **Riverpod 3** | 코드 생성 없이 `Provider` / `FutureProvider` / `Notifier`만 사용 |
| 라우팅 | **go_router 17** | 경로 상수는 `AppRoute` 한 곳에서 관리 |
| 네트워크 | **dio 5** | 서버 오류를 `ApiException`으로 변환, AI 대기 대비 receive timeout 60초 |
| 실시간 (선택) | **cloud_firestore** | 제보가 들어오는 순간 관제 지도에 반영 |
| 로컬 저장 | **shared_preferences** | 토큰 등 |

대상 플랫폼은 **Android · iOS**뿐입니다. 웹/데스크톱 폴더는 제거했고,
필요해지면 `flutter create --platforms=web .`으로 다시 만들 수 있습니다.

| 항목 | 값 |
|---|---|
| Android minSdk | 23 (firebase_auth 요구) |
| NDK | 사용하지 않음 ([build.gradle.kts](android/app/build.gradle.kts) 주석 참고) |

---

## 🚀 시작하기

**1. 백엔드를 먼저 띄웁니다** (별도 레포)

```bash
python app.py
```

**2. 앱 실행**

```bash
flutter pub get
```

```bash
cp env/dev.json.example env/dev.json
```

```bash
flutter run --dart-define-from-file=env/dev.json
```

VS Code는 `F5`(실행 구성 "곁애 (dev)")로 바로 실행됩니다.
Android Studio는 Run/Debug Configurations → Additional run args에
`--dart-define-from-file=env/dev.json`을 추가하세요.

### 서버 주소를 어디로 두나요

| 실행 환경 | `API_BASE_URL` |
|---|---|
| Android 에뮬레이터 | `http://10.0.2.2:5001` (호스트의 localhost) |
| iOS 시뮬레이터 | `http://localhost:5001` |
| 실기기 · 데모 | ngrok URL (`https://xxxx.ngrok.io`) |

`env/dev.json`은 git에 올라가지 않습니다. 키를 추가하면
[env/dev.json.example](env/dev.json.example)과 [lib/core/config/env.dart](lib/core/config/env.dart)에도
같이 추가해서 커밋하세요.

| 키 | 설명 |
|---|---|
| `API_BASE_URL` | 백엔드 주소 |
| `ENABLE_API_LOG` | dio 요청/응답 로그 출력 여부 |

> 로컬 서버는 평문 HTTP라 OS가 기본적으로 막습니다. 디버그 빌드에서만 허용해 뒀습니다
> (Android `usesCleartextTraffic`, iOS `NSAllowsLocalNetworking`). release 빌드는 HTTPS만
> 허용되니 배포용으로는 ngrok/HTTPS 주소를 쓰세요.

---

## 📁 폴더 구조

```
lib/
├─ main.dart                    진입점
├─ app.dart                     MaterialApp.router (테마 · 라우터 · 한국어 로케일)
├─ core/                         기능 전반에서 함께 쓰는 것
│  ├─ config/env.dart           빌드 시 주입되는 환경 설정
│  ├─ network/
│  │  ├─ dio_provider.dart      dio 인스턴스 (baseUrl · 타임아웃 · 인터셉터)
│  │  ├─ auth_interceptor.dart  토큰 첨부 / 401이면 토큰 정리
│  │  └─ api_exception.dart     서버 오류 응답 → 화면에 쓸 메시지
│  ├─ router/app_router.dart    경로 정의 (`AppRoute` 상수)
│  ├─ storage/token_storage.dart
│  ├─ theme/app_theme.dart      Material 3 · seedColor 하나로 색 조정
│  └─ widgets/                  LoadingView · ErrorView
└─ features/
   ├─ home/presentation         홈 = 실종자 목록 (골격)
   ├─ auth/                     선택 로그인 (골격)
   ├─ missing/                  ← 실종 신고 등록 (만들 것)
   ├─ report/                   ← 목격 제보 (만들 것)
   └─ monitor/                  ← 관제 지도 · 경로 (만들 것)
```

**기능 하나 = 폴더 하나.** 서로 다른 화면을 맡으면 파일이 겹치지 않아 merge 충돌이 거의 없습니다.
`core/`를 고칠 때만 팀에 공유하세요.

- `data/` — API 호출, 모델(`fromJson`), 리포지토리
- `presentation/` — 화면, 위젯, Riverpod 컨트롤러
- `domain/` — 로직이 복잡해진 기능에만 나중에 추가 (지금은 없음)

---

## 📡 백엔드 API

Base URL은 `Env.apiBaseUrl`. 업로드는 모두 `multipart/form-data`이고 CORS가 열려 있습니다.

| # | 메서드 | 경로 | 역할 |
|---|---|---|---|
| 1 | `GET` | `/missing` | 실종자 목록 |
| 2 | `POST` | `/missing` | 실종자 등록 (`name`, `description`, `last_lat`, `last_lng`, `photo`) |
| 3 | `POST` | `/report` | 제보 접수 + 얼굴대조 (`missing_id`, `lat`, `lng`, `photo`) |
| 4 | `GET` | `/reports/<missing_id>?only_match=1` | 제보 목록 + 이동 경로 |
| 5 | `GET` | `/uploads/<filename>` | 사진 서빙 |

### 사진 URL 만들기

응답의 `photo` / `photo_url`은 파일명이거나 절대 URL입니다. 파일명일 때는 base URL을 붙입니다.

```dart
String photoUrl(String photo) =>
    photo.startsWith('http') ? photo : '${Env.apiBaseUrl}/uploads/$photo';

Image.network(photoUrl(report.photo));
```

### 제보 보내기 (사진 + GPS)

```dart
final form = FormData.fromMap({
  'missing_id': missingId,
  'lat': lat,
  'lng': lng,
  'photo': await MultipartFile.fromFile(file.path, filename: 'sighting.jpg'),
});

final response = await _dio.post<Map<String, dynamic>>('/report', data: form);
// { similarity: 88.5, is_match: true, face_found: true, alert: true, ... }
```

### 이동 경로 받아오기

`GET /reports/<id>?only_match=1`의 `path`는 **시간순으로 정렬**되어 있어,
그대로 지도 폴리라인으로 연결하면 이동 경로가 됩니다.

```json
{
  "count": 2,
  "reports": [{ "id": "...", "lat": 37.57, "lng": 126.98, "photo": "report_x.jpg",
                "similarity": 88.5, "is_match": true, "reported_at": "..." }],
  "path": [{ "lat": 37.5700, "lng": 126.9820, "time": "2026-09-10T22:01:00" },
           { "lat": 37.5720, "lng": 126.9850, "time": "2026-09-10T22:20:00" }]
}
```

### 오류 처리

서버는 오류를 `{"error": "사진에서 얼굴을 찾지 못했습니다."}` 형태로 돌려줍니다.
`ApiException.from(e)`가 이 메시지를 뽑아주니, 화면에서는 그대로 보여주면 됩니다.

```dart
try {
  return await _api.submitReport(missingId: id, lat: lat, lng: lng, file: file);
} on DioException catch (e) {
  throw ApiException.from(e); // message · statusCode · isNetworkIssue
}
```

얼굴을 못 찾은 400은 사용자가 사진을 다시 찍어야 하는 경우이니,
`ErrorView`의 재시도 대신 "다시 촬영" 안내로 처리하세요.

---

## 🧩 기능 추가하는 법

`features/<기능>/` 폴더를 만들고 아래 순서대로 채웁니다.

**1. 모델 (`data/missing_person.dart`)** — 코드 생성(freezed 등)은 쓰지 않고 손으로 씁니다.

```dart
class MissingPerson {
  const MissingPerson({
    required this.id,
    required this.name,
    required this.description,
    required this.photo,
  });

  final String id;
  final String name;
  final String description;
  final String photo;

  factory MissingPerson.fromJson(Map<String, dynamic> json) => MissingPerson(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    photo: json['photo'] as String? ?? '',
  );
}
```

**2. API (`data/missing_api.dart`)**

```dart
class MissingApi {
  MissingApi(this._dio);

  final Dio _dio;

  Future<List<MissingPerson>> fetchAll() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/missing');
      final list = response.data!['missing'] as List<dynamic>;
      return list
          .map((e) => MissingPerson.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}

final missingApiProvider =
    Provider((ref) => MissingApi(ref.watch(dioProvider)));
```

**3. 상태 (`presentation/missing_controller.dart`)**

```dart
final missingListProvider = FutureProvider<List<MissingPerson>>(
  (ref) => ref.watch(missingApiProvider).fetchAll(),
);
```

**4. 화면 (`presentation/missing_list_screen.dart`)**

```dart
class MissingListScreen extends ConsumerWidget {
  const MissingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(missingListProvider)) {
      AsyncData(:final value) => ListView.builder(
        itemCount: value.length,
        itemBuilder: (context, i) => MissingTile(person: value[i]),
      ),
      AsyncError(:final error) => ErrorView(
        message: error is ApiException ? error.message : '오류가 발생했어요.',
        onRetry: () => ref.invalidate(missingListProvider),
      ),
      _ => const LoadingView(),
    };
  }
}
```

**5. 경로 추가** — [app_router.dart](lib/core/router/app_router.dart)의 `AppRoute`에 상수를 넣고
`routes`에 `GoRoute`를 추가합니다. 이동은 `context.push(AppRoute.report)`.

---

## 📦 아직 정하지 않은 것 (지도 · 카메라 · 위치)

관제 지도와 제보 화면에 필요한 패키지는 **아직 넣지 않았습니다.** 정해지면 추가하세요.

| 필요 | 후보 | 메모 |
|---|---|---|
| 지도 · 폴리라인 | `kakao_map_plugin` / `google_maps_flutter` / `flutter_naver_map` | 백엔드 README는 카카오맵 SDK 기준. 어느 쪽이든 API 키 발급 필요 |
| 카메라 · 갤러리 | `image_picker` | 제보 사진 촬영 |
| GPS | `geolocator` | 제보 시 위치 자동 첨부 |
| 권한 | `permission_handler` | 위치 · 카메라 권한 안내 |
| 이미지 캐시 | `cached_network_image` | 목록 썸네일 |

```bash
flutter pub add image_picker geolocator permission_handler cached_network_image
```

지도 SDK는 키 발급과 네이티브 설정이 따라오니, 지도 담당이 정한 뒤 한 번에 추가하는 게 좋습니다.

---

## 🔥 Firestore 실시간 연동 (선택)

제보가 접수되는 **순간** 관제 지도에 핀이 찍히게 하려면 Firestore를 구독합니다.
`cloud_firestore` 패키지는 이미 들어 있고, 초기화 코드만 주석 처리돼 있습니다.

**설정 (한 사람이 1회)**

```bash
dart pub global activate flutterfire_cli
```

```bash
flutterfire configure
```

백엔드와 **같은 Firebase 프로젝트**를 선택하고, [lib/main.dart](lib/main.dart)의
`TODO(firebase)` 블록 주석을 풉니다. 생성된 설정 파일(`lib/firebase_options.dart`,
`google-services.json`, `GoogleService-Info.plist`)은 git에 올라가지 않으니
팀원끼리 직접 전달하세요.

**구독 예시** (백엔드의 `reports` 컬렉션)

```dart
final matchedReportsProvider = StreamProvider.family<List<Report>, String>(
  (ref, missingId) => FirebaseFirestore.instance
      .collection('reports')
      .where('missing_id', isEqualTo: missingId)
      .where('is_match', isEqualTo: true)
      .orderBy('timestamp')
      .snapshots()
      .map((snap) => snap.docs.map((d) => Report.fromJson(d.data())).toList()),
);
```

> Firebase를 안 쓰는 경우: 관제 화면에서 `GET /reports/<id>?only_match=1`을
> 2~3초마다 폴링해도 데모에는 충분합니다.

---

## 🎬 데모 시나리오

1. 보호자 화면에서 실종자 1명 등록 → `missing_id` 확보
2. 제보 화면에서 서로 다른 위치의 목격 사진을 순차 제보
3. 관제 지도로 전환 → 핀이 시간순으로 찍히고 **경로가 선으로 그려짐**
4. 하이라이트: "유사도 92% 일치!" 뜨는 순간 + 경로 애니메이션

**성공 기준**: "제보 사진 업로드 → 유사도 %가 뜨고 → 지도에 시간순 경로가 그려진다"
이 흐름이 끊김 없이 한 번 돌면 성공.

데모 직전 점검:

- [ ] `env/dev.json`의 `API_BASE_URL`이 ngrok URL로 바뀌어 있는지
- [ ] 실기기에서 위치 · 카메라 권한을 미리 허용해 뒀는지
- [ ] 백엔드에 시드 데이터(`python seed.py`)가 들어가 있는지

---

## 🔒 프라이버시

- 제보 사진은 서버에서 대조 후 삭제하는 것이 원칙입니다. 앱도 촬영한 사진을
  앨범에 남기거나 로컬에 캐시하지 않습니다.
- AI 유사도는 **후보 순위 제시**일 뿐이며 최종 확인은 사람이 합니다.
  화면에도 "AI 추정"임을 함께 표시하세요.
- 위치는 제보 시점에만 수집하고, 백그라운드 위치 추적은 하지 않습니다.

---

## 🧪 명령어

```bash
flutter analyze
```

```bash
flutter test
```

```bash
dart format .
```

```bash
flutter run --dart-define-from-file=env/dev.json
```

```bash
flutter build apk --dart-define-from-file=env/dev.json
```

## 🌿 브랜치 전략

```
main            발표/배포용 — 동작이 검증된 것만
└─ dev          기본 통합 브랜치. 여기서 따고 여기로 합친다
   └─ feat/<기능>   각자 작업 브랜치 (예: feat/report-upload)
```

커밋 전에 `flutter analyze`와 `flutter test`가 통과하는지 확인하세요.
