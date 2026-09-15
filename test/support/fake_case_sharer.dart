import 'package:gyeotae/core/share/case_sharer.dart';

/// 카카오톡을 띄우지 않고 받은 카드만 적어 두는 [CaseSharer].
class FakeCaseSharer implements CaseSharer {
  FakeCaseSharer({this.result = ShareResult.opened});

  ShareResult result;

  final List<CaseShareCard> cards = [];

  @override
  Future<ShareResult> share(CaseShareCard card) async {
    cards.add(card);

    return result;
  }
}
