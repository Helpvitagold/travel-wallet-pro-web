import java.util.Properties

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.reader(Charsets.UTF_8).use { reader ->
        localProperties.load(reader)
    }
}

val flutterRoot = localProperties.getProperty("flutter.sdk")
if (flutterRoot == null) {
    throw GradleException("Flutter SDK not found. Define flutter.sdk in local.properties.")
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"

plugins {
    id("com.android.application")
    id("kotlin-android")
    // ✨ Firebase 플러그인
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.my_currency_app"
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    // ✨ Deprecated 해결: compilerOptions DSL 사용
    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.my_currency_app"
        minSdk = flutter.minSdkVersion 
        targetSdk = flutter.targetSdkVersion
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✨ 에러 지점: 변수 참조 에러 해결을 위해 표준 라이브러리 선언 방식 수정 또는 제거
    // 최신 Flutter는 이 줄이 없어도 동작하지만, 필요하다면 아래와 같이 직접 버전을 명시합니다.
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.0") 
    
    // ✨ Firebase SDK
    implementation(platform("com.google.firebase:firebase-bom:34.8.0"))
    implementation("com.google.firebase:firebase-analytics")
}
