@echo off
echo ========================================
echo   Quick Fix - Restart App on Emulator
echo ========================================
echo.

echo Stopping frozen app...
C:\Users\Asser\AppData\Local\Android\sdk\platform-tools\adb shell am force-stop com.example.banking_app
timeout /t 2 /nobreak >nul

echo.
echo Clearing app cache...
C:\Users\Asser\AppData\Local\Android\sdk\platform-tools\adb shell pm clear com.example.banking_app
timeout /t 2 /nobreak >nul

echo.
echo Restarting app with better performance...
echo.
echo Press Ctrl+C if the app hangs again, then run this script again.
echo.

cd C:\Users\Asser\Desktop\sharawey\mobile-bankingapp
flutter run -d emulator-5554 --release

pause

