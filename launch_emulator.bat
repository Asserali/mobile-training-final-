@echo off
echo ========================================
echo   Mobile Banking App - Emulator Launcher
echo ========================================
echo.
echo Searching for Android Studio...
echo.

REM Check common Android Studio locations
set "STUDIO_PATH="

if exist "C:\Program Files\Android\Android Studio\bin\studio64.exe" (
    set "STUDIO_PATH=C:\Program Files\Android\Android Studio\bin\studio64.exe"
)

if exist "%LOCALAPPDATA%\Programs\Android\Android Studio\bin\studio64.exe" (
    set "STUDIO_PATH=%LOCALAPPDATA%\Programs\Android\Android Studio\bin\studio64.exe"
)

if exist "C:\Program Files (x86)\Android\Android Studio\bin\studio64.exe" (
    set "STUDIO_PATH=C:\Program Files (x86)\Android\Android Studio\bin\studio64.exe"
)

if defined STUDIO_PATH (
    echo Found Android Studio at:
    echo %STUDIO_PATH%
    echo.
    echo Launching Android Studio...
    echo.
    echo NEXT STEPS:
    echo 1. Click "Device Manager" (phone icon on right side)
    echo 2. Create a new device or start an existing one
    echo 3. Wait for emulator to boot fully
    echo 4. Run this command in PowerShell:
    echo    cd C:\Users\Asser\Desktop\sharawey\mobile-bankingapp
    echo    flutter run
    echo.
    start "" "%STUDIO_PATH%"
) else (
    echo Android Studio not found at common locations!
    echo.
    echo OPTION 1: Install Android Studio
    echo    Download from: https://developer.android.com/studio
    echo.
    echo OPTION 2: Use your Android phone
    echo    1. Enable USB Debugging on your phone
    echo    2. Connect via USB
    echo    3. Run: flutter run
    echo.
    echo OPTION 3: Find Android Studio manually
    echo    Look for studio64.exe and run it
    echo.
)

echo.
echo Press any key to exit...
pause >nul

