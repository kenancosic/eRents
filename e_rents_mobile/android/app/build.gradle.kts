plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    ndkVersion = "27.0.12077973"
    namespace = "com.erents.e_rents_mobile"
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.erents.e_rents_mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Signing with the debug keys for now, so `flutter run --release` works.
            // TODO: Add your own signing config for production release.
            signingConfig = signingConfigs.getByName("debug")
            
            // Enable ProGuard/R8 for release builds
            isMinifyEnabled = true
            isShrinkResources = true
            isDebuggable = false
            
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

// Copy APK to Flutter's expected location after release build
tasks.whenTaskAdded {
    if (name == "assembleRelease") {
        doLast {
            val sourceApk = file("${buildDir}/outputs/apk/release/app-release.apk")
            val sourceMetadata = file("${buildDir}/outputs/apk/release/output-metadata.json")
            val targetDir = file("${rootProject.projectDir}/../build/app/outputs/flutter-apk")
            
            if (sourceApk.exists()) {
                targetDir.mkdirs()
                sourceApk.copyTo(file("${targetDir}/app-release.apk"), overwrite = true)
                if (sourceMetadata.exists()) {
                    sourceMetadata.copyTo(file("${targetDir}/output-metadata.json"), overwrite = true)
                }
                println("APK copied to: ${targetDir}/app-release.apk")
            }
        }
    }
    if (name == "assembleDebug") {
        doLast {
            val sourceApk = file("${buildDir}/outputs/apk/debug/app-debug.apk")
            val sourceMetadata = file("${buildDir}/outputs/apk/debug/output-metadata.json")
            val targetDir = file("${rootProject.projectDir}/../build/app/outputs/flutter-apk")
            
            if (sourceApk.exists()) {
                targetDir.mkdirs()
                sourceApk.copyTo(file("${targetDir}/app-debug.apk"), overwrite = true)
                if (sourceMetadata.exists()) {
                    sourceMetadata.copyTo(file("${targetDir}/output-metadata.json"), overwrite = true)
                }
                println("Debug APK copied to: ${targetDir}/app-debug.apk")
            }
        }
    }
}
