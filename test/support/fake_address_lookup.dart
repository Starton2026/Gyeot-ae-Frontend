import 'package:gyeotae/features/missing/data/address_lookup.dart';

/// 카카오 로컬 API를 부르지 않는 [AddressLookup].
///
/// [address]가 null이면 키가 없거나 조회가 실패한 경우다.
class FakeAddressLookup implements AddressLookup {
  FakeAddressLookup([this.address = '인천 남동구 인하로 501']);

  String? address;

  /// 물어본 좌표를 순서대로.
  final List<({double lat, double lng})> calls = [];

  @override
  Future<String?> addressAt({required double lat, required double lng}) async {
    calls.add((lat: lat, lng: lng));
    return address;
  }
}
