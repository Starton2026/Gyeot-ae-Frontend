import 'package:exif/exif.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/media/photo_exif.dart';

IfdTag _ratios(List<(int, int)> parts) {
  return IfdTag(
    tag: 0,
    tagType: 'Ratio',
    printable: '',
    values: IfdRatios([
      for (final (numerator, denominator) in parts)
        Ratio(numerator, denominator),
    ]),
  );
}

IfdTag _text(String value) {
  return IfdTag(
    tag: 0,
    tagType: 'ASCII',
    printable: value,
    values: const IfdNone(),
  );
}

/// 인천 남동구 만수동 언저리. 37°28'12" N, 126°45'12" E.
Map<String, IfdTag> _gps({String latRef = 'N', String lngRef = 'E'}) {
  return {
    'GPS GPSLatitude': _ratios([(37, 1), (28, 1), (12, 1)]),
    'GPS GPSLatitudeRef': _text(latRef),
    'GPS GPSLongitude': _ratios([(126, 1), (45, 1), (12, 1)]),
    'GPS GPSLongitudeRef': _text(lngRef),
  };
}

void main() {
  group('촬영 좌표', () {
    test('도·분·초를 도 단위로 바꾼다', () {
      final fix = photoFactsFromExif(_gps()).fix;

      expect(fix, isNotNull);
      expect(fix!.lat, closeTo(37.47, 0.001));
      expect(fix.lng, closeTo(126.7533, 0.001));
    });

    test('남위·서경은 음수다', () {
      final fix = photoFactsFromExif(_gps(latRef: 'S', lngRef: 'W')).fix;

      expect(fix!.lat, closeTo(-37.47, 0.001));
      expect(fix.lng, closeTo(-126.7533, 0.001));
    });

    test('한쪽만 있으면 쓰지 않는다', () {
      final tags = _gps()..remove('GPS GPSLongitude');

      expect(photoFactsFromExif(tags).fix, isNull);
    });

    test('0, 0은 좌표를 못 잡은 사진이다', () {
      final fix = photoFactsFromExif({
        'GPS GPSLatitude': _ratios([(0, 1), (0, 1), (0, 1)]),
        'GPS GPSLatitudeRef': _text('N'),
        'GPS GPSLongitude': _ratios([(0, 1), (0, 1), (0, 1)]),
        'GPS GPSLongitudeRef': _text('E'),
      }).fix;

      expect(fix, isNull, reason: '기니만 앞바다에 목격 지점이 찍힌다');
    });

    test('EXIF가 없는 사진도 정상이다', () {
      expect(photoFactsFromExif(const {}), emptyPhotoFacts);
    });
  });

  group('촬영 시각', () {
    test('EXIF 표기를 읽는다', () {
      final facts = photoFactsFromExif({
        'EXIF DateTimeOriginal': _text('2026:09:12 17:12:03'),
      });

      expect(facts.takenAt, DateTime(2026, 9, 12, 17, 12, 3));
    });

    test('DateTimeOriginal이 없으면 Image DateTime을 쓴다', () {
      final facts = photoFactsFromExif({
        'Image DateTime': _text('2026:09:12 09:05:00'),
      });

      expect(facts.takenAt, DateTime(2026, 9, 12, 9, 5));
    });

    test('앞으로의 시각은 버린다', () {
      final next = DateTime.now().add(const Duration(days: 2));
      final stamp =
          '${next.year}:${next.month.toString().padLeft(2, '0')}:'
          '${next.day.toString().padLeft(2, '0')} 12:00:00';

      final facts = photoFactsFromExif({'EXIF DateTimeOriginal': _text(stamp)});

      expect(facts.takenAt, isNull, reason: '기기 시계가 틀어진 사진이다');
    });

    test('알아볼 수 없는 표기는 버린다', () {
      final facts = photoFactsFromExif({
        'EXIF DateTimeOriginal': _text('0000:00:00 00:00:00'),
      });

      expect(facts.takenAt, isNull);
    });
  });
}
