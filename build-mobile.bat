@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ============================================================
echo   eRents Mobile App - Android APK Build Script
echo   Seminarski rad - Razvoj softvera II (RSII)
echo   Student: Kenan Cosic (IB160228)
echo ============================================================
echo.

REM Store original directory
set "ORIGINAL_DIR=%CD%"
set "SCRIPT_DIR=%~dp0"

REM Check if Flutter is installed
echo [1/5] Checking Flutter installation...
flutter --version
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Flutter not found. Please install Flutter SDK first.
    echo [INFO] Visit: https://flutter.dev/docs/get-started/install/windows
    pause
    exit /b 1
)
echo [OK] Flutter is installed
echo.

REM Navigate to mobile app
echo [2/5] Navigating to mobile app directory...
cd /d "%SCRIPT_DIR%e_rents_mobile"
if %errorlevel% neq 0 (
    echo [ERROR] e_rents_mobile directory not found.
    cd /d "%ORIGINAL_DIR%"
    pause
    exit /b 1
)
echo [OK] Working directory: %CD%
echo.

REM Get dependencies
echo [3/5] Getting Flutter dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo [ERROR] Failed to get dependencies.
    cd /d "%ORIGINAL_DIR%"
    pause
    exit /b 1
)
echo [OK] Dependencies resolved
echo.

REM Show connected devices
echo [4/5] Available devices:
call flutter devices
echo.

REM Build the APK
echo [5/5] Building release APK...
echo [INFO] This may take several minutes...
echo.
call flutter build apk --release
set BUILD_RESULT=%errorlevel%

echo.
if %BUILD_RESULT% equ 0 (
    echo ============================================================
    echo   BUILD SUCCESSFUL!
    echo ============================================================
    echo.
    
    set "APK_PATH=build\app\outputs\flutter-apk\app-release.apk"
    if exist "!APK_PATH!" (
        echo [OUTPUT] %CD%\!APK_PATH!
        for %%I in ("!APK_PATH!") do echo [SIZE] %%~zI bytes
        echo.
        echo [INFO] Opening output folder...
        explorer "build\app\outputs\flutter-apk"
    ) else (
        echo [WARNING] APK not found at expected location.
        echo [INFO] Check build\app\outputs\ folder manually.
    )
) else (
    echo ============================================================
    echo   BUILD FAILED!
    echo ============================================================
    echo.
    echo [TIP] Run 'flutter doctor -v' to diagnose issues
    echo [TIP] Make sure Android SDK is properly configured
)

cd /d "%ORIGINAL_DIR%"
echo.
pause
