@echo off
setlocal enabledelayedexpansion

REM Android SDK 35 路径修复脚本 (Windows版本)
REM 解决 android-35 vs android-35-2 路径不匹配问题

echo === Android SDK 35 路径修复 ===
echo 检查当前 SDK 安装状态...

REM 设置 Android SDK 路径
if defined ANDROID_HOME (
    set "ANDROID_SDK_ROOT=%ANDROID_HOME%"
) else (
    set "ANDROID_SDK_ROOT=%cd%\android-sdk"
)

echo SDK 根目录: %ANDROID_SDK_ROOT%

REM 检查 platforms 目录
set "PLATFORMS_DIR=%ANDROID_SDK_ROOT%\platforms"
echo 检查 platforms 目录: %PLATFORMS_DIR%

if exist "%PLATFORMS_DIR%" (
    echo 已安装的 Android 平台:
    dir "%PLATFORMS_DIR%" | findstr "android"
    
    REM 检查是否存在 android-35-2 但不存在 android-35
    if exist "%PLATFORMS_DIR%\android-35-2" (
        if not exist "%PLATFORMS_DIR%\android-35" (
            echo 发现 android-35-2，创建 android-35 符号链接...
            
            REM Windows 下使用 mklink 创建符号链接（需要管理员权限）
            mklink /D "%PLATFORMS_DIR%\android-35" "%PLATFORMS_DIR%\android-35-2" >nul 2>&1
            
            if exist "%PLATFORMS_DIR%\android-35" (
                echo ✓ 成功创建 android-35 符号链接指向 android-35-2
                dir "%PLATFORMS_DIR%\android-35%" | head
            ) else (
                echo ❌ 创建符号链接失败（可能需要管理员权限），尝试复制...
                robocopy "%PLATFORMS_DIR%\android-35-2" "%PLATFORMS_DIR%\android-35" /E /NFL /NDL /NJH /NJS >nul
                if exist "%PLATFORMS_DIR%\android-35" (
                    echo ✓ 成功复制 android-35-2 到 android-35
                ) else (
                    echo ❌ 复制也失败了
                    exit /b 1
                )
            )
        ) else (
            echo ✓ android-35 已存在，无需修复
        )
    ) else if exist "%PLATFORMS_DIR%\android-35" (
        echo ✓ android-35 已存在，无需修复
    ) else (
        echo ❌ 未找到 android-35-2 或 android-35
        echo 尝试安装 Android SDK 35...
        
        REM 使用 sdkmanager 安装 platform
        if exist "%ANDROID_SDK_ROOT%\cmdline-tools\latest\bin\sdkmanager.bat" (
            call "%ANDROID_SDK_ROOT%\cmdline-tools\latest\bin\sdkmanager.bat" --install "platforms;android-35"
        ) else (
            echo ❌ sdkmanager 不可用
            exit /b 1
        )
    )
) else (
    echo ❌ platforms 目录不存在
    exit /b 1
)

echo.
echo === 验证修复结果 ===
if exist "%PLATFORMS_DIR%\android-35" (
    echo ✓ android-35 现在可用
    echo 路径: %PLATFORMS_DIR%\android-35
    echo 内容:
    dir "%PLATFORMS_DIR%\android-35" | head
) else (
    echo ❌ android-35 仍然不可用
    exit /b 1
)

echo.
echo === 检查构建工具 ===
set "BUILD_TOOLS_DIR=%ANDROID_SDK_ROOT%\build-tools"
if exist "%BUILD_TOOLS_DIR%" (
    echo 已安装的构建工具:
    dir "%BUILD_TOOLS_DIR%" | findstr "35"
    
    if not exist "%BUILD_TOOLS_DIR%\35.0.0" (
        echo 尝试安装构建工具 35.0.0...
        if exist "%ANDROID_SDK_ROOT%\cmdline-tools\latest\bin\sdkmanager.bat" (
            call "%ANDROID_SDK_ROOT%\cmdline-tools\latest\bin\sdkmanager.bat" --install "build-tools;35.0.0"
        )
    )
) else (
    echo ❌ build-tools 目录不存在
)

echo.
echo === 修复完成 ===
echo 现在可以重新运行 Flutter 构建

pause