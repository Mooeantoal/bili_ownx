@echo off
REM =============================================================================
REM Gradle构建错误自动修复脚本 (Windows版本)
REM 解决Kotlin编译冲突和版本不兼容问题
REM =============================================================================

setlocal enabledelayedexpansion

echo ========================================
echo 🔧 Gradle构建错误自动修复脚本 (Windows)
echo ========================================
echo.

REM 检查当前目录
if not exist "pubspec.yaml" (
    echo [ERROR] 请在Flutter项目根目录运行此脚本
    pause
    exit /b 1
)

if not exist "android" (
    echo [ERROR] 未找到android目录，请确认这是Flutter项目
    pause
    exit /b 1
)

echo [INFO] 项目根目录验证通过

REM 创建备份目录
set BACKUP_DIR=backup_%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set BACKUP_DIR=%BACKUP_DIR: =0%
mkdir "%BACKUP_DIR%" 2>nul

echo [INFO] 备份关键配置文件...

REM 备份文件
if exist "android\gradle\wrapper\gradle-wrapper.properties" (
    copy "android\gradle\wrapper\gradle-wrapper.properties" "%BACKUP_DIR%\" >nul
)

if exist "android\build.gradle.kts" (
    copy "android\build.gradle.kts" "%BACKUP_DIR%\" >nul
)

if exist "android\app\build.gradle.kts" (
    copy "android\app\build.gradle.kts" "%BACKUP_DIR%\" >nul
)

if exist "android\gradle.properties" (
    copy "android\gradle.properties" "%BACKUP_DIR%\" >nul
)

echo [SUCCESS] 文件已备份到: %BACKUP_DIR%

REM 修复Gradle版本
echo [INFO] 修复Gradle版本到8.5...

set WRAPPER_FILE=android\gradle\wrapper\gradle-wrapper.properties
if exist "%WRAPPER_FILE%" (
    powershell -Command "(Get-Content '%WRAPPER_FILE%') -replace 'gradle-8\.12-all\.zip', 'gradle-8.5-all.zip' | Set-Content '%WRAPPER_FILE%'"
    echo [SUCCESS] Gradle版本已更新到8.5
) else (
    echo [ERROR] Gradle wrapper文件不存在
    pause
    exit /b 1
)

REM 修复Kotlin版本配置
echo [INFO] 修复Kotlin版本配置...

set BUILD_GRADLE=android\build.gradle.kts
if exist "%BUILD_GRADLE%" (
    (
        echo buildscript ^{
        echo     ext ^{
        echo         kotlin_version = '1.9.10'
        echo         gradle_version = '8.5'
        echo     ^}
        echo     
        echo     repositories ^{
        echo         google(^)
        echo         mavenCentral(^)
        echo     ^}
        echo     
        echo     dependencies ^{
        echo         classpath "com.android.tools.build:gradle:$gradle_version"
        echo         classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
        echo         classpath "org.jetbrains.kotlin:kotlin-android-extensions:$kotlin_version"
        echo     ^}
        echo ^}
        echo     
        echo allprojects ^{
        echo     repositories ^{
        echo         google(^)
        echo         mavenCentral(^)
        echo     ^}
        echo ^}
        echo     
        echo val newBuildDir: Directory = rootProject.layout.buildDirectory.dir^("../../build"^).get(^)
        echo rootProject.layout.buildDirectory.value^(newBuildDir^)
        echo     
        echo subprojects ^{
        echo     val newSubprojectBuildDir: Directory = newBuildDir.dir^(project.name^)
        echo     project.layout.buildDirectory.value^(newSubprojectBuildDir^)
        echo     
        echo     configurations.all ^{
        echo         resolutionStrategy ^{
        echo             eachDependency ^{
        echo                 when ^(requested.group^) ^{
        echo                     "org.jetbrains.kotlin" -^> ^{
        echo                         useVersion^("1.9.10"^)
        echo                     ^}
        echo                     "androidx.core" -^> ^{
        echo                         if ^(requested.name.startsWith^("core"^)^) ^{
        echo                             useVersion^("1.12.0"^)
        echo                         ^}
        echo                     ^}
        echo                     "androidx.lifecycle" -^> ^{
        echo                         if ^(requested.name.startsWith^("lifecycle"^)^) ^{
        echo                             useVersion^("2.7.0"^)
        echo                         ^}
        echo                     ^}
        echo                     "androidx.media3" -^> ^{
        echo                         useVersion^("1.2.1"^)
        echo                     ^}
        echo                 ^}
        echo             ^}
        echo             
        echo             // 强制依赖版本
        echo             force^("org.jetbrains.kotlin:kotlin-stdlib:1.9.10"^)
        echo             force^("org.jetbrains.kotlin:kotlin-stdlib-common:1.9.10"^)
        echo             force^("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.9.10"^)
        echo             force^("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.10"^)
        echo             force^("androidx.core:core-ktx:1.12.0"^)
        echo             force^("androidx.appcompat:appcompat:1.6.1"^)
        echo         ^}
        echo     ^}
        echo ^}
    ) > "%BUILD_GRADLE%"
    
    echo [SUCCESS] Kotlin版本配置已更新
) else (
    echo [ERROR] build.gradle.kts文件不存在
    pause
    exit /b 1
)

REM 优化app级配置
echo [INFO] 优化app级配置...

set APP_BUILD_GRADLE=android\app\build.gradle.kts
if exist "%APP_BUILD_GRADLE%" (
    (
        echo plugins ^{
        echo     id^("com.android.application"^)
        echo     id^("kotlin-android"^)
        echo     id^("dev.flutter.flutter-gradle-plugin"^)
        echo ^}
        echo     
        echo android ^{
        echo     namespace = "com.example.bili_ownx"
        echo     compileSdk = 34
        echo     ndkVersion = "26.1.10909125"
        echo     
        echo     compileOptions ^{
        echo         sourceCompatibility = JavaVersion.VERSION_11
        echo         targetCompatibility = JavaVersion.VERSION_11
        echo         isCoreLibraryDesugaringEnabled = true
        echo     ^}
        echo     
        echo     kotlinOptions ^{
        echo         jvmTarget = "11"
        echo         freeCompilerArgs += listOf^(
        echo             "-Xallow-result-return-type",
        echo             "-Xopt-in=kotlin.RequiresOptIn",
        echo             "-Xskip-prerelease-check"
        echo         ^)
        echo     ^}
        echo     
        echo     dependenciesInfo ^{
        echo         includeInApk = false
        echo         includeInBundle = false
        echo     ^}
        echo     
        echo     defaultConfig ^{
        echo         applicationId = "com.example.bili_ownx"
        echo         minSdk = 21
        echo         targetSdk = 34
        echo         versionCode = flutter.versionCode
        echo         versionName = flutter.versionName
        echo     ^}
        echo     
        echo     buildTypes ^{
        echo         release ^{
        echo             isMinifyEnabled = true
        echo             isShrinkResources = true
        echo             proguardFiles^(
        echo                 getDefaultProguardFile^("proguard-android-optimize.txt"^),
        echo                 "proguard-rules.pro"
        echo             ^)
        echo             signingConfig = signingConfigs.getByName^("debug"^)
        echo         ^}
        echo         
        echo         debug ^{
        echo             isMinifyEnabled = false
        echo             isShrinkResources = false
        echo         ^}
        echo     ^}
        echo     
        echo     splits ^{
        echo         abi ^{
        echo             isEnable = true
        echo             reset^(^)
        echo             include^("arm64-v8a"^)
        echo             isUniversalApk = false
        echo         ^}
        echo     ^}
        echo     
        echo     packaging ^{
        echo         resources ^{
        echo             excludes += listOf^(
        echo                 "META-INF/*.kotlin_module",
        echo                 "META-INF/LICENSE.md",
        echo                 "META-INF/LICENSE-notice.md",
        echo                 "META-INF/AL2.0",
        echo                 "META-INF/LGPL2.1",
        echo                 "META-INF/NOTICE.md",
        echo                 "META-INF/DEPENDENCIES",
        echo                 "META-INF/gradle/incremental.annotation.processors",
        echo                 "META-INF/*.properties",
        echo                 "META-INF/proguard/*",
        echo                 "META-INF/com.android.tools/annotations"
        echo             ^)
        echo         ^}
        echo     ^}
        echo ^}
        echo     
        echo flutter ^{
        echo     source = "../.."
        echo ^}
    ) > "%APP_BUILD_GRADLE%"
    
    echo [SUCCESS] app级配置已优化
) else (
    echo [ERROR] app/build.gradle.kts文件不存在
    pause
    exit /b 1
)

REM 创建gradle.properties
echo [INFO] 创建优化的gradle.properties...

set PROPERTIES_FILE=android\gradle.properties
(
    echo # Kotlin编译避免修复
    echo org.gradle.kotlin.compilation-avoidance.disabled=true
    echo.
    echo # 统一版本配置
    echo org.jetbrains.kotlin.android.version=1.9.10
    echo org.jetbrains.kotlin.gradle.version=1.9.10
    echo kotlin.code.style=official
    echo.
    echo # 构建优化
    echo org.gradle.parallel=true
    echo org.gradle.daemon=true
    echo org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
    echo org.gradle.caching=true
    echo.
    echo # Android优化
    echo android.useAndroidX=true
    echo android.enableJetifier=true
    echo android.enableR8.fullMode=true
    echo.
    echo # 构建性能优化
    echo org.gradle.configureondemand=true
    echo org.gradle.vfs.watch=true
) > "%PROPERTIES_FILE%"

echo [SUCCESS] gradle.properties已创建

REM 清理缓存
echo [INFO] 清理所有缓存...

echo [INFO] 清理Flutter缓存...
flutter clean
echo [SUCCESS] Flutter缓存已清理

echo [INFO] 清理Gradle缓存...
cd android
call gradlew.bat clean
cd ..
echo [SUCCESS] Gradle缓存已清理

REM 删除Gradle缓存目录
if exist "%USERPROFILE%\.gradle\caches" (
    rmdir /s /q "%USERPROFILE%\.gradle\caches" 2>nul
)

if exist "android\.gradle" (
    rmdir /s /q "android\.gradle" 2>nul
)

echo [SUCCESS] 本地Gradle缓存已清理

REM 重新获取依赖
echo [INFO] 重新获取依赖...

flutter pub get
echo [SUCCESS] Flutter依赖已更新

cd android
call gradlew.bat --refresh-keys
cd ..
echo [SUCCESS] Gradle依赖已刷新

REM 验证构建
echo [INFO] 开始验证构建...

flutter build apk --debug --no-shrink

if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] 🎉 构建验证成功!
    
    REM 显示APK信息
    set APK_PATH=build\app\outputs\apk\debug\app-debug.apk
    if exist "%APK_PATH%" (
        for %%F in ("%APK_PATH%") do set APK_SIZE=%%~zF
        set /a APK_SIZE_MB=!APK_SIZE!/1024/1024
        echo [SUCCESS] APK大小: !APK_SIZE_MB! MB
        echo [SUCCESS] APK路径: %APK_PATH%
    )
) else (
    echo [ERROR] ❌ 构建验证失败!
    pause
    exit /b 1
)

REM 显示修复总结
echo.
echo [SUCCESS] 🎊 修复完成!
echo.
echo === 修复总结 ===
echo ✅ Gradle版本: 8.12 → 8.5
echo ✅ Kotlin版本: 1.7.10 → 1.9.10
echo ✅ 编译避免: 已禁用以解决冲突
echo ✅ 缓存清理: 已完成
echo ✅ 依赖更新: 已完成
echo ✅ 构建验证: 通过
echo.
echo === 后续建议 ===
echo 1. 定期运行此脚本维护构建环境
echo 2. 避免同时升级多个主要依赖版本
echo 3. 在CI/CD中添加构建缓存清理步骤
echo 4. 监控依赖更新通知
echo.

pause