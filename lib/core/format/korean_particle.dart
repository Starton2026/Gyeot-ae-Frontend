/// 이름 뒤에 붙는 주격 조사. `하준이` · `민수가`.
///
/// 받침이 있으면 `이`, 없으면 `가`다. 고정으로 하나만 쓰면 "민수이 발견되면"
/// 같은 문장이 나오고, 그 한 글자 때문에 안내문 전체가 기계가 쓴 것처럼 읽힌다.
///
/// 한글 음절이 아니면(영문 이름 등) `가`를 쓴다. 한국어 화자가 영문 이름을
/// 읽을 때 대체로 받침 없이 읽는다.
String subjectParticle(String word) {
  return _hasFinalConsonant(word) ? '이' : '가';
}

/// `하준이가` · `민수가`. [word]에 주격 조사를 붙여 돌려준다.
String withSubjectParticle(String word) => '$word${subjectParticle(word)}';

/// 마지막 글자에 받침이 있다.
///
/// 한글 음절은 유니코드에서 `0xAC00 + (초성×588) + (중성×28) + 종성`으로
/// 배열돼 있어서, 28로 나눈 나머지가 곧 종성이다.
bool _hasFinalConsonant(String word) {
  if (word.isEmpty) return false;

  final code = word.runes.last;
  if (code < 0xAC00 || code > 0xD7A3) return false;

  return (code - 0xAC00) % 28 != 0;
}
