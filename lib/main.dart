import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/map/kakao_map_init.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 카카오맵 — env의 KAKAO_MAP_KEY가 있을 때만 초기화한다.
  // 키가 없으면 지도 화면만 동작하지 않고, 앱은 정상 실행된다.
  //
  // 키는 `--dart-define-from-file=env/dev.json`으로 **컴파일 시점에** 박힌다.
  // 파일만 고치고 핫 리스타트하면 값이 바뀌지 않아서, 여기서 한 번 찍어둔다.
  final mapReady = await initKakaoMapSdk();
  debugPrint(
    mapReady
        ? '카카오맵 SDK 초기화 완료'
        : '카카오맵 키가 비어 있어 지도 초기화를 건너뜁니다. '
              '--dart-define-from-file=env/dev.json 으로 실행했는지 확인하세요.',
  );

  // 카카오 로그인 — 지도와 같은 네이티브 앱 키다. 키가 없으면 초기화하지
  // 않는다. 로그인 시트의 버튼만 동작하지 않고 앱은 그대로 돈다.
  if (Env.kakaoNativeAppKey.isNotEmpty) {
    await KakaoSdk.init(nativeAppKey: Env.kakaoNativeAppKey);
  }

  // Firebase — 푸시 알림(FCM)에 쓴다. 설정은 `flutterfire configure`가 만든
  // lib/firebase_options.dart에 있고, 그 파일은 .gitignore에 걸려 있어서
  // 새 PC에서는 한 번 다시 돌려야 한다(README의 Firebase 섹션).
  //
  // **초기화에 실패해도 앱은 뜬다.** 알림을 못 받는 것과 앱이 안 켜지는 것은
  // 무게가 다르다. 이때는 SilentPushMessaging이 대신 물린다.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on Object catch (error) {
    debugPrint('Firebase 초기화 실패 — 푸시 알림 없이 계속합니다: $error');
  }

  runApp(const ProviderScope(child: GyeotaeApp()));
}
