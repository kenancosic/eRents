@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ============================================================
echo   eRents Desktop App - Windows Build Script
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

REM Navigate to desktop app
echo [2/5] Navigating to desktop app directory...
cd /d "%SCRIPT_DIR%e_rents_desktop"
if %errorlevel% neq 0 (
    echo [ERROR] e_rents_desktop directory not found.
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

REM Enable Windows desktop support
echo [4/5] Enabling Windows desktop support...
call flutter config --enable-windows-desktop
echo.

REM Build the application
echo [5/5] Building release Windows executable...
echo [INFO] This may take several minutes...
echo.
call flutter build windows --release
set BUILD_RESULT=%errorlevel%

echo.
if %BUILD_RESULT% equ 0 (
    echo ============================================================
    echo   BUILD SUCCESSFUL!
    echo ============================================================
    echo.
    
    REM Check for output in both possible locations
    if exist "build\windows\x64\runner\Release\e_rents_desktop.exe" (
        set "OUTPUT_DIR=build\windows\x64\runner\Release"
        echo [OUTPUT] %CD%\build\windows\x64\runner\Release\e_rents_desktop.exe
    ) else if exist "build\windows\runner\Release\e_rents_desktop.exe" (
        set "OUTPUT_DIR=build\windows\runner\Release"
        echo [OUTPUT] %CD%\build\windows\runner\Release\e_rents_desktop.exe
    ) else (
        echo [WARNING] Executable not found at expected location.
        echo [INFO] Check build\windows\ folder manually.
        set "OUTPUT_DIR=build\windows"
    )
    
    echo.
    echo [INFO] Opening output folder...
    explorer "!OUTPUT_DIR!"
) else (
    echo ============================================================
    echo   BUILD FAILED!
    echo ============================================================
    echo.
    echo [TIP] Run 'flutter doctor -v' to diagnose issues
    echo [TIP] Check if Visual Studio Build Tools are installed
)

cd /d "%ORIGINAL_DIR%"
echo.
pause
