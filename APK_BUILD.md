# Building Android APK for Travel Fleet

This guide explains how to build a release APK for your Flutter app that connects to the Render backend.

## Prerequisites

1. **Flutter SDK** - [Install Flutter](https://flutter.dev/docs/get-started/install)
2. **Android SDK** - Comes with Android Studio or install separately
3. **Java Development Kit (JDK)** - Android requires JDK 11 or later
4. **Git** - For version control
5. **Backend deployed on Render** - Ensure `https://travel-fleet.onrender.com` is running

Verify installations:
```bash
flutter --version
java -version
```

## Setup Steps

### 1. Navigate to Flutter App Directory

```bash
cd flutter_app
```

### 2. Get Dependencies

```bash
flutter pub get
```

### 3. Clean Build (Recommended for first builds)

```bash
flutter clean
flutter pub get
```

## Building the APK

### Option A: Release APK (Recommended for Production)

```bash
flutter build apk --release
```

**Output Location:**
```
flutter_app/build/app/outputs/flutter-apk/app-release.apk
```

**Characteristics:**
- Optimized for size and performance
- Minified code
- No debug symbols
- Recommended for distribution on Google Play Store

### Option B: Debug APK (For Testing on Devices)

```bash
flutter build apk --debug
```

**Output Location:**
```
flutter_app/build/app/outputs/flutter-apk/app-debug.apk
```

**Characteristics:**
- Larger file size
- Debug symbols included
- Better for local testing

### Option C: Split APKs by Processor Architecture

```bash
flutter build apk --release --split-per-abi
```

Creates smaller APKs for specific device architectures:
- `app-armeabi-v7a-release.apk` (32-bit)
- `app-arm64-v8a-release.apk` (64-bit, recommended)

**Why split APKs?**
- Smaller download size
- Better performance
- Recommended for Play Store

## Building Bundle (Google Play Store)

For distribution on Google Play Store, use Android App Bundle:

```bash
flutter build appbundle --release
```

**Output Location:**
```
flutter_app/build/app/outputs/bundle/release/app-release.aab
```

This is the modern recommended format for Play Store uploads.

## Testing the APK

### Option 1: Physical Android Device

1. Connect your Android device via USB
2. Enable Developer Mode on device
3. Run:
```bash
flutter install
flutter run
```

Or install the APK directly:
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Option 2: Android Emulator

1. Start emulator from Android Studio
2. Run:
```bash
flutter run
```

### Option 3: Manual APK Installation

1. Transfer APK to device
2. Open file manager and tap the APK
3. Follow installation prompts

## Troubleshooting

### Error: "Could not find or load main class"
- **Solution**: Ensure JDK is properly installed and JAVA_HOME is set
```bash
export JAVA_HOME=/path/to/jdk
```

### Error: "Gradle build failed"
- **Solution**: Clean and rebuild
```bash
flutter clean
flutter pub get
flutter build apk --release
```

### Error: "minSdkVersion error"
- **Solution**: Check `flutter_app/android/app/build.gradle.kts`
- Ensure minSdkVersion matches Flutter's requirements (usually 21+)

### APK is too large
- **Solution**: Use split APKs or bundle format
```bash
flutter build apk --release --split-per-abi
# or
flutter build appbundle --release
```

### Backend URL issues
- **Solution**: Verify the API URL in [flutter_app/lib/core/constants/app_constants.dart](flutter_app/lib/core/constants/app_constants.dart)
- Current production URL: `https://travel-fleet.onrender.com/api`
- Test connection:
```bash
curl https://travel-fleet.onrender.com/health
```

## APK Signing (For Play Store)

### Generate Keystore

```bash
keytool -genkey -v -keystore ~/my-release-key.keystore \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias my-key-alias
```

### Configure Signing in Flutter

Create `flutter_app/android/key.properties`:
```properties
storePassword=<your_store_password>
keyPassword=<your_key_password>
keyAlias=my-key-alias
storeFile=<path_to_keystore_file>
```

### Build Signed APK

```bash
flutter build apk --release
# or
flutter build appbundle --release
```

## Distribution

### Google Play Store
1. Create [Google Play Developer Account](https://play.google.com/apps/publish/)
2. Create new app
3. Upload release bundle (`.aab`)
4. Fill store listing details
5. Submit for review

### Direct APK Distribution
1. Host APK on server
2. Share download link
3. Users install from "Unknown sources" (enable in device settings)

## CI/CD Automation

For automated builds, add to your `.github/workflows/build.yml`:

```yaml
name: Flutter Build

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  build-apk:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: cd flutter_app && flutter pub get
      - run: cd flutter_app && flutter build apk --release --split-per-abi
      - uses: actions/upload-artifact@v3
        with:
          name: apk
          path: flutter_app/build/app/outputs/flutter-apk/
```

## Summary

| Build Type | Command | Output | Use Case |
|-----------|---------|--------|----------|
| Release APK | `flutter build apk --release` | Single APK | General distribution |
| Split APK | `flutter build apk --release --split-per-abi` | Multiple APKs | Play Store |
| Bundle | `flutter build appbundle --release` | .aab | Play Store (recommended) |
| Debug APK | `flutter build apk --debug` | Debug APK | Local testing |

## Testing Checklist

Before releasing, verify:
- [ ] Backend URL works: `https://travel-fleet.onrender.com/health`
- [ ] App starts without crashes
- [ ] All API endpoints work (auth, trips, payments, etc.)
- [ ] File permissions set correctly in `AndroidManifest.xml`
- [ ] Internet permission enabled in manifest
- [ ] No hardcoded localhost URLs in code

## Next Steps

1. **Deploy Backend**: Ensure Render is running
2. **Build APK**: Use commands above
3. **Test on Device**: Install and verify functionality
4. **Distribute**: Share APK or upload to Play Store
