# CI/CD 修复验证脚本 (PowerShell版本)
# 用于验证 GitHub Actions 配置修复是否成功

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "CI/CD 修复验证脚本" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 1. 检查 GitHub Actions 配置
Write-Host "1. 检查 GitHub Actions 配置..." -ForegroundColor Yellow
$ciConfig = ".github/workflows/ci.yml"
if (Test-Path $ciConfig) {
    Write-Host "✅ CI 配置文件存在" -ForegroundColor Green
    
    # 检查 Flutter Action 版本
    if (Select-String -Path $ciConfig -Pattern "subosito/flutter-action@v3") {
        Write-Host "✅ Flutter Action 版本已更新为 v3" -ForegroundColor Green
    } else {
        Write-Host "❌ Flutter Action 版本未正确更新" -ForegroundColor Red
    }
    
    # 检查 Java Home 设置
    if (Select-String -Path $ciConfig -Pattern "export JAVA_HOME=/opt/hostedtoolcache/Java_Temurin-Hotspot_jdk/17.0.17-10/x64") {
        Write-Host "✅ Java Home 路径已修复" -ForegroundColor Green
    } else {
        Write-Host "❌ Java Home 路径未修复" -ForegroundColor Red
    }
} else {
    Write-Host "❌ CI 配置文件不存在" -ForegroundColor Red
}

Write-Host ""

# 2. 检查本地 Flutter 环境
Write-Host "2. 检查本地 Flutter 环境..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version
    Write-Host "✅ Flutter 已安装" -ForegroundColor Green
    Write-Host $flutterVersion -ForegroundColor White
} catch {
    Write-Host "❌ Flutter 未安装或不在 PATH 中" -ForegroundColor Red
}

Write-Host ""

# 3. 检查 Java 环境
Write-Host "3. 检查 Java 环境..." -ForegroundColor Yellow
try {
    $javaVersion = java -version
    Write-Host "✅ Java 已安装" -ForegroundColor Green
    Write-Host $javaVersion -ForegroundColor White
} catch {
    Write-Host "❌ Java 未安装或不在 PATH 中" -ForegroundColor Red
}

Write-Host ""

# 4. 检查 Gradle 配置
Write-Host "4. 检查 Gradle 配置..." -ForegroundColor Yellow
$gradlew = "android/gradlew"
if (Test-Path $gradlew) {
    Write-Host "✅ Gradle Wrapper 存在" -ForegroundColor Green
    
    # 检查 Gradle 版本
    $gradleProperties = "android/gradle/wrapper/gradle-wrapper.properties"
    if (Test-Path $gradleProperties) {
        Write-Host "✅ Gradle Wrapper 配置存在" -ForegroundColor Green
    } else {
        Write-Host "❌ Gradle Wrapper 配置缺失" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Gradle Wrapper 不存在" -ForegroundColor Red
}

Write-Host ""

# 5. 检查项目依赖
Write-Host "5. 检查项目依赖..." -ForegroundColor Yellow
$pubspec = "pubspec.yaml"
if (Test-Path $pubspec) {
    Write-Host "✅ pubspec.yaml 存在" -ForegroundColor Green
    
    # 运行依赖检查
    try {
        Write-Host "检查依赖兼容性..." -ForegroundColor Cyan
        $pubResult = flutter pub get
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ 依赖解析成功" -ForegroundColor Green
        } else {
            Write-Host "❌ 依赖解析失败" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ 依赖检查失败" -ForegroundColor Red
    }
} else {
    Write-Host "❌ pubspec.yaml 不存在" -ForegroundColor Red
}

Write-Host ""

# 6. 模拟构建测试
Write-Host "6. 模拟构建测试..." -ForegroundColor Yellow
if ((Get-Command flutter -ErrorAction SilentlyContinue) -and (Test-Path $pubspec)) {
    Write-Host "尝试清理项目..." -ForegroundColor Cyan
    flutter clean
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 项目清理成功" -ForegroundColor Green
    } else {
        Write-Host "❌ 项目清理失败" -ForegroundColor Red
    }
    
    Write-Host "尝试获取依赖..." -ForegroundColor Cyan
    flutter pub get
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 依赖获取成功" -ForegroundColor Green
    } else {
        Write-Host "❌ 依赖获取失败" -ForegroundColor Red
    }
} else {
    Write-Host "❌ 无法进行构建测试（Flutter 或项目配置问题）" -ForegroundColor Red
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "验证完成" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "如果所有检查都显示 ✅，说明修复成功，可以推送代码触发 CI/CD。" -ForegroundColor Green
Write-Host "如果有 ❌ 项目，请先修复本地问题再推送。" -ForegroundColor Yellow
Write-Host ""

# 7. 提供推送建议
Write-Host "推送建议：" -ForegroundColor Cyan
Write-Host "git add .github/workflows/ci.yml" -ForegroundColor White
Write-Host "git commit -m `"修复 Java Home 路径和 Flutter Action 版本问题`"" -ForegroundColor White
Write-Host "git push origin main" -ForegroundColor White
Write-Host ""
Read-Host "按回车键退出..."