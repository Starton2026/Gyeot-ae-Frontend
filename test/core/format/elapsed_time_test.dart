import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/format/elapsed_time.dart';

void main() {
  group('ElapsedTime.fromMinutes', () {
    test('한 시간이 안 되면 분만 남는다', () {
      final elapsed = ElapsedTime.fromMinutes(45);

      expect(elapsed.days, 0);
      expect(elapsed.hours, 0);
      expect(elapsed.minutes, 45);
    });

    test('24시간이 안 되면 시간과 분으로 쪼갠다', () {
      final elapsed = ElapsedTime.fromMinutes(192);

      expect(elapsed.days, 0);
      expect(elapsed.hours, 3);
      expect(elapsed.minutes, 12);
    });

    test('24시간이 넘으면 일과 시간으로 쪼갠다', () {
      final elapsed = ElapsedTime.fromMinutes(2 * 1440 + 5 * 60 + 30);

      expect(elapsed.days, 2);
      expect(elapsed.hours, 5);
      expect(elapsed.minutes, 30);
    });

    test('음수가 와도 0으로 본다', () {
      expect(ElapsedTime.fromMinutes(-10).label, '0분');
    });
  });

  group('label — 기능정의서 5.3', () {
    test('24시간 미만은 "3시간 12분"', () {
      expect(ElapsedTime.fromMinutes(192).label, '3시간 12분');
    });

    test('24시간 이상은 "2일 5시간" — 분은 버린다', () {
      expect(ElapsedTime.fromMinutes(2 * 1440 + 5 * 60 + 30).label, '2일 5시간');
    });

    test('딱 떨어지면 뒤 칸을 적지 않는다', () {
      expect(ElapsedTime.fromMinutes(180).label, '3시간');
      expect(ElapsedTime.fromMinutes(1440).label, '1일');
      expect(ElapsedTime.fromMinutes(0).label, '0분');
    });
  });

  group('shortLabel — 뱃지용 한 칸', () {
    test('가장 큰 단위 하나만 남는다', () {
      expect(ElapsedTime.fromMinutes(192).shortLabel, '3시간');
      expect(ElapsedTime.fromMinutes(2 * 1440 + 5 * 60).shortLabel, '2일');
      expect(ElapsedTime.fromMinutes(45).shortLabel, '45분');
    });
  });

  group('parts — 큰 숫자로 끊어 읽는 칸', () {
    test('숫자와 단위가 분리돼 나온다', () {
      final parts = ElapsedTime.fromMinutes(192).parts;

      expect(parts, hasLength(2));
      expect(parts.first.value, 3);
      expect(parts.first.unit, '시간');
      expect(parts.last.value, 12);
      expect(parts.last.unit, '분');
    });

    test('뒤 칸이 0이면 칸 자체가 없다', () {
      expect(ElapsedTime.fromMinutes(180).parts, hasLength(1));
      expect(ElapsedTime.fromMinutes(1440).parts, hasLength(1));
    });
  });
}
