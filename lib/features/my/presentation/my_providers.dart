import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/data/auth_session.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../missing/data/missing_case.dart';
import '../data/my_report.dart';
import '../data/my_repository.dart';

/// 내 제보 이력. 로그인 여부와 상관없이 부른다.
///
/// 로그인하면 계정 기준으로 바뀌므로 로그인 상태를 지켜본다. 게스트로 제보한
/// 뒤 로그인하면 그 제보들이 계정으로 옮겨오는데(F-4.2.7), 다시 부르지 않으면
/// 화면은 옛 목록을 들고 있다.
final myReportsProvider = FutureProvider<MyReportList>((ref) async {
  ref.watch(authProvider);

  return ref.watch(myRepositoryProvider).fetchMyReports();
});

/// 내가 등록한 사건. **로그인해야 부른다.**
///
/// 로그아웃 상태에서 부르면 401이라, 아예 부르지 않고 빈 목록을 준다.
/// 게스트에게는 보여줄 사건이라는 개념 자체가 없다 — 등록에는 로그인이
/// 필요하기 때문이다.
final myCasesProvider = FutureProvider<MissingCaseList>((ref) async {
  if (!ref.watch(isSignedInProvider)) return const MissingCaseList.empty();

  return ref.watch(myRepositoryProvider).fetchMyCases();
});

/// 로그인한 사람의 프로필과 건수. 로그아웃 상태면 null이다.
///
/// 등록 사건 수와 제보 수는 서버가 세어 준다. 앱이 세면 화면마다 다른 숫자가
/// 나온다.
final myProfileProvider = FutureProvider<AuthProfile?>((ref) async {
  final signedIn = ref.watch(isSignedInProvider);
  if (!signedIn) return null;

  return ref.watch(authRepositoryProvider).me();
});
