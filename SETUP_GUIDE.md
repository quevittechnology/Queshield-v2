# QueShield Setup Guide 🚀

## Installation Options

### ✅ Option 1: Quick Start (If you have Flutter installed)

If you already have Flutter installed on your system:

```powershell
# Navigate to project directory
cd f:\QUESHIELD

# Install dependencies
flutter pub get

# Run the app (with connected Android device/emulator)
flutter run

# Or build APK
flutter build apk --release
```

Your APK will be at: `f:\QUESHIELD\build\app\outputs\flutter-apk\app-release.apk`

---

### 📦 Option 2: Flutter Installation (Fresh Setup)

If you don't have Flutter installed:

#### Step 1: Download Flutter SDK

1. Visit: https://docs.flutter.dev/get-started/install/windows
2. Download Flutter SDK (latest stable version)
3. Extract to `C:\src\flutter` (recommended)

#### Step 2: Add Flutter to PATH

1. Open "Environment Variables":
   - Press `Win + X` → System → Advanced system settings →Environment Variables
   
2. Under "User variables", edit `Path`:
   - Click "New"
   - Add: `C:\src\flutter\bin`
   - Click "OK"

3. Verify installation:
   ```powershell
   flutter --version
   ```

#### Step 3: Install Android Setup

1. **Download Android Studio**:
   - Visit: https://developer.android.com/studio
   - Install Android Studio

2. **Configure Android SDK**:
   - Open Android Studio
   - Go to: File → Settings → Appearance & Behavior → System Settings → Android SDK
   - Install:
     - Android SDK Platform 34
     - Android SDK Build-Tools
     - Android SDK Command-line Tools

3. **Accept licenses**:
   ```powershell
   flutter doctor --android-licenses
   ```
   (Press `y` for all)

4. **Run Flutter Doctor**:
   ```powershell
   flutter doctor
   ```
   Fix any issues shown

#### Step 4: Build the App

1. Navigate to project:
   ```powershell
   cd f:\QUESHIELD
   ```

2. Install dependencies:
   ```powershell
   flutter pub get
   ```

3. Connect Android device (USB) or start emulator:
   ```powershell
   # List devices
   flutter devices
   ```

4. Run the app:
   ```powershell
   flutter run
   ```

5. Or build APK for installation:
   ```powershell
   flutter build apk --release
   ```

---

### 🔧 Option 3: Manual APK Build (Advanced)

If you need to build without running:

```powershell
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release --split-per-abi

# Smaller APK (single architecture)
flutter build apk --release --target-platform android-arm64
```

Output location:
- `f:\QUESHIELD\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk`

---

## 📱 Installing on Android Device

### Method 1: Direct Installation (Dev Mode)

1. Enable "Developer Options" on Android:
   - Settings → About Phone → Tap "Build Number" 7 times

2. Enable "USB Debugging":
   - Settings → Developer Options → USB Debugging (ON)

3. Connect device to PC via USB

4. Run:
   ```powershell
   flutter install
   ```

### Method 2: Transfer APK

1. Build APK:
   ```powershell
   flutter build apk --release
   ```

2. Copy APK to phone:
   - `f:\QUESHIELD\build\app\outputs\flutter-apk\app-release.apk`

3. On phone:
   - Open file manager
   - Tap APK file
   - Allow "Install from Unknown Sources"
   - Install

---

## ⚙️ Configuration

### Update Flutter SDK Path (if different)

Edit `f:\QUESHIELD\android\local.properties`:

```properties
flutter.sdk=YOUR_FLUTTER_SDK_PATH
```

Example:
```properties
flutter.sdk=C:\\Users\\YourName\\flutter
flutter.sdk=D:\\Dev\\flutter
```

### Customize Security Features

Edit `f:\QUESHIELD\lib\core\services\database_service.dart`:

1. **Add Malware Hashes**:
   ```dart
   'malware_hashes': [
     '44d88612fea8a8f36de82e1278abb02f', // EICAR test
     'your_hash_here',
   ],
   ```

2. **Add Spam Numbers**:
   ```dart
   'spam_patterns': [
     r'^140\d{5}$', // Telemarketing
     r'^your_pattern$',
   ],
   ```

3. **Add Phishing Keywords**:
   ```dart
   'phishing_keywords': [
     'digital arrest',
     'your_keyword',
   ],
   ```

---

## 🧪 Testing the App

### Test Malware Detection

1. Download EICAR test file:
   - Visit: https://www.eicar.org/download-anti-malware-testfile/
   - Download `eicar.com` or `eicar.txt`

2. Place in Downloads folder

3. Run Quick Scan in app

4. Should detect as threat!

### Test Dashboard

1. Open app
2. View security score (should be 100)
3. Toggle dark/light mode
4. Check feature modules

---

## 🐛 Troubleshooting

### "Flutter command not found"
- Add Flutter to PATH (see Option 2, Step 2)
- Restart terminal/PowerShell

### "Android licenses not accepted"
```powershell
flutter doctor --android-licenses
```

### "No connected devices"
- Enable USB Debugging on phone
- Or start Android emulator in Android Studio

### "Build failed - SDK not found"
- Update `local.properties` with correct Flutter path
- Run `flutter doctor` to check setup

### "Permission denied" during scan
- Grant storage permissions in app settings
- Android 11+: Enable "All Files Access"

### App crashes on startup
- Check Android version (requires API 26+)
- Clear app data and reinstall

---

## 📊 Performance Tips

1. **Battery Optimization**:
   - Disable battery optimization for QueShield
   - Settings → Apps → QueShield → Battery → Unrestricted

2. **Storage Management**:
   - App uses < 10MB for database
   - Scan only necessary folders
   - Run optimization weekly

3. **Scan Settings**:
   - Use "Quick Scan" for routine checks
   - "Full Scan" once per week
   - Schedule scans during charging

---

## 🔐 Permissions Explained

The app requests these permissions:

| Permission | Purpose |
|------------|---------|
| Storage | File scanning for malware |
| Phone & SMS | Caller ID, spam detection |
| Network | Threat database updates |
| Overlay | Payment security checks |
| Background Service | Real-time protection |

**Note**: All scanning is local. No data leaves your device.

---

## 📈 Next Steps

After installation:

1. ✅ Complete onboarding
2. ✅ Grant required permissions
3. ✅ Run first scan
4. ✅ Enable real-time protection
5. ✅ Configure scan schedule

---

## 🆘 Need Help?

- **Check README.md** for feature details
- **Review implementation_plan.md** for architecture
- **Check task.md** for development status

---

**Ready to protect your device!** 🛡️

Install now and enjoy comprehensive mobile security with zero lag!
