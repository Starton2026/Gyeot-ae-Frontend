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
