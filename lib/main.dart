import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/map/kakao_map_init.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 카카오맵 — env의 KAKAO_MAP_KEY가 있을 때만 초기화한다.
  // 키가 없으면 지도 화면만 동작하지 않고, 앱은 정상 실행된다.
  await initKakaoMapSdk();

  // TODO(firebase): `dart pub global activate flutterfire_cli` 후
  // `flutterfire configure`를 실행하면 lib/firebase_options.dart가 생성됩니다.
  // 그다음 아래 import와 초기화 주석을 풀어주세요. (README의 Firebase 섹션 참고)
  //
  // import 'package:firebase_core/firebase_core.dart';
  // import 'firebase_options.dart';
  //
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  runApp(const ProviderScope(child: GyeotaeApp()));
}
