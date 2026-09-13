# 곁애(Gyeot-ae) API 명세서

> 기준: 2026-09-12 디자인 확정본
> 현재 백엔드(`Gyeot-ae-Backend`)에서 **확장이 필요한 부분을 포함**한 목표 명세입니다. 기존 엔드포인트와의 대응은 각 항목의 `백엔드 현황` 표시를 참고하세요.

---

## 1. 공통

### Base URL

```
로컬   http://localhost:5001
데모   https://xxxx.ngrok.io   (ngrok)
```

### 인증

| 구분 | 방식 |
|---|---|
| 게스트 | 헤더 `X-Device-Hash` 필수 (클라이언트가 생성·보관하는 기기 고유 해시) |
| 로그인 | 헤더 `Authorization: Bearer <token>` |

**제보·조회 계열은 전부 게스트로 호출 가능하다.** 등록·수정·발견완료만 토큰을 요구한다.

### 공통 헤더

```http
X-Device-Hash: d4f8a91c...        # 항상 전송
Authorization: Bearer eyJhbG...   # 로그인 시에만
Content-Type: multipart/form-data # 업로드 시
```

### 에러 포맷

```json
{
  "error": {
    "code": "FACE_NOT_FOUND",
    "message": "사진에서 얼굴을 찾지 못했습니다.",
    "field": "photo"
  }
}
```

| 코드 | HTTP | 설명 |
|---|---|---|
| `VALIDATION_ERROR` | 400 | 필수 항목 누락·형식 오류 |
| `FACE_NOT_FOUND` | 400 | 등록 시 얼굴 미검출 (등록은 거부) |
| `UNAUTHORIZED` | 401 | 토큰 없음·만료 |
| `FORBIDDEN` | 403 | 보호자 전용 기능에 타인 접근 |
| `NOT_FOUND` | 404 | 리소스 없음 |
| `ANALYSIS_EXPIRED` | 410 | 분석 결과 TTL 만료 (10분) |
| `RATE_LIMITED` | 429 | 게스트 제보 횟수 초과 |

> **제보 시 얼굴 미검출은 에러가 아니다.** `face_found: false`로 저장하고 "얼굴 미검출" 등급을 부여한다. 뒷모습·측면 사진도 경로 복원에 쓰인다.

### 날짜 형식

모든 시각은 **ISO 8601 + KST 오프셋**. `2026-09-11T14:40:00+09:00`

### 페이지네이션

```
?cursor=<opaque>&limit=20
```

응답에 `next_cursor` 포함, 마지막 페이지면 `null`.

---

## 2. 엔드포인트 요약

| # | 메서드 | 경로 | 인증 | 사용 화면 |
|---|---|---|:---:|---|
| 1 | `POST` | `/auth/kakao` | — | S6 |
| 3 | `GET` | `/auth/me` | 토큰 | S8 |
| 4 | `POST` | `/devices` | 게스트 | 온보딩·S8 |
| 5 | `POST` | `/missing` | 토큰 | S7 |
| 6 | `GET` | `/missing` | 게스트 | S1·S2·S5 |
| 7 | `GET` | `/missing/{id}` | 게스트 | S3 |
| 8 | `PATCH` | `/missing/{id}` | 보호자 | S3 |
| 9 | `POST` | `/missing/{id}/photos` | 보호자 | S3 |
| 10 | `POST` | `/missing/{id}/resolve` | 보호자 | S3·S8 |
| 11 | `POST` | `/missing/{id}/boost` | 보호자 | S3 |
| 12 | `GET` | `/missing/{id}/duplicate` | 보호자 | S8 재등록 |
| 13 | **`POST`** | **`/reports/analyze`** | 게스트 | **S4-1** |
| 14 | **`POST`** | **`/reports`** | 게스트 | **S4** |
| 15 | `GET` | `/missing/{id}/reports` | 게스트 | S3·S5 |
| 16 | `PATCH` | `/reports/{id}` | 보호자 | S3 |
| 17 | `POST` | `/reports/{id}/flag` | 게스트 | S3 |
| 18 | `GET` | `/me/reports` | 게스트/토큰 | S8 |
| 19 | `GET` | `/uploads/{filename}` | — | 공통 |

---

## 3. 인증

**로그인은 카카오 하나뿐이다.** 이메일·비밀번호 가입은 두지 않는다. 보호자가 등록을
시도하는 순간은 손이 떨리는 상황이고, 그 자리에서 가입 폼을 채우게 하면 등록 자체가
사라진다. 제보자에게는 애초에 로그인을 요구하지 않는다.

### 1) 카카오 로그인

`POST /auth/kakao`

```json
// Request
{ "access_token": "kakao_access_token..." }

// 200
{
  "token": "eyJhbG...",
  "user": {
    "id": "u_a1b2",
    "kakao_id": "3921847562",
    "name": "김수진",
    "profile_image_url": "https://k.kakaocdn.net/.../profile.jpg",
    "created_at": "2026-09-11T09:12:00+09:00"
  },
  "claimed_reports": 2
}
```

클라이언트가 카카오 SDK로 받은 `access_token`을 보내면 서버가 카카오에 확인한 뒤
자기 토큰을 발급한다. **가입과 로그인을 구분하지 않는다.** 처음 보는 `kakao_id`면
그 자리에서 계정을 만든다.

| 필드 | 설명 |
|---|---|
| `kakao_id` | 카카오 회원번호. 계정을 찾는 키다 |
| `name` | 카카오 닉네임 |
| `profile_image_url` | 카카오 프로필 이미지. 없을 수 있다(`null`) |
| `claimed_reports` | 같은 `X-Device-Hash`로 남긴 게스트 제보를 계정에 귀속시킨 건수 |

**카카오에서 받는 정보는 닉네임과 프로필 이미지뿐이다.** 이메일·전화번호는 동의
항목에 넣지 않는다. 동의 화면이 길어질수록 로그인에서 이탈하고, 이 서비스는 그
이탈을 감당할 수 없다.

**보호자 연락처는 받지 않는다**(2026-09-14 삭제). 제보자에게 공개하지 않고
운영팀이 사건마다 확인할 수도 없어, 쓰는 곳 없이 모으기만 하는 개인정보였다.
보호자는 로그인한 계정으로 제보 소식을 받고, 제보자와 보호자는 연락처를 주고받지
않는다(사칭·금전 요구 사기 방지). 제보자가 실종자와 함께 있다면 112에 신고한다.

`claimed_reports`가 필요한 이유 — **S4-2에서 "로그인하고 알림 받기"를 눌렀을 때
방금 한 제보가 이력에 남아야 한다.** 게스트 제보를 허용한 대가로 생기는 공백을
메우는 유일한 자리다.

### 3) 내 정보

`GET /auth/me` → `{ "user": {...}, "cases": 1, "reports": 6 }`

> 2)번은 비워 뒀다. 이메일 로그인(`POST /auth/login`)이 있던 자리다. 번호를 당기면
> 뒤의 모든 항목이 밀리는데, 앱 코드 주석과 백엔드가 이 번호로 엔드포인트를
> 가리키고 있어 그대로 뒀다.

---

## 4. 기기 · 알림

### 4) 기기 등록

`POST /devices`

```json
// Request
{ "device_hash": "d4f8a91c", "push_token": "fcm:...",
  "radius_km": 5, "categories": ["child","elderly"],
  "quiet_hours": { "from": "23:00", "to": "07:00" } }

// 200
{ "ok": true }
```

**알림 반경 설정이 없으면 P4(배달기사)·P5(지역 상점)는 알림을 전부 무음 처리한다.** 하루 수십 건이 오면 서비스가 꺼진다.

---

## 5. 실종자

### 5) 실종자 등록 — S7

`POST /missing` (multipart/form-data) · **토큰 필수**

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `name` | string | O | |
| `age` | int | O | |
| `gender` | enum | O | `male` \| `female` \| `other` |
| `category` | enum | O | `child` \| `elderly` \| `other` — 긴급도 취약도 가중치 |
| `description` | string | O | 인상착의 + 습관 |
| `last_lat` / `last_lng` | float | O | |
| `last_address` | string | X | 미전송 시 서버 역지오코딩 |
| `missing_at` | datetime | O | 실종 일시 |
| `height_cm` / `weight_kg` | int | X | |
| `photos[]` | file[] | O | **다중**. 첫 장이 대표 |

```json
// 201
{
  "id": "m_ab12cd34",
  "name": "김하준",
  "photos": ["/uploads/m_ab12_1.jpg", "/uploads/m_ab12_2.jpg"],
  "face_encoding_count": 2,
  "notified_devices": 1284
}
```

```json
// 400 — 모든 사진에서 얼굴 미검출
{ "error": { "code": "FACE_NOT_FOUND",
  "message": "사진에서 얼굴을 찾지 못했습니다. 얼굴이 잘 보이는 사진을 한 장 이상 올려주세요.",
  "field": "photos" } }
```

**백엔드 현황**: 단일 `photo`, `name`/`description`/`last_lat`/`last_lng`만 존재.
**변경점**: 사진 다중화(벡터 배열 저장), 필드 6개 추가, 등록 후 반경 알림 발송.

> 사진이 여러 장이면 `face_encodings` 배열에 전부 저장하고, 제보 대조 시 **최고 유사도를 채택**한다. 정면·측면·전신을 함께 올리면 정확도가 올라간다.

### 6) 실종자 목록 — S1·S2·S5

`GET /missing`

| 쿼리 | 기본 | 설명 |
|---|---|---|
| `q` | — | 이름·지역 검색 |
| `category` | all | `child` \| `elderly` \| `other` |
| `status` | active | `active` \| `resolved` \| `all` |
| `sort` | urgency | `urgency` \| `recent` \| `distance` |
| `lat` / `lng` | — | 거리 계산·긴급도용 |
| `radius_km` | — | 지도 뷰포트 필터 |
| `limit` / `cursor` | 20 | |

```json
// 200
{
  "count": 14,
  "next_cursor": "eyJvIjoyMH0",
  "items": [
    {
      "id": "m_ab12cd34",
      "name": "김하준", "age": 7, "gender": "male", "category": "child",
      "description": "노란 후드티, 검정 백팩, 파란 운동화",
      "thumbnail": "/uploads/m_ab12_1_thumb.jpg",
      "last_lat": 37.4491, "last_lng": 126.7312,
      "last_address": "인천 남동구 구월동 로데오거리",
      "missing_at": "2026-09-11T14:40:00+09:00",
      "elapsed_minutes": 192,
      "status": "active",
      "report_count": 6,
      "distance_km": 1.2,
      "urgency_score": 9.0,
      "urgency_level": "critical"
    }
  ]
}
```

| 필드 | 용도 |
|---|---|
| `elapsed_minutes` | **서버 계산**. 클라이언트가 자체 계산하면 기기 시각 오차로 틀어진다 |
| `urgency_level` | `critical`(3h↓) / `high`(12h↓) / `normal` / `resolved` — 뱃지 색 결정 |
| `distance_km` | `lat`/`lng` 전달 시에만 |

**백엔드 현황**: 전체 목록만 반환.
**변경점**: 검색·필터·정렬·거리·페이지네이션·긴급도 전면 추가.

### 7) 실종자 상세 — S3

`GET /missing/{id}`

```json
{
  "id": "m_ab12cd34",
  "name": "김하준", "age": 7, "gender": "male", "category": "child",
  "description": "노란 후드티, 검정 백팩, 파란 운동화. 말수가 적고 버스·간판에 관심을 보이면 오래 서 있습니다.",
  "height_cm": 122, "weight_kg": 24,
  "photos": ["/uploads/m_ab12_1.jpg", "..."],
  "last_lat": 37.4491, "last_lng": 126.7312,
  "last_address": "인천 남동구 구월동 로데오거리",
  "last_place_detail": "학원 차량 승차 지점",
  "missing_at": "2026-09-11T14:40:00+09:00",
  "elapsed_minutes": 192,
  "status": "active",
  "report_count": 6,
  "match_count": 3,
  "is_guardian": false,
  "boost_available": false
}
```

`is_guardian` — 보호자 전용 UI(수정·발견완료·제보 관리) 노출 판단.

### 8) 정보 수정

`PATCH /missing/{id}` · **보호자만**
수정 가능: `description`, `last_*`, `height_cm`, `weight_kg`
수정 불가: `missing_at`, `name`, `category` (경과 시간·긴급도 조작 방지)

### 9) 사진 추가

`POST /missing/{id}/photos` · **보호자만**

```json
// 200
{ "photos": [...], "face_encoding_count": 3, "reanalyzed_reports": 6 }
```

**사진을 추가하면 기존 제보의 유사도를 전부 재계산하고 `route_index`를 재부여한다.** 뒷모습만 있던 저신뢰 제보가 전신 사진 추가로 경로에 편입될 수 있다.

### 10) 발견 완료

`POST /missing/{id}/resolve` · **보호자만**

```json
// Request
{ "found_at": "2026-09-11T18:05:00+09:00", "note": "만수동 파출소에서 보호 중" }

// 200
{ "status": "resolved", "notified_reporters": 6 }
```

제보자 전원에게 결과 알림을 보낸다. **재참여 동기를 만드는 유일한 지점이다.**

### 11) 긴급도 올리기

`POST /missing/{id}/boost` · **보호자만 · 사건당 1회**

```json
// 200
{ "boost_applied_at": "...", "expires_at": "...", "urgency_score": 13.5 }
// 409
{ "error": { "code": "BOOST_ALREADY_USED" } }
```

### 12) 재등록 템플릿

`GET /missing/{id}/duplicate` · **보호자만 · 종료된 사건만**

```json
{ "prefill": { "name": "이순자", "age": 81, "gender": "female",
  "category": "elderly", "description": "...", "height_cm": 152,
  "photo_ids": ["p_1","p_2"] } }
```

사진 재업로드 없이 기존 사진을 재사용한다. 사용자는 **시간과 위치만 새로 입력**하면 된다.

---

## 6. 제보 (핵심)

> **이 섹션이 백엔드와 가장 크게 다르다.** 현재는 `POST /report` 하나가 업로드·분석·저장을 모두 처리하지만, 디자인상 시민은 **분석 결과를 본 뒤에 제보 여부를 결정**한다. 두 단계로 분리한다.

```
[S4] 사진 선택 → [분석하기] ──► POST /reports/analyze
                                  ↓ analysis_id + similarity
[S4-1] 결과 확인 → [분석 확인] ──► (클라이언트 상태 유지)
[S4] → [제보] ─────────────────► POST /reports { analysis_id, ... }
[S4-2] 완료
```

### 13) 사진 분석 — S4-1 ★

`POST /reports/analyze` (multipart/form-data)

| 필드 | 타입 | 필수 |
|---|---|:---:|
| `missing_id` | string | O |
| `photo` | file | O |

```json
// 200 — 정상
{
  "analysis_id": "an_7x9k2m",
  "similarity": 63.4,
  "grade": "medium",
  "face_found": true,
  "photo_url": "/uploads/tmp/an_7x9k2m.jpg",
  "matched_photo_url": "/uploads/m_ab12_1.jpg",
  "expires_at": "2026-09-11T17:24:00+09:00"
}

// 200 — 얼굴 미검출 (에러 아님)
{
  "analysis_id": "an_7x9k2n",
  "similarity": null,
  "grade": "no_face",
  "face_found": false,
  "photo_url": "/uploads/tmp/an_7x9k2n.jpg",
  "matched_photo_url": null,
  "expires_at": "..."
}
```

| `grade` | 조건 | UI |
|---|---|---|
| `high` | 70% 이상 | 진한 파랑, "높음" |
| `medium` | 40 ~ 70% | 연한 파랑, "보통 · 확인해볼 만합니다" |
| `low` | 40% 미만 | 회색, "낮음" |
| `no_face` | 얼굴 미검출 | 회색, "얼굴 미검출" |

- 임시 사진은 `uploads/tmp/`에 저장, **TTL 10분**
- 확정 제보 시 정식 경로로 이동, 만료 시 삭제
- `matched_photo_url` — 여러 장 중 최고 유사도를 낸 등록 사진. S4-1의 대조 이미지 좌측에 표시

**얼굴 미검출을 에러로 처리하면 안 된다.** 뒷모습·측면·원거리 사진도 위치와 시간만으로 경로 복원에 기여한다.

### 14) 제보 확정 — S4 ★

`POST /reports` (application/json)

```json
// Request
{
  "analysis_id": "an_7x9k2m",
  "lat": 37.4622, "lng": 126.7401,
  "place_name": "만수주공 앞 버스정류장",
  "observed_at": "2026-09-11T17:12:00+09:00"
}

// 201
{
  "id": "r_ef56gh78",
  "missing_id": "m_ab12cd34",
  "similarity": 63.4,
  "grade": "medium",
  "route_index": 4,
  "photo_url": "/uploads/r_ef56gh78.jpg",
  "observed_at": "2026-09-11T17:12:00+09:00",
  "created_at": "2026-09-11T17:14:22+09:00",
  "guardian_notified": true
}
```

| 필드 | 설명 |
|---|---|
| `analysis_id` | 필수. 사진 재업로드 없음 |
| `observed_at` | **목격 시각**. 사진 EXIF 우선, 사용자 수정 가능. 경로 정렬 기준 |
| `created_at` | 서버가 기록하는 전송 시각 |
| `route_index` | 유사도 40% 이상일 때만 부여. 미만이면 `null` |

```json
// 410 — 분석 만료
{ "error": { "code": "ANALYSIS_EXPIRED", "message": "분석 결과가 만료되었습니다. 다시 분석해 주세요." } }

// 429 — 남용 방지
{ "error": { "code": "RATE_LIMITED", "message": "잠시 후 다시 시도해 주세요.",
  "retry_after": 240 } }
```

**게스트 제한**: 사건 1건당 `X-Device-Hash` 기준 10분 내 3회.

**백엔드 현황**: `POST /report`가 `missing_id`, `lat`, `lng`, `photo`를 받아 즉시 저장.
**변경점**: 2단계 분리, `observed_at` 추가, `place_name` 추가, `route_index` 도입, 40% 미만도 저장.

### 15) 제보 목록 / 이동 경로 — S3·S5 ★

`GET /missing/{id}/reports`

| 쿼리 | 기본 | 설명 |
|---|---|---|
| `min_similarity` | 0 | 필터 토글용 (UI 기본 60) |
| `include_low` | true | `false`면 40% 미만 제외 |
| `until` | — | 시간 슬라이더용. 이 시각까지의 제보만 |

```json
{
  "missing_id": "m_ab12cd34",
  "count": 6,
  "hidden_count": 0,
  "origin": {
    "lat": 37.4491, "lng": 126.7312,
    "address": "인천 남동구 구월동 로데오거리",
    "at": "2026-09-11T14:40:00+09:00"
  },
  "reports": [
    {
      "id": "r_01", "route_index": 3,
      "lat": 37.4701, "lng": 126.7512,
      "place_name": "남동구 만수동 버스정류장",
      "observed_at": "2026-09-11T17:12:00+09:00",
      "similarity": 82.1, "grade": "high", "face_found": true,
      "photo_url": "/uploads/r_01.jpg",
      "status": "visible", "confirmed": false,
      "gap_minutes": 42,
      "bearing": "SE", "distance_from_prev_km": 1.4
    },
    {
      "id": "r_04", "route_index": null,
      "similarity": 34.2, "grade": "low",
      "...": "..."
    }
  ],
  "path": [
    { "lat": 37.4491, "lng": 126.7312, "at": "2026-09-11T14:40:00+09:00", "index": 0, "origin": true },
    { "lat": 37.4552, "lng": 126.7380, "at": "2026-09-11T15:05:00+09:00", "index": 1 },
    { "lat": 37.4640, "lng": 126.7455, "at": "2026-09-11T16:30:00+09:00", "index": 2 },
    { "lat": 37.4701, "lng": 126.7512, "at": "2026-09-11T17:12:00+09:00", "index": 3 }
  ],
  "time_range": {
    "from": "2026-09-11T14:40:00+09:00",
    "to": "2026-09-11T17:12:00+09:00",
    "ticks": ["2026-09-11T15:05:00+09:00", "2026-09-11T16:30:00+09:00", "2026-09-11T17:12:00+09:00"]
  }
}
```

| 필드 | 용도 |
|---|---|
| `reports` | **최신순 정렬** (타임라인 표시 순서) |
| `path` | **시간순 정렬**, `route_index` 있는 것만 + 최초 실종 지점 포함. 폴리라인에 그대로 사용 |
| `gap_minutes` | 이전 제보와의 간격. 60분 이상이면 타임라인에 "⋯ N분 공백" 표시 |
| `bearing` / `distance_from_prev_km` | 이동 방향·거리. P2(배회가 잦은 부모)의 방향 판단에 사용 |
| `time_range.ticks` | 시간 슬라이더 눈금 위치 |

**`reports`와 `path`의 정렬 방향이 반대인 것은 의도된 것이다.** 타임라인은 최신이 위, 경로는 시간순이어야 한다.

**백엔드 현황**: `GET /reports/<missing_id>?only_match=1`, `path` 배열 이미 존재.
**변경점**: 경로에 `origin` 포함, `route_index`·`gap_minutes`·`bearing`·`time_range` 추가, `until` 필터.

### 16) 제보 관리

`PATCH /reports/{id}` · **보호자만**

```json
// Request
{ "status": "hidden" }        // 또는 { "confirmed": true }
```

| 값 | 의미 |
|---|---|
| `status: hidden` | 허위·중복 제보 숨김. 경로에서 제외 |
| `confirmed: true` | 보호자가 직접 확인함 체크. 제보 10건 넘어가면 필수 |

### 17) 제보 신고

`POST /reports/{id}/flag` · 게스트 가능

```json
{ "reason": "unrelated" }   // unrelated | offensive | spam
```

동일 제보에 3회 이상 신고 시 자동 숨김 후 운영 검토.

### 18) 내 제보 이력 — S8

`GET /me/reports`

- 토큰 있으면 계정 기준
- 없으면 `X-Device-Hash` 기준 (게스트도 자기 제보는 볼 수 있어야 한다)

```json
{
  "count": 6,
  "items": [
    { "id": "r_01", "missing_name": "김하준",
      "missing_thumbnail": "...", "missing_status": "resolved",
      "similarity": 82.1, "grade": "high",
      "observed_at": "...", "contributed_to_path": true }
  ]
}
```

`contributed_to_path` — 내 제보가 실제 경로에 포함됐는지. 재참여 동기의 핵심 지표.

### 19) 사진 서빙

`GET /uploads/{filename}` → 이미지 파일

썸네일은 `{filename}_thumb.jpg` 규칙. 목록에서 원본을 내려받으면 모바일 데이터가 낭비된다.

---

## 7. 계산 규칙

### 7.1 유사도

```python
# face_recognition 128차원 벡터, 유클리드 거리
distance = face_distance(registered_encodings, report_encoding).min()
similarity = round((1 - distance) * 100, 1)

# 사진이 여러 장이면 최고 유사도 채택
```

| grade | 조건 | route_index |
|---|---|:---:|
| `high` | `similarity >= 70` | 부여 |
| `medium` | `40 <= similarity < 70` | 부여 |
| `low` | `similarity < 40` | `null` |
| `no_face` | 얼굴 미검출 | `null` |

**모든 제보를 저장한다. 임계값은 표시 등급과 경로 포함 여부만 결정한다.**

### 7.2 긴급도

```python
def urgency(case, user_lat=None, user_lng=None):
    h = elapsed_hours(case.missing_at)
    golden   = 3.0 if h < 3 else 2.0 if h < 12 else 1.5 if h < 48 else 1.0
    vuln     = 1.5 if case.category in ("child", "elderly") else 1.0
    dist     = 1.0
    if user_lat:
        km = haversine(case.last_lat, case.last_lng, user_lat, user_lng)
        dist = 2.0 if km <= 3 else 1.3 if km <= 10 else 1.0
    gap      = 1.3 if minutes_since_last_report(case) > 60 else 1.0
    boost    = 1.5 if case.boost_active else 1.0
    return golden * vuln * dist * gap * boost
```

```python
def urgency_level(h):
    return "critical" if h < 3 else "high" if h < 12 else "normal"
```

> MVP에서는 `golden * dist`만으로 시작해도 정렬이 정상 동작한다.

### 7.3 이동 방향

```python
bearing = calculate_bearing(prev.lat, prev.lng, curr.lat, curr.lng)
# 8방위 문자열로 변환: N, NE, E, SE, S, SW, W, NW
distance_from_prev_km = haversine(prev, curr)
```

---

## 8. 실시간 반영

### 방식 A — Firestore (권장, 이미 구축됨)

```js
const q = query(
  collection(db, "reports"),
  where("missing_id", "==", missingId),
  orderBy("observed_at")
);
onSnapshot(q, snap => { /* 타임라인·지도 갱신 */ });
```

`is_match` 필터를 **제거**한다. 저신뢰 제보도 타임라인에 회색으로 표시해야 한다.

### 방식 B — 폴링

`GET /missing/{id}/reports`를 3초 간격 호출. 데모에는 충분하다.

응답 헤더에 `ETag`를 붙이고 `If-None-Match`로 304를 반환하면 부하가 줄어든다.

---

## 9. 구현 우선순위

### 1순위 — 핵심 루프 (데모 필수)

| 엔드포인트 | 비고 |
|---|---|
| `POST /missing` | 필드 확장 + 사진 다중 |
| `GET /missing` | 정렬·거리만이라도 |
| `GET /missing/{id}` | |
| **`POST /reports/analyze`** | **신규. 가장 중요** |
| **`POST /reports`** | 기존 `/report` 분리 |
| `GET /missing/{id}/reports` | `path` + `time_range` |
| `GET /uploads/{filename}` | 기존 유지 |

### 2순위

`POST /auth/*` · `GET /me/reports` · `POST /missing/{id}/resolve` · `POST /devices` · 긴급도 계산

### 3순위

`PATCH /reports/{id}` · `POST /reports/{id}/flag` · `POST /missing/{id}/boost` · `GET /missing/{id}/duplicate` · `POST /missing/{id}/photos`

---

## 부록. 기존 엔드포인트 마이그레이션

| 기존 | 신규 | 처리 |
|---|---|---|
| `POST /missing` | `POST /missing` | 필드 추가, `photo` → `photos[]` |
| `POST /report` | `POST /reports/analyze` + `POST /reports` | **분리** |
| `GET /reports/<id>?only_match=1` | `GET /missing/{id}/reports?min_similarity=60` | 경로·파라미터 변경 |
| `GET /missing` | `GET /missing` | 쿼리 파라미터 추가 |
| `GET /uploads/<filename>` | 동일 | 유지 |

### 하위 호환

해커톤 일정상 기존 경로를 즉시 지우기 어렵다면, 구 경로를 신 경로로 내부 위임하는 얇은 어댑터를 두고 프론트만 신규 경로를 쓰도록 한다.

```python
@app.post("/report")   # deprecated
def legacy_report():
    # analyze + create를 한 번에 수행해 기존 응답 형태로 반환
    ...
```
