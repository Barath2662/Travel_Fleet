# Travel Fleet - Command Reference Guide

## 🚀 Quick Command Reference

### Backend Commands

#### Setup
```bash
cd backend/
npm install                    # Install dependencies
npm install -g nodemon        # Auto-reload on changes
```

#### Running
```bash
npm start                      # Start production server
npm run dev                    # Start with auto-reload
npm run test                   # Run tests
```

#### Database
```bash
# MongoDB required, ensure it's running
mongod                         # Start MongoDB locally
```

---

### Flutter App Commands

#### Setup & Clean
```bash
cd flutter_app/

flutter clean                  # Clean build cache
flutter pub get               # Get dependencies
flutter pub upgrade           # Update dependencies
flutter doctor               # Check environment
```

#### Development
```bash
flutter run                   # Run debug build
flutter run -v               # Run with verbose logging
flutter run --release        # Run release build
```

#### Building

**Debug APK**:
```bash
flutter build apk            # Builds unoptimized APK
```

**Release APK**:
```bash
flutter build apk --release  # Optimized release APK
```

**App Bundle** (Play Store):
```bash
flutter build appbundle --release
```

**Split by ABI** (optimized size):
```bash
flutter build apk --split-per-abi
```

#### Installation
```bash
flutter install              # Install on connected device
adb install app-release.apk # Manual installation via ADB
```

#### Debugging
```bash
flutter logs                 # View device logs
flutter analyze             # Code analysis
flutter test                # Run unit tests
flutter test --coverage     # Test with coverage report
```

---

### Project Navigation

```bash
# Navigate to backend
cd backend/

# Navigate to Flutter app
cd flutter_app/

# View logs from both
# Terminal 1
cd backend && npm start

# Terminal 2
cd flutter_app && flutter run
```

---

## 📂 File Modification Reference

### Configuration Files

#### API Configuration
```
File: flutter_app/lib/core/config/app_config.dart
Change: apiBaseUrl
From: static const String apiBaseUrl = 'http://localhost:3000/api';
To:   static const String apiBaseUrl = 'http://your-server:3000/api';
```

#### Backend Configuration
```
File: backend/.env
Contents:
  PORT=3000
  MONGODB_URI=mongodb://localhost:27017/travel-fleet
  JWT_SECRET=your_secret_key
```

#### Android Configuration
```
File: android/app/build.gradle.kts
Change applicationId:
  applicationId = "com.example.travel_fleet"

File: android/app/src/main/AndroidManifest.xml
Already configured with:
  - INTERNET
  - ACCESS_FINE_LOCATION
  - ACCESS_COARSE_LOCATION
  - CAMERA
  - STORAGE permissions
```

---

## 🔧 Development Workflow

### Starting Development Environment

```bash
# Terminal 1 - Backend
cd backend/
npm run dev
# Output: Server running on http://localhost:3000

# Terminal 2 - Flutter
cd flutter_app/
flutter run
# Output: App running on device/emulator
```

### Making Changes

```bash
# Backend API change
1. Edit file in backend/
2. Server auto-reloads (with nodemon)
3. Test in app

# Flutter UI change
1. Edit file in flutter_app/
2. App hot-reloads (Ctrl+S)
3. Test changes

# Dependency change
1. Update pubspec.yaml or package.json
2. Run: flutter pub get (or npm install)
```

### Testing Workflow

```bash
# Test backend API
curl http://localhost:3000/api/auth/login \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"email":"owner@example.com","password":"password123"}'

# Test on Flutter
flutter run --debug
# Use Ctrl+R for reload
# Use Ctrl+Shift+R for full restart
```

---

## 📦 Build & Deploy Commands

### Local Testing Build

```bash
# Debug build (fast, large file)
flutter build apk
# Output: build/app/outputs/apk/debug/app-debug.apk

# Test on device
flutter install
```

### Production Build

```bash
# Clean & prepare
flutter clean
flutter pub get

# Build release
flutter build apk --release
# Output: build/app/outputs/apk/release/app-release.apk

# Alternative: App Bundle for Play Store
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Deployment

```bash
# Verify APK size
ls -lh build/app/outputs/apk/release/app-release.apk

# Install on test device
adb install build/app/outputs/apk/release/app-release.apk

# Install on multiple devices
adb devices | grep attached | awk '{print $1}' | xargs -I {} adb -s {} install app-release.apk

# View app version
aapt dump badging build/app/outputs/apk/release/app-release.apk | grep version
```

---

## 🐛 Troubleshooting Commands

### Flutter Issues

```bash
# Check Flutter environment
flutter doctor
flutter doctor -v              # Verbose output

# Clear all Flutter cache
flutter clean
rm pubspec.lock
flutter pub get

# Update Flutter
flutter upgrade

# Check device connectivity
adb devices
adb devices -l                 # Detailed info

# View device logs
adb logcat
adb logcat | grep "flutter"
adb logcat -c                  # Clear logs
```

### Backend Issues

```bash
# Check Node installation
node --version
npm --version

# Check port availability
lsof -i :3000                  # Linux/Mac
netstat -ano | findstr :3000   # Windows

# Clear npm cache
npm cache clean --force
npm install

# Test API endpoint
curl http://localhost:3000/api/health

# View backend logs
npm start                      # Shows logs in console
```

### Connection Issues

```bash
# Verify backend is running
curl http://localhost:3000

# Restart backend
pkill -f "node server.js"
npm start

# Restart device/emulator
adb shell reboot              # Device
# Emulator: Close and restart

# Verify network
ping 8.8.8.8
```

---

## 📊 Useful Git Commands

```bash
# Initialize git
git init

# Check status
git status

# Add all changes
git add .

# Commit changes
git commit -m "feat: role-based UI implementation"

# View commit history
git log --oneline

# Create branch
git checkout -b feature/gps-tracking

# Merge branch
git checkout main
git merge feature/gps-tracking

# Push to remote
git push origin main
```

---

## 📱 Android Device Commands

```bash
# List connected devices
adb devices

# Connect wireless (same network)
adb connect device-ip:5555

# Disconnect
adb disconnect

# Reboot device
adb reboot

# Screenshot
adb shell screencap /sdcard/screenshot.png
adb pull /sdcard/screenshot.png ./

# Install APK
adb install app.apk

# Uninstall app
adb uninstall com.example.travel_fleet

# Clear app data
adb shell pm clear com.example.travel_fleet

# Enable debug
adb shell setprop debug.atrace.tags.enableflags 1
```

---

## 🔍 Environment Setup Verification

```bash
# Verify all requirements
echo "Flutter:"
flutter --version

echo "Dart:"
dart --version

echo "Java:"
java -version

echo "Android SDK:"
echo $ANDROID_HOME

echo "Node.js:"
node --version

echo "npm:"
npm --version

echo "MongoDB:"
mongod --version
```

---

## ⚙️ Common Configurations

### Update API URL for Deployment

**File**: `flutter_app/lib/core/config/app_config.dart`

```dart
// Development
static const String apiBaseUrl = 'http://localhost:3000/api';

// Staging
static const String apiBaseUrl = 'https://staging-api.example.com/api';

// Production
static const String apiBaseUrl = 'https://api.example.com/api';
```

### Environment Variables

```bash
# Create backend/.env
PORT=3000
MONGODB_URI=mongodb://your-mongo-server:27017/travel-fleet
JWT_SECRET=your-strong-secret-key
NODE_ENV=production
```

### Firebase Setup (Optional)

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize
firebase init

# Deploy
firebase deploy
```

---

## 🔄 Continuous Development

### Watch Mode

```bash
# Backend - auto-restart on changes
npm run dev

# Flutter - hot reload on save
ctrl+s in editor (or flutter run with --watch)
```

### Live Reload

```bash
# In Flutter app running terminal:
- Type 'r' + Enter     # Hot reload (fast)
- Type 'R' + Enter     # Full restart
- Type 'q' + Enter     # Quit
- Type 'h' + Enter     # Help
```

---

## 📋 Common Tasks

### Create New Feature
```bash
# 1. Create new file
touch lib/features/new_feature/new_feature_page.dart

# 2. Add to routes
edit lib/routes/app_router.dart

# 3. Test
flutter run

# 4. Commit
git add .
git commit -m "feat: add new feature"
```

### Add New Package
```bash
# Add to pubspec.yaml
flutter pub add package_name

# Or manually
flutter pub get

# Use in code
import 'package:package_name/package_name.dart';
```

### Update Dependencies
```bash
flutter pub upgrade        # Check upgradeable packages
flutter pub upgrade --major-versions  # Major version updates

# Rebuild
flutter clean
flutter pub get
flutter run
```

---

## 🚨 Emergency Procedures

### App Won't Start

```bash
flutter clean
flutter pub get
flutter run
```

### Backend Won't Connect

```bash
# Check if running
curl http://localhost:3000

# Restart
pkill -f "node server.js"
npm start

# Check logs
npm start  # Shows console logs
```

### Build Issues

```bash
# Full clean rebuild
flutter clean
rm -rf build/
rm pubspec.lock
flutter pub get
flutter build apk --release
```

---

## 📞 Quick Reference

| Command | Use | File |
|---------|-----|------|
| `flutter run` | Test app | - |
| `flutter build apk --release` | Production APK | - |
| `npm start` | Start backend | backend/ |
| `flutter clean` | Reset build cache | - |
| `adb install x.apk` | Install APK | - |
| `flutter doctor` | Check environment | - |

---

**This guide covers all common commands for developing, testing, building, and deploying Travel Fleet. Keep it handy!**
