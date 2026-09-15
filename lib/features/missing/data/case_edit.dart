/// 보호자가 고칠 수 있는 사건 정보. API 명세서 8) `PATCH /missing/{id}`.
///
/// **이름·나이·성별·구분·실종 일시는 없다.** 서버가 막는 칸이다 — 이 값이
/// 바뀌면 경과 시간과 긴급도를 조작할 수 있다. 칸이 없으니 보낼 수도 없다.
///
/// 폼 전체를 늘 함께 보낸다. 키·몸무게를 비우면 null로 보내 지운다.
class CaseEdit {
  const CaseEdit({
    required this.description,
    required this.lastLat,
    required this.lastLng,
    this.lastAddress,
    this.heightCm,
    this.weightKg,
  });

  final String description;
  final double lastLat;
  final double lastLng;
  final String? lastAddress;
  final int? heightCm;
  final int? weightKg;

  Map<String, dynamic> toJson() {
    final address = lastAddress?.trim();

    return {
      'description': description.trim(),
      'last_lat': lastLat,
      'last_lng': lastLng,
      'last_address': address == null || address.isEmpty ? null : address,
      'height_cm': heightCm,
      'weight_kg': weightKg,
    };
  }
}

/// 사진 추가 결과. API 명세서 9).
///
/// [reanalyzedReports]는 유사도를 다시 계산한 제보 수다. 보호자에게 "사진을
/// 넣었더니 무엇이 달라졌는지" 알려주는 숫자다.
typedef PhotoAddResult = ({int photoCount, int reanalyzedReports});
