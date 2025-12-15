#!/bin/bash

# QueShield VPS Build Script - FIXED VERSION with absolute paths
# Run this script on VPS to build APK

set -e

echo "🛡️ QueShield APK Build on VPS"
echo "=============================="
echo ""

# Set PATH explicitly
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Update system
echo "📦 Updating system packages..."
/usr/bin/apt-get update -qq
/usr/bin/apt-get install -y wget curl git unzip xz-utils zip libglu1-mesa openjdk-11-jdk

# Install Flutter
echo "📦 Installing Flutter SDK..."
cd /root
if [ ! -d "flutter" ]; then
    /usr/bin/wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
    /bin/tar xf flutter_linux_3.24.5-stable.tar.xz
    /bin/rm flutter_linux_3.24.5-stable.tar.xz
fi

# Set up Flutter path
export PATH="$PATH:/root/flutter/bin"

# Install Android SDK
echo "📦 Installing Android SDK..."
cd /root
if [ ! -d "android-sdk" ]; then
    /usr/bin/wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
    /bin/mkdir -p android-sdk/cmdline-tools
    /usr/bin/unzip -q commandlinetools-linux-11076708_latest.zip -d android-sdk/cmdline-tools
    /bin/mv android-sdk/cmdline-tools/cmdline-tools android-sdk/cmdline-tools/latest
    /bin/rm commandlinetools-linux-11076708_latest.zip
fi

# Set Android environment variables
export ANDROID_HOME=/root/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

# Accept Android licenses
yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses 2>/dev/null || true

# Install required Android SDK components
echo "📦 Installing Android SDK components..."
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# Configure Flutter
echo "⚙️ Configuring Flutter..."
/root/flutter/bin/flutter config --android-sdk=$ANDROID_HOME
/root/flutter/bin/flutter config --no-analytics
/root/flutter/bin/flutter doctor --android-licenses 2>/dev/null || true

# Go to project directory
cd /root/queshield-app

# Clean and get dependencies
echo "📦 Getting Flutter dependencies..."
/root/flutter/bin/flutter clean
/root/flutter/bin/flutter pub get

# Build release APK
echo "🔨 Building release APK..."
/root/flutter/bin/flutter build apk --release --split-per-abi

# Copy APK to web directory
echo "📋 Deploying APK..."
/bin/mkdir -p /var/www/html/download
/bin/cp build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk /var/www/html/download/queshield-v1.0.0-arm.apk 2>/dev/null || true
/bin/cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk /var/www/html/download/queshield-v1.0.0-arm64.apk 2>/dev/null || true
/bin/cp build/app/outputs/flutter-apk/app-x86_64-release.apk /var/www/html/download/queshield-v1.0.0-x64.apk 2>/dev/null || true

# Set permissions
/bin/chmod 644 /var/www/html/download/*.apk 2>/dev/null || true
/bin/chown www-data:www-data /var/www/html/download/*.apk 2>/dev/null || true

echo ""
echo "✅ Build complete!"
echo ""
echo "📱 APK files available at:"
echo "   - http://145.223.19.208/download/queshield-v1.0.0-arm.apk (32-bit ARM)"
echo "   - http://145.223.19.208/download/queshield-v1.0.0-arm64.apk (64-bit ARM)"
echo "   - http://145.223.19.208/download/queshield-v1.0.0-x64.apk (64-bit x86)"
echo ""
echo "🎉 QueShield is ready for download!"
