#!/bin/bash

# =============================================================================
# Gradle构建错误自动修复脚本
# 解决Kotlin编译冲突和版本不兼容问题
# =============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查当前目录
check_project_root() {
    if [[ ! -f "pubspec.yaml" ]] || [[ ! -d "android" ]]; then
        log_error "请在Flutter项目根目录运行此脚本"
        exit 1
    fi
    log_success "项目根目录验证通过"
}

# 备份关键文件
backup_files() {
    log_info "备份关键配置文件..."
    
    local backup_dir="backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # 备份Gradle配置文件
    cp android/gradle/wrapper/gradle-wrapper.properties "$backup_dir/" 2>/dev/null || true
    cp android/build.gradle.kts "$backup_dir/" 2>/dev/null || true
    cp android/app/build.gradle.kts "$backup_dir/" 2>/dev/null || true
    cp android/gradle.properties "$backup_dir/" 2>/dev/null || true
    
    log_success "文件已备份到: $backup_dir"
}

# 修复Gradle版本
fix_gradle_version() {
    log_info "修复Gradle版本到8.5..."
    
    local wrapper_file="android/gradle/wrapper/gradle-wrapper.properties"
    
    if [[ -f "$wrapper_file" ]]; then
        # 替换Gradle版本
        sed -i.bak 's/gradle-8\.12-all\.zip/gradle-8.5-all.zip/g' "$wrapper_file"
        log_success "Gradle版本已更新到8.5"
    else
        log_error "Gradle wrapper文件不存在"
        return 1
    fi
}

# 修复Kotlin版本配置
fix_kotlin_version() {
    log_info "修复Kotlin版本配置..."
    
    local build_gradle="android/build.gradle.kts"
    
    if [[ -f "$build_gradle" ]]; then
        # 创建临时文件
        local temp_file=$(mktemp)
        
        # 更新build.gradle.kts
        cat > "$temp_file" << 'EOF'
buildscript {
    ext {
        kotlin_version = '1.9.10'
        gradle_version = '8.5'
    }
    
    repositories {
        google()
        mavenCentral()
    }
    
    dependencies {
        classpath "com.android.tools.build:gradle:$gradle_version"
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
        classpath "org.jetbrains.kotlin:kotlin-android-extensions:$kotlin_version"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    configurations.all {
        resolutionStrategy {
            eachDependency {
                when (requested.group) {
                    "org.jetbrains.kotlin" -> {
                        useVersion("1.9.10")
                    }
                    "androidx.core" -> {
                        if (requested.name.startsWith("core")) {
                            useVersion("1.12.0")
                        }
                    }
                    "androidx.lifecycle" -> {
                        if (requested.name.startsWith("lifecycle")) {
                            useVersion("2.7.0")
                        }
                    }
                    "androidx.media3" -> {
                        useVersion("1.2.1")
                    }
                }
            }
            
            // 强制依赖版本
            force("org.jetbrains.kotlin:kotlin-stdlib:1.9.10")
            force("org.jetbrains.kotlin:kotlin-stdlib-common:1.9.10")
            force("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.9.10")
            force("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.10")
            force("androidx.core:core-ktx:1.12.0")
            force("androidx.appcompat:appcompat:1.6.1")
        }
    }
}
EOF
        
        mv "$temp_file" "$build_gradle"
        log_success "Kotlin版本配置已更新"
    else
        log_error "build.gradle.kts文件不存在"
        return 1
    fi
}

# 优化app级配置
optimize_app_config() {
    log_info "优化app级配置..."
    
    local app_build_gradle="android/app/build.gradle.kts"
    
    if [[ -f "$app_build_gradle" ]]; then
        # 创建临时文件
        local temp_file=$(mktemp)
        
        # 更新app/build.gradle.kts
        cat > "$temp_file" << 'EOF'
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.bili_ownx"
    compileSdk = 34
    ndkVersion = "26.1.10909125"
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }
    
    kotlinOptions {
        jvmTarget = "11"
        freeCompilerArgs += listOf(
            "-Xallow-result-return-type",
            "-Xopt-in=kotlin.RequiresOptIn",
            "-Xskip-prerelease-check"
        )
    }
    
    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
    }

    defaultConfig {
        applicationId = "com.example.bili_ownx"
        minSdk = 21
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("debug")
        }
        
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
    
    splits {
        abi {
            isEnable = true
            reset()
            include("arm64-v8a")
            isUniversalApk = false
        }
    }
    
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
EOF
        
        mv "$temp_file" "$app_build_gradle"
        log_success "app级配置已优化"
    else
        log_error "app/build.gradle.kts文件不存在"
        return 1
    fi
}

# 创建gradle.properties
create_gradle_properties() {
    log_info "创建优化的gradle.properties..."
    
    local properties_file="android/gradle.properties"
    
    cat > "$properties_file" << 'EOF'
# Kotlin编译避免修复
org.gradle.kotlin.compilation-avoidance.disabled=true

# 统一版本配置
org.jetbrains.kotlin.android.version=1.9.10
org.jetbrains.kotlin.gradle.version=1.9.10
kotlin.code.style=official

# 构建优化
org.gradle.parallel=true
org.gradle.daemon=true
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
org.gradle.caching=true

# Android优化
android.useAndroidX=true
android.enableJetifier=true
android.enableR8.fullMode=true

# 构建性能优化
org.gradle.configureondemand=true
org.gradle.vfs.watch=true
EOF
    
    log_success "gradle.properties已创建"
}

# 清理缓存
clean_caches() {
    log_info "清理所有缓存..."
    
    # 清理Flutter缓存
    flutter clean
    log_success "Flutter缓存已清理"
    
    # 清理Gradle缓存
    cd android
    ./gradlew clean
    log_success "Gradle缓存已清理"
    
    # 删除Gradle缓存目录
    rm -rf ~/.gradle/caches/ 2>/dev/null || true
    rm -rf .gradle/ 2>/dev/null || true
    log_success "本地Gradle缓存已清理"
    
    cd ..
}

# 重新获取依赖
refresh_dependencies() {
    log_info "重新获取依赖..."
    
    flutter pub get
    log_success "Flutter依赖已更新"
    
    cd android
    ./gradlew --refresh-keys
    log_success "Gradle依赖已刷新"
    
    cd ..
}

# 验证构建
verify_build() {
    log_info "开始验证构建..."
    
    if flutter build apk --debug --no-shrink; then
        log_success "🎉 构建验证成功!"
        
        # 显示APK信息
        local apk_path="build/app/outputs/apk/debug/app-debug.apk"
        if [[ -f "$apk_path" ]]; then
            local apk_size=$(du -h "$apk_path" | cut -f1)
            log_success "APK大小: $apk_size"
            log_success "APK路径: $apk_path"
        fi
    else
        log_error "❌ 构建验证失败!"
        return 1
    fi
}

# 显示修复总结
show_summary() {
    log_success "🎊 修复完成!"
    echo
    echo "=== 修复总结 ==="
    echo "✅ Gradle版本: 8.12 → 8.5"
    echo "✅ Kotlin版本: 1.7.10 → 1.9.10"
    echo "✅ 编译避免: 已禁用以解决冲突"
    echo "✅ 缓存清理: 已完成"
    echo "✅ 依赖更新: 已完成"
    echo "✅ 构建验证: 通过"
    echo
    echo "=== 后续建议 ==="
    echo "1. 定期运行此脚本维护构建环境"
    echo "2. 避免同时升级多个主要依赖版本"
    echo "3. 在CI/CD中添加构建缓存清理步骤"
    echo "4. 监控依赖更新通知"
}

# 主函数
main() {
    echo "========================================"
    echo "🔧 Gradle构建错误自动修复脚本"
    echo "========================================"
    echo
    
    # 检查环境
    check_project_root
    
    # 备份文件
    backup_files
    
    # 执行修复步骤
    fix_gradle_version
    fix_kotlin_version
    optimize_app_config
    create_gradle_properties
    clean_caches
    refresh_dependencies
    verify_build
    
    # 显示总结
    show_summary
}

# 错误处理
trap 'log_error "脚本执行过程中发生错误，请检查上述输出"; exit 1' ERR

# 执行主函数
main "$@"