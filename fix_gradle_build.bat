@echo off
echo === 修复 Gradle 构建问题 ===

REM 清理构建缓存
echo 清理构建缓存...
cd android
call gradlew.bat clean

REM 回到项目根目录
cd ..

REM 清理 Flutter 缓存
echo 清理 Flutter 缓存...
call flutter clean

REM 重新获取依赖
echo 重新获取依赖...
call flutter pub get

REM 升级依赖
echo 升级依赖到最新兼容版本...
call flutter pub upgrade --major-versions

REM 重新构建
echo 重新构建项目...
call flutter build apk --debug

echo === 构建修复完成 ===
pause