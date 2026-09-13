import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/format/korean_particle.dart';

void main() {
  group('subjectParticle', () {
    test('받침이 있으면 이', () {
      expect(subjectParticle('하준'), '이');
      expect(subjectParticle('김하준'), '이');
      expect(subjectParticle('정순'), '이');
    });

    test('받침이 없으면 가', () {
      expect(subjectParticle('민수'), '가');
      expect(subjectParticle('영희'), '가');
      expect(subjectParticle('서우'), '가');
    });

    test('한글이 아니면 가', () {
      expect(subjectParticle('Kevin'), '가');
      expect(subjectParticle(''), '가');
    });
  });

  group('withSubjectParticle', () {
    test('이름에 조사를 붙인다', () {
      expect(withSubjectParticle('김하준'), '김하준이');
      expect(withSubjectParticle('박민수'), '박민수가');
    });
  });
}
