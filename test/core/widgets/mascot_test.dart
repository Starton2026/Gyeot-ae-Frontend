import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/widgets/mascot.dart';

void main() {
  testWidgets('MascotPose의 모든 경로가 실제 에셋을 가리킨다', (tester) async {
    for (final pose in MascotPose.values) {
      final data = await rootBundle.load(pose.asset);

      expect(
        data.lengthInBytes,
        greaterThan(0),
        reason: '${pose.asset} 이(가) 비어 있다',
      );
    }
  });
}
