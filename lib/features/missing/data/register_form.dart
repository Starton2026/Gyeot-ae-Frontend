import '../../../core/network/json.dart';
import 'missing_case.dart';

/// 등록 폼(S7)의 칸. **선언 순서가 화면 순서다.**
///
/// 등록하기를 눌렀는데 빠진 칸이 있으면 첫 번째 칸으로 스크롤한다. 순서가
/// 화면과 어긋나면 엉뚱한 칸으로 튄다.
enum RegisterField {
  photos('사진을 한 장 이상 올려 주세요'),
  name('이름을 입력해 주세요'),
  // 나이 칸은 성별과 반씩 나눠 쓴다. 길면 잘린다.
  age('나이를 확인해 주세요'),
  gender('성별을 골라 주세요'),
  category('구분을 골라 주세요'),
  description('인상착의를 입력해 주세요'),
  location('마지막 목격 위치를 골라 주세요'),
  missingAt('실종 일시를 확인해 주세요');

  const RegisterField(this.message);

  /// 칸 아래에 적는 안내.
  final String message;

  /// 서버 오류의 `field`(API 명세서 1절)를 폼의 칸으로. 모르는 이름이면 null.
  static RegisterField? fromServer(String? field) {
    return switch (field) {
      'photos' || 'photo' => RegisterField.photos,
      'name' => RegisterField.name,
      'age' => RegisterField.age,
      'gender' => RegisterField.gender,
      'category' => RegisterField.category,
      'description' => RegisterField.description,
      'last_lat' || 'last_lng' => RegisterField.location,
      'missing_at' => RegisterField.missingAt,
      _ => null,
    };
  }
}

/// 등록 폼에 적힌 값 그대로.
///
/// 나이·키·몸무게는 **적은 글자 그대로** 둔다. 숫자로 바꿔 쥐면 "7"을 지우는
/// 도중의 빈 칸이나 잘못 친 글자를 담을 자리가 없다. 숫자는 보낼 때 만든다.
///
/// 임시저장(F-7.11)도 이 값을 그대로 적어 둔다.
class RegisterForm {
  const RegisterForm({
    required this.missingAt,
    this.photoPaths = const [],
    this.name = '',
    this.age = '',
    this.gender,
    this.category,
    this.description = '',
    this.lat,
    this.lng,
    this.locationPicked = false,
    this.address = '',
    this.height = '',
    this.weight = '',
  });

  /// 올릴 사진의 로컬 경로. 첫 장이 대표다.
  final List<String> photoPaths;

  final String name;
  final String age;
  final Gender? gender;
  final MissingCategory? category;

  /// 인상착의. 복장과 함께 습관·자주 가는 곳(F-7.6).
  final String description;

  /// 마지막 목격 위치. 아직 모르면 둘 다 null이다.
  final double? lat;
  final double? lng;

  /// 보호자가 지도에서 고르거나 주소를 직접 적었다. false면 기기 위치가
  /// 저절로 들어간 것이다.
  final bool locationPicked;

  /// 사람이 읽는 주소. 비워도 된다.
  final String address;

  final DateTime missingAt;

  /// 키·몸무게(F-7.9). 선택이다.
  final String height;
  final String weight;

  bool get hasLocation => lat != null && lng != null;

  /// 나가면 사라지는 것이 있다. 닫을 때 한 번 물을지 정한다.
  ///
  /// 기기 위치와 그 주소가 저절로 채워진 것은 치지 않는다. 아무것도 안
  /// 했는데 "쓰던 내용이 사라집니다"라고 물으면 거짓말이다. 보호자가 위치나
  /// 주소를 손대면 [locationPicked]가 선다.
  bool get hasInput =>
      photoPaths.isNotEmpty ||
      name.trim().isNotEmpty ||
      age.trim().isNotEmpty ||
      gender != null ||
      category != null ||
      description.trim().isNotEmpty ||
      locationPicked ||
      height.trim().isNotEmpty ||
      weight.trim().isNotEmpty;

  int? get _ageNumber {
    final value = int.tryParse(age.trim());

    return value != null && value >= 0 && value <= 130 ? value : null;
  }

  /// 채우지 않았거나 잘못 채운 필수 칸. 화면 순서대로.
  List<RegisterField> get invalidFields => [
    if (photoPaths.isEmpty) RegisterField.photos,
    if (name.trim().isEmpty) RegisterField.name,
    if (_ageNumber == null) RegisterField.age,
    if (gender == null) RegisterField.gender,
    if (category == null) RegisterField.category,
    if (description.trim().isEmpty) RegisterField.description,
    if (!hasLocation) RegisterField.location,
  ];

  /// 서버로 보낼 값. **빠진 칸이 있으면 만들지 않는다**([StateError]).
  MissingCaseDraft toDraft() {
    if (invalidFields.isNotEmpty) {
      throw StateError('채우지 않은 칸이 있다: $invalidFields');
    }

    final trimmedAddress = address.trim();

    return MissingCaseDraft(
      name: name.trim(),
      age: _ageNumber!,
      gender: gender!,
      category: category!,
      description: description.trim(),
      lastLat: lat!,
      lastLng: lng!,
      lastAddress: trimmedAddress.isEmpty ? null : trimmedAddress,
      missingAt: missingAt,
      photoPaths: photoPaths,
      heightCm: int.tryParse(height.trim()),
      weightKg: int.tryParse(weight.trim()),
    );
  }

  RegisterForm copyWith({
    List<String>? photoPaths,
    String? name,
    String? age,
    Gender? gender,
    MissingCategory? category,
    String? description,
    double? lat,
    double? lng,
    bool? locationPicked,
    String? address,
    DateTime? missingAt,
    String? height,
    String? weight,
  }) {
    return RegisterForm(
      photoPaths: photoPaths ?? this.photoPaths,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      category: category ?? this.category,
      description: description ?? this.description,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      locationPicked: locationPicked ?? this.locationPicked,
      address: address ?? this.address,
      missingAt: missingAt ?? this.missingAt,
      height: height ?? this.height,
      weight: weight ?? this.weight,
    );
  }

  /// 기기에 적어 두는 모양. 서버 형식과 상관없다.
  Map<String, dynamic> toJson() => {
    'photo_paths': photoPaths,
    'name': name,
    'age': age,
    'gender': gender?.wire,
    'category': category?.wire,
    'description': description,
    'lat': lat,
    'lng': lng,
    'location_picked': locationPicked,
    'address': address,
    // 기기 안에서만 도는 값이라 오프셋 없이 로컬 시각 그대로 적는다.
    'missing_at': missingAt.toIso8601String(),
    'height': height,
    'weight': weight,
  };

  factory RegisterForm.fromJson(Map<String, dynamic> json) {
    final gender = json['gender'];
    final category = json['category'];

    return RegisterForm(
      photoPaths: jsonStringList(json['photo_paths']),
      name: jsonString(json['name']),
      age: jsonString(json['age']),
      gender: gender == null ? null : Gender.fromJson(gender),
      category: category == null ? null : MissingCategory.fromJson(category),
      description: jsonString(json['description']),
      lat: jsonDoubleOrNull(json['lat']),
      lng: jsonDoubleOrNull(json['lng']),
      locationPicked: jsonBool(json['location_picked']),
      address: jsonString(json['address']),
      missingAt: jsonDateOrNull(json['missing_at']) ?? DateTime.now(),
      height: jsonString(json['height']),
      weight: jsonString(json['weight']),
    );
  }
}
