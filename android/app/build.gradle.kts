plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.bili_ownx"
    compileSdk = 35
    ndkVersion = "27.0.12077973"
    
    // 启用核心库脱糖以支持 Java 8+ 特性
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }
    
    // 为 Kotlin 编译也启用相同配置
    kotlinOptions {
        jvmTarget = "1.8"
    }
    
    // 解决 AAR 元数据冲突
    dependenciesInfo {
        // 禁用依赖元数据检查以避免冲突
        includeInApk = false
        includeInBundle = false
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.bili_ownx"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // 启用代码压缩
            isMinifyEnabled = true
            // 启用资源压缩
            isShrinkResources = true
            
            // 启用 R8 完全优化
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            signingConfig = signingConfigs.getByName("debug")
        }
        
        debug {
            // 为debug构建也启用基本优化以减小APK大小
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
    
    // 移除ABI分割配置以确保生成通用APK
    
    packaging {
        resources {
            excludes += listOf(
                "META-INF/*.kotlin_module",
                "META-INF/LICENSE.md",
                "META-INF/LICENSE-notice.md",
                "META-INF/AL2.0",
                "META-INF/LGPL2.1",
                "META-INF/NOTICE.md",
                "META-INF/DEPENDENCIES",
                "META-INF/gradle/incremental.annotation.processors",
                "META-INF/*.properties",
                "META-INF/proguard/*",
                "META-INF/com.android.tools/annotations"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 核心库脱糖支持 - 解决 flutter_local_notifications 兼容性问题
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

// 解决依赖版本冲突
configurations.all {
    resolutionStrategy {
        // 强制使用兼容版本的依赖 - 更新到最新稳定版
        force("androidx.core:core-ktx:1.13.1")
        force("androidx.appcompat:appcompat:1.7.0")
        force("androidx.lifecycle:lifecycle-runtime:2.8.7")
        force("androidx.lifecycle:lifecycle-common:2.8.7")
        force("org.jetbrains.kotlin:kotlin-stdlib:2.0.21")
        force("org.jetbrains.kotlin:kotlin-stdlib-common:2.0.21")
        
        // Media3 版本对齐
        force("androidx.media3:media3-exoplayer:1.5.0")
        force("androidx.media3:media3-common:1.5.0")
        force("androidx.media3:media3-ui:1.5.0")
        
        // 排除冲突的模块 - 使用 Kotlin DSL 正确语法
        exclude(mapOf("group" to "com.google.guava", "module" to "listenablefuture"))
    }
}
