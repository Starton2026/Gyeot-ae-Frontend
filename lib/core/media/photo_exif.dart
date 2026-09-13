import 'dart:io';

import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';

import '../location/location_source.dart';

/// 사진 자체에 박혀 있는 사실. 둘 다 없을 수 있다.
typedef PhotoFacts = ({DateTime? takenAt, LocationFix? fix});

const PhotoFacts emptyPhotoFacts = (takenAt: null, fix: null);

/// 사진 파일에서 촬영 시각과 좌표를 읽는다.
///
/// **앨범에서 고른 사진은 지금 여기서 찍은 것이 아니다.** 어제 다른 동네에서
/// 찍었을 수 있고, 그때는 기기의 현재 위치를 붙이면 거짓 목격 지점이 된다.
/// 사진에 박힌 값이 있으면 그쪽이 사실에 가깝다.
///
/// 읽지 못하면 조용히 빈 값을 준다. EXIF가 없는 사진은 흔하다 — 화면 캡처,
/// 메신저로 받은 사진, 위치를 꺼두고 찍은 사진.
Future<PhotoFacts> readPhotoFacts(File file) async {
  try {
    return photoFactsFromExif(await readExifFromFile(file));
  } catch (error) {
    debugPrint('EXIF를 읽지 못했습니다: $error');
    return emptyPhotoFacts;
  }
}

/// EXIF 태그 묶음에서 쓸 만한 값만 꺼낸다.
///
/// 파일 읽기와 떼어놔야 태그 조합별로 테스트할 수 있다.
PhotoFacts photoFactsFromExif(Map<String, IfdTag> tags) {
  return (takenAt: _takenAt(tags), fix: _fix(tags));
}

/// `EXIF DateTimeOriginal`은 `2026:09:13 17:12:03` 모양이다.
///
/// 시간대가 없어서 기기의 지역 시각으로 읽는다. 사진을 찍은 곳과 올리는 곳의
/// 시간대가 다르면 어긋나지만, 목격 시각은 사용자가 고칠 수 있다.
DateTime? _takenAt(Map<String, IfdTag> tags) {
  final raw = tags['EXIF DateTimeOriginal']?.printable ??
      tags['Image DateTime']?.printable;
  if (raw == null) return null;

  final match = RegExp(
    r'^(\d{4}):(\d{2}):(\d{2})[ T](\d{2}):(\d{2}):(\d{2})',
  ).firstMatch(raw.trim());
  if (match == null) return null;

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);

  // `0000:00:00 00:00:00`으로 채워진 사진이 흔하다. 그대로 넘기면 Dart가
  // 기원전 날짜로 정규화해서, 말이 되는 시각인 척한다.
  if (year < 1990 || month < 1 || month > 12 || day < 1 || day > 31) {
    return null;
  }

  final taken = DateTime(
    year,
    month,
    day,
    int.parse(match.group(4)!),
    int.parse(match.group(5)!),
    int.parse(match.group(6)!),
  );

  // 앞으로의 시각은 목격 시각이 될 수 없다. 기기 시계가 틀어진 사진이다.
  return taken.isAfter(DateTime.now()) ? null : taken;
}

LocationFix? _fix(Map<String, IfdTag> tags) {
  final lat = _degrees(tags['GPS GPSLatitude'], tags['GPS GPSLatitudeRef']);
  final lng = _degrees(tags['GPS GPSLongitude'], tags['GPS GPSLongitudeRef']);
  if (lat == null || lng == null) return null;

  if (lat.abs() > 90 || lng.abs() > 180) return null;

  // 0,0은 기니만 앞바다다. 좌표를 못 잡은 사진이 이 값으로 남는 일이 많다.
  if (lat == 0 && lng == 0) return null;

  return (lat: lat, lng: lng);
}

/// `[37/1, 27/1, 5436/100]` + `N` → 37.4515.
double? _degrees(IfdTag? value, IfdTag? reference) {
  final parts = value?.values;
  if (parts is! IfdRatios || parts.ratios.length < 2) return null;

  final ratios = parts.ratios;
  final degrees = ratios[0].toDouble() +
      ratios[1].toDouble() / 60 +
      (ratios.length > 2 ? ratios[2].toDouble() / 3600 : 0);

  final sign = switch (reference?.printable.trim().toUpperCase()) {
    'S' || 'W' => -1,
    _ => 1,
  };

  return degrees * sign;
}
