import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/format/time_label.dart';

void main() {
  test('오후 시각은 12를 빼고 "오후 2시 40분"으로 읽는다', () {
    expect(koreanTimeLabel(DateTime(2026, 9, 12, 14, 40)), '오후 2시 40분');
  });

  test('오전 시각은 그대로 읽는다', () {
    expect(koreanTimeLabel(DateTime(2026, 9, 12, 9, 5)), '오전 9시 5분');
  });

  test('자정과 정오는 12시로 읽는다', () {
    expect(koreanTimeLabel(DateTime(2026, 9, 12, 0, 30)), '오전 12시 30분');
    expect(koreanTimeLabel(DateTime(2026, 9, 12, 12, 30)), '오후 12시 30분');
  });

  test('0분이면 분을 적지 않는다', () {
    expect(koreanTimeLabel(DateTime(2026, 9, 12, 14, 0)), '오후 2시');
  });

  group('koreanDateLabel', () {
    final now = DateTime(2026, 9, 12, 16, 0);

    test('같은 날이면 "오늘"', () {
      expect(koreanDateLabel(DateTime(2026, 9, 12, 2, 5), now: now), '오늘');
    });

    test('하루 전이면 "어제"', () {
      expect(koreanDateLabel(DateTime(2026, 9, 11, 23, 59), now: now), '어제');
    });

    test('그보다 오래되면 월일로 적는다', () {
      expect(koreanDateLabel(DateTime(2026, 9, 9, 18, 0), now: now), '9월 9일');
    });

    test('시각이 아니라 날짜로 가른다', () {
      // 자정 직후는 몇 시간 전이어도 "오늘"이 아니다.
      expect(koreanDateLabel(DateTime(2026, 9, 11, 22, 0), now: now), '어제');
    });
  });

  test('relative를 끄면 오늘도 월일로 적는다', () {
    final now = DateTime(2026, 9, 12, 16, 0);

    expect(
      koreanDateLabel(DateTime(2026, 9, 12, 14, 40), now: now, relative: false),
      '9월 12일',
    );
    expect(
      koreanDateTimeLabel(
        DateTime(2026, 9, 12, 14, 40),
        now: now,
        relative: false,
      ),
      '9월 12일 오후 2시 40분',
    );
  });

  group('koreanDateTimeLabel', () {
    final now = DateTime(2026, 9, 12, 16, 0);

    test('날짜와 시각을 이어 붙인다', () {
      expect(
        koreanDateTimeLabel(DateTime(2026, 9, 12, 14, 40), now: now),
        '오늘 오후 2시 40분',
      );
      expect(
        koreanDateTimeLabel(DateTime(2026, 9, 9, 18, 0), now: now),
        '9월 9일 오후 6시',
      );
    });
  });
}
