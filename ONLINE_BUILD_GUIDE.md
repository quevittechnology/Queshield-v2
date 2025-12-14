# QueShield - Online Build Service Instructions

## ⚠️ Build Error: iOS xcodeproj Not Found

Your project was built for **Android only**. The online build service is trying to build iOS but the iOS folder doesn't exist.

---

## 🔧 Solution: Build Android Only

### For Codemagic / FlutLab / Similar Services

**Option 1: Configure to Build Android Only**

In your build configuration:

**Codemagic codemagic.yaml:**
```yaml
workflows:
  android-workflow:
    name: Android Build
    max_build_duration: 60
    environment:
      flutter: stable
    scripts:
      - name: Get Flutter packages
        script: flutter pub get
      - name: Build Android APK
        script: flutter build apk --release
    artifacts:
      - build/app/outputs/flutter-apk/app-release.apk
```

**FlutLab:**
- Build Settings → Platform → Select **Android Only**
- Uncheck iOS build
- Save and rebuild

**AppCenter / Other Services:**
- Look for "Target Platform" or "Build Platform" settings
- Select: **Android**
- Disable: **iOS**

---

## 📱 Alternative: Add iOS Support (If Needed)

If you want iOS support in the future, you'll need to:

### Prerequisites:
- macOS computer (iOS development requires macOS)
- Xcode installed
- CocoaPods installed

### Steps:

1. **On macOS with Flutter installed:**
```bash
cd /path/to/QUESHIELD
flutter create --platforms=ios .
```

2. **Configure iOS permissions in ios/Runner/Info.plist:**
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>QueShield needs location access for lost phone tracking</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>QueShield needs background location for lost phone protection</string>

<key>NSCameraUsageDescription</key>
<string>QueShield needs camera access for security features</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>QueShield needs photo access to scan for malware</string>
```

3. **Push to GitHub:**
```bash
git add ios/
git commit -m "Add iOS platform support"
git push origin main
```

**⚠️ Note:** Many security features won't work on iOS due to Apple's sandboxing restrictions:
- ❌ Full file system scanning (limited access)
- ❌ Call blocking (requires CallKit, limited)
- ❌ SMS access (not allowed)
- ❌ Package scanning (no access to other apps)
- ✅ Web security (works)
- ✅ Anti-fraud education (works)
- ✅ Lost phone tracking (works with limitations)

---

## 🎯 Recommended: Build Android Locally or Online (Android Only)

### Option 1: Build Locally (Recommended)

**Install Flutter on your Windows PC:**

1. Download Flutter SDK: https://docs.flutter.dev/get-started/install/windows
2. Extract to `C:\src\flutter`
3. Add to PATH: `C:\src\flutter\bin`
4. Install Android Studio
5. Run `flutter doctor`

**Then build:**
```powershell
cd f:\QUESHIELD
flutter pub get
flutter build apk --release
```

**APK Location:** `build\app\outputs\flutter-apk\app-release.apk`

---

### Option 2: Use GitHub Actions (Free CI/CD)

Create `.github/workflows/android-build.yml`:

```yaml
name: Android Build

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Java
      uses: actions/setup-java@v3
      with:
        distribution: 'zulu'
        java-version: '17'
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
        channel: 'stable'
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Build APK
      run: flutter build apk --release
    
    - name: Upload APK
      uses: actions/upload-artifact@v3
      with:
        name: app-release
        path: build/app/outputs/flutter-apk/app-release.apk
```

**Commit and push this file to trigger automatic builds on GitHub!**

---

## 🔍 Current Project Status

**Supported Platforms:**
- ✅ **Android** (Full support - all features)
- ❌ **iOS** (Not configured - would need macOS)

**Recommended Actions:**
1. Build Android APK only
2. Focus on Android deployment
3. Add iOS later if needed (requires macOS)

**Your project is Android-first**, which is perfect for a security app since Android allows deeper system access!

---

## 📊 Build Service Comparison

| Service | Android | iOS | Free Tier | Notes |
|---------|---------|-----|-----------|-------|
| **GitHub Actions** | ✅ | ✅ | 2000 min/month | Best for Android |
| **Codemagic** | ✅ | ✅ | 500 min/month | Easy setup |
| **AppCenter** | ✅ | ✅ | Free | Microsoft |
| **FlutLab** | ✅ | ✅ | Limited | Online IDE |
| **Local Build** | ✅ | ❌ (needs macOS) | Unlimited | Fastest |

---

## 🚀 Quick Fix for Current Build

**In your online build service:**

1. **Find build configuration file** (codemagic.yaml, .yml, or build settings)
2. **Change target platform to Android only**
3. **Disable iOS build**
4. **Rebuild**

Or simply:
- **Install Flutter locally** on your Windows PC
- **Build Android APK** with `flutter build apk --release`
- Takes 5-10 minutes for first build
- Get immediate APK file

---

## 💡 Recommendation

**Best approach for QueShield:**

1. ✅ **Build Android locally** (fastest, full control)
2. ✅ Deploy to Google Play Store (Android)
3. ⏸️ Skip iOS for now (limited security features anyway)
4. 🔄 Add iOS later if there's demand (requires macOS)

Your app is **meant for Android** - iOS sandboxing would limit most security features!

---

**Need help setting up Flutter locally? Check BUILD_GUIDE.md for step-by-step instructions!**
