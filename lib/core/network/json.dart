/// 손으로 쓰는 `fromJson`에서 반복되는 형변환을 모아둔다.
///
/// 코드 생성을 쓰지 않기로 했으므로(CLAUDE.md 아키텍처) 모델마다 같은 방어 코드를
/// 쓰게 된다. 서버가 `9`를 줄지 `9.0`을 줄지, 선택 필드를 빼고 줄지 `null`로 줄지는
/// 미리 알 수 없어서 양쪽을 다 받아둔다.
library;

String jsonString(Object? value, {String fallback = ''}) {
  return value is String ? value : fallback;
}

String? jsonStringOrNull(Object? value) {
  return value is String && value.isNotEmpty ? value : null;
}

int jsonInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? jsonIntOrNull(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double jsonDouble(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

double? jsonDoubleOrNull(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool jsonBool(Object? value, {bool fallback = false}) {
  return value is bool ? value : fallback;
}

/// ISO 8601 문자열을 읽는다. 서버는 KST 오프셋을 붙여 보낸다(`+09:00`).
DateTime jsonDate(Object? value) {
  return jsonDateOrNull(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

/// 서버로 보낼 시각 문자열. **오프셋을 반드시 붙인다.**
///
/// `DateTime.toIso8601String()`은 로컬 시각에 오프셋을 안 붙이고(`...T20:10:00`),
/// UTC면 `Z`를 붙인다. 둘 다 문제가 있다 — 오프셋이 없으면 서버가 KST라고
/// 넘겨짚고, `Z`는 파이썬 3.11 미만의 `fromisoformat`이 못 읽는다.
/// 목격 시각은 경로 정렬 기준이라(설계 결정 5번) 한 시간 밀리면 순서가 바뀐다.
String isoWithOffset(DateTime time) {
  final local = time.toLocal();
  final offset = local.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final hours = offset.inHours.abs().toString().padLeft(2, '0');
  final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');

  return '${local.toIso8601String()}$sign$hours:$minutes';
}

DateTime? jsonDateOrNull(Object? value) {
  if (value is DateTime) return value;
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

List<String> jsonStringList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList(growable: false);
}

List<Map<String, dynamic>> jsonMapList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .toList(growable: false);
}

Map<String, dynamic>? jsonMapOrNull(Object? value) {
  return value is Map ? value.cast<String, dynamic>() : null;
}
