# 🧡 곁애 (Gyeot-ae) — Frontend

> **실종 아동·어르신 조기 발견 네트워크**
> "곁에 있다 + 사랑" — 시민의 눈이 모여 실종자의 골든타임을 지킵니다.

Flutter 앱 (Android · iOS). 서버 API는 별도 레포에서 관리합니다.

---

## 📌 어떤 서비스인가요?

실종자(아동·어르신)가 발생하면 시민이 목격 사진을 제보합니다.
AI가 실종자 사진과 얼굴을 대조해 진짜 후보만 걸러내고,
매칭된 제보를 **시간순 위치로 이어 이동 경로를 지도에 그려줍니다.**

```
보호자: 실종 신고 등록 (사진 + 인상착의 + 마지막 위치)
   ↓
시민: 목격 사진 제보 (사진 + GPS 자동 첨부)
   ↓
AI: 얼굴대조 → 유사도 % 계산 → 매칭 판정
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

| 화면 | 경로 | 역할 | 상태 |
|---|---|---|---|
| 홈 (실종자 목록) | `/` | 시민 | 골격만 |
| 실종 신고 등록 | `/missing/new` | 보호자 | 미구현 |
| 제보하기 | `/report/:missingId` | 시민 | 미구현 |
| 관제 지도 | `/monitor/:missingId` | 관제 | 미구현 |
| 로그인 (선택) | `/login` | 공통 | 자리만 |

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
| 사진 · 위치 | **image_picker · geolocator · permission_handler** | 제보 화면용 |
| 실시간 (선택) | **cloud_firestore** | 제보가 들어오는 순간 관제 지도에 반영 |
| 로컬 저장 | **shared_preferences** | 토큰 등 |
| 지도 | **kakao_map_sdk** | 네이티브 카카오맵. 이동 경로는 `PolylineShape` |

| 항목 | 값 |
|---|---|
| Android minSdk | 23 |
| NDK | 사용하지 않음 ([build.gradle.kts](android/app/build.gradle.kts) 주석 참고) |
| 대상 플랫폼 | Android · iOS (웹/데스크톱 폴더는 제거. 필요하면 `flutter create --platforms=web .`) |

---

## 🚀 시작하기

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

API 서버가 떠 있어야 화면에 데이터가 들어옵니다 (서버 실행 방법은 서버 레포 참고).

### 환경 설정 (`env/dev.json`)

| 키 | 설명 |
|---|---|
| `API_BASE_URL` | 서버 주소 |
| `ENABLE_API_LOG` | dio 요청/응답 로그 출력 여부 |
| `KAKAO_MAP_KEY` | 카카오맵 **네이티브 앱 키** (비어 있으면 지도만 비활성) |

`env/dev.json`은 git에 올라가지 않습니다. 키를 추가하면
[env/dev.json.example](env/dev.json.example)과 [lib/core/config/env.dart](lib/core/config/env.dart)에도
같이 추가해서 커밋하세요.

**실행 환경별 `API_BASE_URL`**

| 실행 환경 | 값 |
|---|---|
| Android 에뮬레이터 | `http://10.0.2.2:5001` (호스트의 localhost) |
| iOS 시뮬레이터 | `http://localhost:5001` |
| 실기기 · 데모 | 공개 URL (`https://...`) |

> 로컬 서버는 평문 HTTP라 OS가 기본적으로 막습니다. 디버그 빌드에서만 허용해 뒀습니다
> (Android `usesCleartextTraffic`, iOS `NSAllowsLocalNetworking`). release 빌드는 HTTPS만
> 허용되니 배포용으로는 HTTPS 주소를 쓰세요.

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

## 🔌 서버 연동

엔드포인트 명세는 **서버 레포 README**가 기준입니다. 여기서는 앱에서 부르는 방법만 정리합니다.

### 요청 보내기

`dioProvider`를 읽어서 쓰면 base URL · 타임아웃 · 토큰 첨부가 이미 적용돼 있습니다.

```dart
final response = await ref.watch(dioProvider).get<Map<String, dynamic>>('/missing');
```

### 사진 업로드 (multipart)

```dart
final form = FormData.fromMap({
  'missing_id': missingId,
  'lat': lat,
  'lng': lng,
  'photo': await MultipartFile.fromFile(file.path, filename: 'sighting.jpg'),
});

final response = await _dio.post<Map<String, dynamic>>('/report', data: form);
```

### 서버가 준 사진 보여주기

응답의 사진 값은 파일명이거나 절대 URL입니다. 파일명일 때는 base URL을 붙입니다.

```dart
String photoUrl(String photo) =>
    photo.startsWith('http') ? photo : '${Env.apiBaseUrl}/uploads/$photo';

Image.network(photoUrl(person.photo));
```

### 오류 처리

`DioException`을 잡아 `ApiException.from(e)`로 바꾸면 서버가 보낸 메시지가 그대로 담깁니다.

```dart
try {
  return await _api.submitReport(missingId: id, lat: lat, lng: lng, file: file);
} on DioException catch (e) {
  throw ApiException.from(e); // message · statusCode · isNetworkIssue
}
```

화면에서는 `ErrorView(message: e.message, onRetry: ...)`로 보여주면 됩니다.
단, "사진에서 얼굴을 찾지 못했다"류의 400은 재시도가 아니라 **다시 촬영** 안내로 처리하세요.

---

## 📷 사진 · 위치 · 권한

패키지와 네이티브 권한 설정은 **이미 되어 있습니다.**

| 패키지 | 용도 |
|---|---|
| `image_picker` | 목격 사진 촬영 / 갤러리 선택 |
| `geolocator` | 제보 시 현재 위치 |
| `permission_handler` | 권한 상태 확인 · 설정 화면 열기 (12.x 고정 — 아래 참고) |

**설정된 권한**

| 플랫폼 | 내용 |
|---|---|
| Android | `INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` ([AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)) |
| iOS | `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSLocationWhenInUseUsageDescription` ([Info.plist](ios/Runner/Info.plist)) |

사진 촬영·선택은 `image_picker`가 시스템 카메라와 사진 선택기를 띄우므로
Android에 `CAMERA` · `READ_MEDIA_IMAGES` 권한 선언이 필요하지 않습니다.

> ⚠️ `permission_handler`는 **12.x에 고정**돼 있습니다. 13.x의 android 모듈이
> AGP 9 / Kotlin 2.3을 요구해서 현재 툴체인(AGP 8.11 / Kotlin 2.2)에서는 Gradle
> 빌드가 깨집니다. 툴체인을 올릴 때 같이 올리세요.

> ⚠️ **iOS 빌드 담당자에게**: `permission_handler`는 iOS에서 쓰지 않는 권한을
> Podfile 매크로로 꺼야 심사에서 문제가 없습니다. macOS에서 첫 빌드를 하면
> `ios/Podfile`이 생성되니, 그때 `post_install` 블록에 카메라 · 사진 · 위치만 켜고
> 나머지를 `0`으로 두는 설정을 추가하세요
> ([permission_handler iOS 설정](https://pub.dev/packages/permission_handler#ios)).

### 사진 + 위치 받아오기 (제보 화면 참고용)

```dart
// 1) 사진
final picked = await ImagePicker().pickImage(
  source: ImageSource.camera,
  imageQuality: 85,       // 업로드 용량 줄이기
  maxWidth: 1600,
);
if (picked == null) return; // 사용자가 취소

// 2) 위치 — 권한 상태를 먼저 확인한다
var permission = await Geolocator.checkPermission();
if (permission == LocationPermission.denied) {
  permission = await Geolocator.requestPermission();
}
if (permission == LocationPermission.deniedForever) {
  // 다시 물어볼 수 없는 상태 → 설정 화면으로 안내
  await openAppSettings(); // permission_handler
  return;
}

final position = await Geolocator.getCurrentPosition();
```

권한 거부는 정상 경로입니다. 거부되면 제보를 막지 말고, 위치 없이 제보하거나
지도에서 직접 위치를 찍게 하는 대안을 주세요.

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

## 🗺️ 지도 (카카오맵)

[`kakao_map_sdk`](https://pub.dev/packages/kakao_map_sdk) (네이티브 SDK)를 씁니다.
이동 경로는 `PolylineShape` / `RouteLayer`로 그립니다. 패키지와 네이티브 설정은
**이미 되어 있고, 남은 것은 키 발급뿐입니다.**

**키 발급 (한 사람이 1회)**

1. [Kakao Developers](https://developers.kakao.com)에서 앱 등록
2. **네이티브 앱 키**를 복사 (JavaScript 키가 아닙니다)
3. 플랫폼 등록에 필요한 키 해시는 앱에서 확인할 수 있습니다

   ```dart
   final hash = await KakaoMapSdk.instance.hashKey();
   ```

4. 발급받은 키를 각자 `env/dev.json`의 `KAKAO_MAP_KEY`에 넣습니다

키는 [main.dart](lib/main.dart)에서 `initKakaoMapSdk()`가 읽어 초기화합니다.
**키가 비어 있으면 초기화를 건너뛰므로**, 키를 못 받은 팀원도 앱은 그대로 실행됩니다
(지도 화면만 동작하지 않음).

**설정된 것**

| 항목 | 내용 |
|---|---|
| 권한 | `INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` |
| ProGuard | [proguard-rules.pro](android/app/proguard-rules.pro) — release 축소에서 지도 클래스 보존 |
| 최소 버전 | Android API 23 · iOS 13 (프로젝트 설정과 일치) |

**지도 띄우기**

```dart
KakaoMap(
  option: const KakaoMapOption(
    position: LatLng(37.5665, 126.9780),
    zoomLevel: 16,
  ),
  onMapReady: (controller) {
    // 여기서 제보 위치 마커와 경로 폴리라인을 올린다
  },
)
```

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

서버와 **같은 Firebase 프로젝트**를 선택하고, [lib/main.dart](lib/main.dart)의
`TODO(firebase)` 블록 주석을 풉니다. 생성된 설정 파일(`lib/firebase_options.dart`,
`google-services.json`, `GoogleService-Info.plist`)은 git에 올라가지 않으니
팀원끼리 직접 전달하세요.

**구독 예시**

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

> Firestore를 안 쓰는 경우: 관제 화면에서 제보 목록을 2~3초마다 다시 불러도(`ref.invalidate`)
> 데모에는 충분합니다.

---

## 🎬 데모 시나리오

1. 보호자 화면에서 실종자 1명 등록
2. 제보 화면에서 서로 다른 위치의 목격 사진을 순차 제보
3. 관제 지도로 전환 → 핀이 시간순으로 찍히고 **경로가 선으로 그려짐**
4. 하이라이트: "유사도 92% 일치!" 뜨는 순간 + 경로 애니메이션

**성공 기준**: "제보 사진 업로드 → 유사도 %가 뜨고 → 지도에 시간순 경로가 그려진다"
이 흐름이 끊김 없이 한 번 돌면 성공.

데모 직전 점검:

- [ ] `env/dev.json`의 `API_BASE_URL`이 공개 URL로 바뀌어 있는지
- [ ] `KAKAO_MAP_KEY`가 채워져 있는지
- [ ] 실기기에서 위치 · 카메라 권한을 미리 허용해 뒀는지
- [ ] 서버에 시드 데이터가 들어가 있는지

---

## 🔒 프라이버시

- 촬영한 사진을 앨범에 남기거나 로컬에 캐시하지 않습니다.
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
