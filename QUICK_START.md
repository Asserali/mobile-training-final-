# Quick Start Guide - Run on Emulator

## ✅ Your App is Ready!

All compilation errors have been fixed. The app successfully builds and is configured to use **Firebase** as the main database (not SQLite).

## 🚀 Launch the App (3 Simple Steps)

### Step 1: Create & Start an Emulator

Open a new terminal and run:

```powershell
# Option A: Create a new emulator automatically
flutter emulators --create

# Option B: Use Android Studio
# - Open Android Studio
# - Click "More Actions" > "Virtual Device Manager"
# - Click "Create Device"
# - Select a device (e.g., Pixel 5)
# - Select a system image (e.g., Android 13)
# - Click Finish
# - Click the Play button to start it
```

### Step 2: Verify Device is Running

```powershell
flutter devices
```

You should see your emulator listed. If not, wait a few seconds for it to fully boot.

### Step 3: Run the App

```powershell
cd C:\Users\Asser\Desktop\sharawey\mobile-bankingapp
flutter run
```

That's it! The app will install and launch on the emulator.

## 📱 Alternative: Run on Your Phone

1. Enable Developer Options on your Android phone:
   - Go to Settings > About Phone
   - Tap "Build Number" 7 times
   
2. Enable USB Debugging:
   - Go to Settings > Developer Options
   - Turn on "USB Debugging"

3. Connect your phone via USB

4. Run:
   ```powershell
   flutter run
   ```

## 🧪 Test the App

### Register a New Account
1. Click "Register" on the login screen
2. Enter a valid Egyptian National ID (14 digits, e.g., `29512011234567`)
3. Enter a phone number (e.g., `01234567890`)
4. Enter OTP: `123456` (demo mode)
5. Fill in your details
6. Create a 6-digit PIN

### Login
- National ID: Your registered ID
- PIN: Your 6-digit PIN

### Demo Mode
For quick testing without registration:
- National ID: Any valid 14-digit Egyptian ID
- PIN: `123456`

## 🛠️ If You Run Into Issues

### "No devices found"
```powershell
# Check if emulator is running
flutter devices

# If empty, create and launch emulator
flutter emulators --create
# Wait for it to boot, then run again:
flutter devices
```

### "Gradle build failed"
```powershell
cd C:\Users\Asser\Desktop\sharawey\mobile-bankingapp
flutter clean
flutter pub get
flutter run
```

### App crashes on startup
Check that Firebase is properly configured:
- File exists: `android/app/google-services.json`
- Internet connection is active

## 📊 What You Can Do in the App

✅ View account balances  
✅ Add income/expense transactions  
✅ Track spending by category  
✅ View analytics and charts  
✅ Set budgets  
✅ Transfer money between accounts  
✅ Request/send money  
✅ Top up mobile credit  
✅ Pay bills  
✅ Manage multiple accounts  
✅ Profile management  

## 🔧 Technical Details

**Database**: Firebase Firestore (real-time sync)  
**Authentication**: Firebase Auth + Custom Egyptian ID validation  
**State Management**: Provider pattern with AppState  
**Build**: Debug APK ready at `build/app/outputs/flutter-apk/app-debug.apk`  

---

**Need Help?**  
Check `FIREBASE_SETUP_COMPLETE.md` for detailed information about the fixes and configuration.

**Ready to code?**  
All errors are fixed. Just launch an emulator and run `flutter run`! 🎉

