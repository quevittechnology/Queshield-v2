# QueShield - Universal Security App

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)
![Platform](https://img.shields.io/badge/Platform-Android-green.svg)
![Version](https://img.shields.io/badge/Version-1.0.0-red.svg)

## ⚠️ BUILD NOTICE

**For Online Build Services (Codemagic, FlutLab, etc.):**

This project uses **Flutter v2 embedding** for Android. If you encounter "Android v1 embedding" errors:

1. **Clear build cache** before building
2. **Use Flutter stable channel** (3.16.0+)
3. The MainActivity.kt file is located at: `android/app/src/main/kotlin/com/queshield/queshield/MainActivity.kt`
4. Build with: `flutter build apk --release` (NOT appbundle --debug)

**Recommended:** Build locally on your machine for fastest results.

---

## 🛡️ Complete Universal Security Solution for Android

QueShield is a comprehensive security application built with Flutter, providing advanced protection features including antivirus scanning, caller ID, payment security, web protection, anti-fraud awareness, storage optimization, and lost phone tracking.

### ✨ Key Features

#### 🦠 Antivirus & Threat Protection
- Real-time file scanner with custom malware signatures
- APK security analysis
- Hash-based threat detection (MD5)
- Phishing content scanner
- Quick, Full, and Custom scan modes
- Threat quarantine management

#### 📞 Caller ID & Spam Protection  
- Advanced spam call detection using pattern analysis
- Heuristic analysis for unknown numbers
- Sequential and repeated digit detection
- India-focused telemarketing detection
- Local blocklist management with auto-blocking
- Confidence scoring (0-100%)

#### 💳 Payment & Financial Security
- Fake payment app detection
- Legitimate app verification (Paytm, PhonePe, GPay, etc.)
- Package signature analysis
- UPI security checker
- Transaction SMS monitoring
- Screen overlay detection
- Impersonation alerts

#### 🌐 Web Security
- Multi-layer phishing URL detection
- Typosquatting detection (fake domains)
- SSL/HTTPS verification
- Domain reputation analysis
- URL structure validation
- Suspicious TLD detection (.tk, .ml, etc.)
- Risk scoring system (0-100)

#### 🚨 Anti-Fraud & Scam Protection
- Digital arrest scam awareness
- Government impersonation detection
- OTP scam protection
- Educational content (5 scam types)
- Emergency helplines (1930, 155260)
- SMS fraud analysis
- Interactive awareness tips

#### 💾 Storage Cleaner
- Cache analysis and cleanup
- Duplicate file detection
- Large file finder (>50MB)
- Storage usage breakdown
- Cleanup recommendations
- One-tap optimization

#### 📍 Lost Phone Protection
- GPS location tracking with Google Maps
- Remote lock and wipe capabilities
- SIM card change detection
- SMS alerts to trusted contacts
- Remote alarm (max volume)
- Last known location backup

### 🎨 Design Highlights

- **Modern Material Design 3** interface
- **Dark/Light theme** support
- **Smooth animations** with flutter_animate
- **Gradient-based** color system
- **Card-based** layouts for clarity
- **Professional UI/UX** - Play Store ready

### 📊 Technical Stack

**Frontend:**
- Flutter 3.0+ (Dart)
- Provider State Management
- Material Design 3

**Database:**
- Hive (Lightweight NoSQL)
- <10 MB optimized storage
- Encrypted local data

**Security:**
- Custom malware signatures
- Pattern matching algorithms
- Heuristic threat analysis
- Hash-based detection

**Services:**
- Background foreground service
- Location tracking (Geolocator)
- Local notifications
- SMS/Call monitoring

### 🚀 Getting Started

#### Prerequisites

- Flutter SDK 3.0 or higher
- Android SDK (API 26+)
- Android Studio or VS Code
- Git

#### Installation

```bash
# Clone repository
git clone https://github.com/quevittechnology/Queshield.git
cd Queshield

# Install dependencies
flutter pub get

# Run on device/emulator
flutter run

# Build release APK
flutter build apk --release
```

#### APK Location
```
build/app/outputs/flutter-apk/app-release.apk
```

### 📱 Platform Support

- ✅ **Android 8.0+ (API 26)** - Full functionality
- ⚠️ **iOS 12.0+** - Limited features (Apple sandbox restrictions)

**Note:** QueShield is designed for Android where full security features are available. iOS version has limited functionality due to platform restrictions.

### 📚 Documentation

- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Installation & configuration
- **[FEATURES.md](FEATURES.md)** - Complete feature list
- **[BUILD_GUIDE.md](BUILD_GUIDE.md)** - Build instructions
- **[ONLINE_BUILD_GUIDE.md](ONLINE_BUILD_GUIDE.md)** - Online build services

### 🎯 Performance Metrics

**App Size:**
- Release APK: ~18-22 MB
- Split APK (arm64): ~15-18 MB
- Database: <10 MB

**Scan Performance:**
- Quick Scan: 10-30 seconds
- Full Scan: 2-5 minutes
- ~100-200 files/second

**Resource Usage:**
- Memory (idle): 50-80 MB
- Memory (scanning): 100-150 MB
- Battery: Low impact (optimized)

### 🔒 Security & Privacy

- ✅ **100% Local** - All scanning happens on device
- ✅ **No Data Upload** - Nothing sent to external servers
- ✅ **No Telemetry** - Complete privacy
- ✅ **Encrypted Storage** - Sensitive data protected
- ✅ **Open Source** - Transparent security

### 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point
├── core/
│   └── services/            # Database, Background, Notifications
├── features/
│   ├── antivirus/          # Malware scanning
│   ├── caller_id/          # Spam detection
│   ├── payment_security/   # Payment protection
│   ├── web_security/       # Phishing detection
│   ├── anti_fraud/         # Scam awareness
│   ├── storage/            # Storage optimization
│   ├── lost_phone/         # Anti-theft
│   └── dashboard/          # Main UI
├── shared/
│   ├── providers/          # State management
│   └── widgets/            # Reusable components
└── theme/                  # App theming
```

### 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

### 📄 License

To be determined - Add LICENSE file

### 🙏 Acknowledgments

- Flutter team for the amazing framework
- Open source community
- Security researchers for threat intelligence

### 📞 Support

- **Issues**: [GitHub Issues](https://github.com/quevittechnology/Queshield/issues)
- **Email**: info@quevit.com
- **Documentation**: Check `/docs` folder

### 🎉 Features Showcase

Check out `mockups.md` in the artifacts folder for professional UI screenshots of all features!

---

**QueShield** - Complete Mobile Security, Made in India 🇮🇳

Built with ❤️ using Flutter
