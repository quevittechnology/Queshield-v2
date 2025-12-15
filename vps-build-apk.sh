#!/bin/bash

# QueShield VPS Build Script
# Installs Flutter, Android SDK, and builds the APK

set -e

echo "🛡️ QueShield APK Build on VPS"
echo "=============================="
echo ""

# Update system
echo "📦 Updating system..."
apt-get update -qq
apt-get install -y wget curl git unzip xz-utils zip libglu1-mesa openjdk-11-jdk

# Install Flutter
echo "📦 Installing Flutter SDK..."
cd /root
if [ ! -d "flutter" ]; then
    wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
    tar xf flutter_linux_3.24.5-stable.tar.xz
    rm flutter_linux_3.24.5-stable.tar.xz
fi

# Set up Flutter path
export PATH="\$PATH:/root/flutter/bin"
echo 'export PATH="\$PATH:/root/flutter/bin"' >> /root/.bashrc

# Install Android SDK
echo "📦 Installing Android SDK..."
cd /root
if [ ! -d "android-sdk" ]; then
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
    mkdir -p android-sdk/cmdline-tools
    unzip -q commandlinetools-linux-11076708_latest.zip -d android-sdk/cmdline-tools
    mv android-sdk/cmdline-tools/cmdline-tools android-sdk/cmdline-tools/latest
    rm commandlinetools-linux-11076708_latest.zip
fi

# Set Android environment variables
export ANDROID_HOME=/root/android-sdk
export PATH=\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools
echo 'export ANDROID_HOME=/root/android-sdk' >> /root/.bashrc
echo 'export PATH=\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools' >> /root/.bashrc

# Accept Android licenses
yes | \$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses || true

# Install required Android SDK components
echo "📦 Installing Android SDK components..."
\$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# Configure Flutter
echo "⚙️ Configuring Flutter..."
flutter config --android-sdk=\$ANDROID_HOME
flutter config --no-analytics
flutter doctor --android-licenses || true

# Go to project directory
cd /root/queshield-app

# Clean and get dependencies
echo "📦 Getting Flutter dependencies..."
flutter clean
flutter pub get

# Build release APK
echo "🔨 Building release APK..."
flutter build apk --release --split-per-abi

# Copy APK to web directory
echo "📋 Deploying APK..."
mkdir -p /var/www/html/download
cp build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk /var/www/html/download/queshield-v1.0.0-arm.apk
cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk /var/www/html/download/queshield-v1.0.0-arm64.apk
cp build/app/outputs/flutter-apk/app-x86_64-release.apk /var/www/html/download/queshield-v1.0.0-x64.apk

# Set permissions
chmod 644 /var/www/html/download/*.apk
chown www-data:www-data /var/www/html/download/*.apk

echo ""
echo "✅ Build complete!"
echo ""
echo "📱 APK files available at:"
echo "   - http://145.223.19.208/download/queshield-v1.0.0-arm.apk (32-bit ARM)"
echo "   - http://145.223.19.208/download/queshield-v1.0.0-arm64.apk (64-bit ARM)"
echo "   - http://145.223.19.208/download/queshield-v1.0.0-x64.apk (64-bit x86)"
echo ""
echo "🎉 QueShield is ready for download!"
