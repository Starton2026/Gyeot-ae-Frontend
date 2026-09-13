plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 카카오 로그인 리디렉트 스킴(`kakao{네이티브 앱 키}://oauth`)은 매니페스트에
// 박혀 있어야 하는데, 키는 git에 올리지 않는 env/dev.json에만 있다. 빌드할 때
// 거기서 읽어 끼워 넣는다. 키 파일을 하나로 유지하려는 것이다.
//
// 값이 없으면 스킴이 비어 로그인만 동작하지 않는다. 키를 아직 못 받은 팀원도
// 앱은 빌드하고 실행할 수 있어야 한다.
val kakaoNativeAppKey: String = run {
    val envFile = rootProject.file("../env/dev.json")
    if (!envFile.exists()) return@run ""

    runCatching {
        @Suppress("UNCHECKED_CAST")
        val json = groovy.json.JsonSlurper().parse(envFile) as Map<String, Any?>
        json["KAKAO_MAP_KEY"]?.toString().orEmpty()
    }.getOrDefault("")
}

if (kakaoNativeAppKey.isEmpty()) {
    logger.warn("[곁애] env/dev.json에 KAKAO_MAP_KEY가 없어 카카오 로그인 스킴을 비웁니다.")
}

android {
    namespace = "com.starton.gyeotae"
    compileSdk = flutter.compileSdkVersion
    // 이 앱은 네이티브 코드를 직접 컴파일하지 않아 NDK가 필요 없다.
    // NDK를 요구하는 플러그인을 추가하면 아래 줄의 주석을 풀고
    // Android Studio SDK Manager에서 해당 NDK를 설치한다.
    // ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.starton.gyeotae"
        // firebase_auth가 최소 23을 요구한다.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // AndroidManifest의 ${kakaoAuthScheme}로 들어간다.
        manifestPlaceholders["kakaoAuthScheme"] = "kakao$kakaoNativeAppKey"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")

            // 카카오맵 SDK 클래스가 축소 과정에서 제거되지 않도록 규칙을 적용한다.
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
