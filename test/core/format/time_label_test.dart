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
}
