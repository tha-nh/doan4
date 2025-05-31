plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.esavior_doctor"
    compileSdk = 35 // ✅ hoặc cao hơn

    ndkVersion = "27.0.12077973" // ✅ theo yêu cầu từ lỗi bạn dán


    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Bật core library desugaring
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.esavior_doctor"
        minSdk = flutter.minSdkVersion
        targetSdk = 35 // ✅ Đặt cố định là 33 hoặc cao hơn

        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Bật MultiDex
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    testOptions {
        unitTests.all {
            it.enabled = false // Disable all unit tests
        }
    }
}

dependencies {
    // Thêm dependency cho core library desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Thêm dependency cho MultiDex
    implementation("androidx.multidex:multidex:2.0.1")
    implementation(platform("com.google.firebase:firebase-bom:33.14.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation ("androidx.work:work-runtime-ktx:2.8.1")


}


flutter {
    source = "../.."
}