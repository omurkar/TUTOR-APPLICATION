plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.nextsolves.tutor.tutor_app"

    // Use SDK 35 (Android 15)
    compileSdk = 35
    buildToolsVersion = "35.0.0"

    ndkVersion = flutter.ndkVersion

    compileOptions {
        // FIXED: Enabled core library desugaring for local notifications plugin
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.nextsolves.tutor.tutor_app"
        minSdk = flutter.minSdkVersion 
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

// FORCE STABLE VERSIONS TO AVOID SDK 36 ERRORS
configurations.all {
    resolutionStrategy {
        force("androidx.activity:activity:1.9.3")
        force("androidx.activity:activity-ktx:1.9.3")
        force("androidx.core:core:1.15.0")
        force("androidx.core:core-ktx:1.15.0")
        force("androidx.lifecycle:lifecycle-common:2.8.7")
        force("androidx.lifecycle:lifecycle-runtime:2.8.7")
        force("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    }
}

flutter {
    source = "../.."
}

dependencies {
    // REQUIRED for core library desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
