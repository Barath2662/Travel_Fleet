# Travel Fleet - Complete Setup & Build Guide

## 📋 Project Overview

Travel Fleet is a comprehensive fleet management and ride-sharing application with role-based access for:
- **Owner/Admin**: Full control over all features
- **Employee**: Trip management and employee oversight
- **Driver**: Trip execution with GPS tracking and earnings management

---

## 🚀 Features by Role

### Owner/Admin Dashboard
- Dashboard with analytics and overview
- Trip scheduling and management
- Vehicle management and maintenance
- Driver management and payroll
- Employee management
- Billing and invoicing
- Payment tracking
- Alerts and notifications
- Leave request approvals
- Driver salary management

### Employee Dashboard
- Dashboard overview
- Trip scheduling and assignment
- Vehicle information
- Driver management
- Billing management
- Payment tracking
- Alerts notification
- Leave application

### Driver Dashboard
- Trip dashboard
- My assigned trips
- GPS-based trip tracking
- Trip details entry
- Earnings tracking
- Leave application
- Notifications

---

## 🛠️ Prerequisites

### System Requirements
- Flutter SDK 3.3.0 or higher
- Android SDK 21+ (for APK building)
- Dart SDK (included with Flutter)
- Node.js 14+ (for backend)
- MongoDB (for database)

### Tools
- VS Code or Android Studio
- Git
- Android Emulator or Physical Device

---

## 📦 Project Setup

### 1. Backend Setup

```bash
cd backend/
npm install

# Create .env file with the following:
PORT=3000
MONGODB_URI=mongodb://localhost:27017/travel-fleet
JWT_SECRET=your_secret_key_here
```

Start the backend:
```bash
npm start
# or for development with hot reload
npm run dev
```

**Backend runs on**: `http://localhost:3000`

### 2. Flutter App Setup

```bash
cd flutter_app/

# Get dependencies
flutter pub get

# Run on emulator/device
flutter run

# For release build
flutter run --release
```

---

## 📱 Building APK

### Prerequisites for APK Build
1. Java Development Kit (JDK) 11 or higher
2. Android SDK with Build Tools
3. Proper environment variables set

### Build APK

```bash
# Navigate to flutter_app directory
cd flutter_app/

# Clean previous builds
flutter clean

# Get latest dependencies
flutter pub get

# Build APK (debug)
flutter build apk

# Build APK (release)
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Split APK by ABI (optimized size)
flutter build apk --split-per-abi
```

**APK Output Location**: `flutter_app/build/app/outputs/apk/release/app-release.apk`

### APK Installation

```bash
# Install on connected device
flutter install

# Or using adb directly
adb install build/app/outputs/apk/release/app-release.apk
```

---

## 🌐 API Configuration

### Update API Base URL

Edit: `flutter_app/lib/core/services/api_service.dart`

```dart
static const baseUrl = 'http://your-api-server:3000/api';
```

### For Production
- Update to your production backend URL
- Ensure HTTPS is used
- Configure proper CORS headers

---

## 🔐 Authentication

### Login Credentials (Demo)

- **Owner**: owner@example.com / password
- **Employee**: employee@example.com / password
- **Driver**: driver@example.com / password

### Creating New Users

1. Owner can create users via Users management screen
2. Each user gets:
   - Unique email and password
   - Role assignment (owner, employee, driver)
   - Role-specific permissions

---

## 🎨 Theme & UI

### Light Mode
- Primary: Royal Blue (#2563EB)
- Secondary: Emerald (#10B981)
- Background: White (#FFFFFF)

### Dark Mode
- Primary: Light Blue (#60A5FA)
- Secondary: Soft Emerald (#34D399)
- Background: Dark Blue-Gray (#0F172A)

### Switching Themes
- Go to Settings
- Toggle "Dark Mode"
- Theme persists in local storage

---

## 🗺️ GPS & Location Features

### Driver-Specific GPS Features
- Real-time location tracking
- Auto-filling location based on GPS
- Trip route visualization
- Distance calculation
- Location history

### Permissions Required
- ACCESS_FINE_LOCATION
- ACCESS_COARSE_LOCATION
- ACCESS_BACKGROUND_LOCATION (for continuous tracking)

---

## 📊 Database Setup

### MongoDB Collections

```javascript
// Users
{
  name: String,
  email: String (unique),
  password: String (hashed),
  role: String (owner, employee, driver),
  fcmToken: String,
  createdAt: Date,
  updatedAt: Date
}

// Drivers
{
  name: String,
  phone: String,
  licenseNumber: String,
  salaryPerDay: Number,
  bataRate: Number,
  loginEmail: String (optional)
}

// Trips
{
  pickupDateTime: Date,
  customerName: String,
  customerMobile: String,
  pickupLocation: String,
  placesToVisit: [String],
  numberOfDays: Number,
  driverId: ObjectId,
  vehicleId: ObjectId,
  status: String (scheduled, in-progress, completed)
}

// Vehicles
{
  number: String (unique),
  model: String,
  type: String,
  registrationNumber: String,
  status: String (active, inactive, maintenance)
}

// Payments & Billing
{
  tripId: ObjectId,
  driverId: ObjectId,
  amount: Number,
  status: String (pending, completed, failed),
  createdAt: Date
}
```

---

## 🔄 Role-Based Access Control

### Frontend Permission Checks
```dart
// Check if user can perform action
final userRole = auth.userRole; // UserRole enum
if (userRole.canManageDrivers) {
  // Show driver management UI
}
```

### Backend Permission Checks
All API endpoints verify:
1. JWT token validity
2. User role against required permissions
3. Resource ownership (if applicable)

---

## ⚠️ Troubleshooting

### Common Issues

#### APK Build Fails
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk

# For specific error, check build logs
flutter build apk -v
```

#### API Connection Issues
- Verify backend is running
- Check network connectivity
- Update API URL in api_service.dart
- Check firewall settings

#### GPS Not Working
- Enable location services on device
- Grant location permissions
- Check Android SDK tools are installed
- For emulator, set up location in extended controls

#### Theme Not Switching
- Clear app cache: `flutter clean && flutter pub get`
- Check SharedPreferences permissions

#### Database Connection
- Verify MongoDB is running
- Check connection string in .env
- Verify network access to MongoDB

---

## 📚 Project Structure

```
Travel_Fleet/
├── backend/                 # Node.js Express server
│   ├── controllers/        # API business logic
│   ├── models/            # MongoDB schemas
│   ├── routes/            # API endpoints
│   ├── middleware/        # Auth & validation
│   └── server.js          # Entry point
│
└── flutter_app/            # Flutter mobile app
    ├── lib/
    │   ├── core/          # Constants, services, theme
    │   ├── features/      # UI screens by feature
    │   ├── models/        # Data models
    │   ├── providers/     # State management (Riverpod)
    │   ├── routes/        # Navigation
    │   └── main.dart      # App entry
    └── android/           # Android configuration
```

---

## 🚀 Deployment

### Backend Deployment (Render.yaml configured)
See `render.yaml` for automated deployment setup

### Mobile App Deployment

1. **Testing**:
   ```bash
   flutter test
   
   ```

2. **Build Production APK**:
   ```bash
   flutter build apk --release
   ```

3. **Google Play Store**:
   ```bash
   flutter build appbundle --release
   # Upload to Google Play Console
   ```

4. **Direct APK Distribution**:
   - Share APK file with users
   - Ensure device allows installation from unknown sources

---

## 📞 Support & Maintenance

### Debugging
- Enable debug mode: `flutter run -v`
- Check device logs: `adb logcat`
- Firebase Crashlytics integration (recommended)

### Performance Optimization
- Build release APK for production
- Enable ProGuard for code obfuscation
- Monitor API response times
- Implement proper error handling

### Regular Updates
- Keep Flutter SDK updated
- Update dependencies regularly
- Monitor security advisories
- Test on latest Android versions

---

## ✅ Checklist Before Release

- [ ] Backend API is production-ready
- [ ] Database is properly configured
- [ ] All permissions are set in AndroidManifest.xml
- [ ] Theme works in both light and dark modes
- [ ] GPS features work on physical device
- [ ] APK builds without errors
- [ ] All API endpoints are tested
- [ ] Role-based access is verified
- [ ] Error handling is implemented
- [ ] Documentation is complete

---

## 📝 Notes

- All times are in ISO 8601 format (UTC)
- Passwords are hashed with bcrypt (10 rounds)
- JWTs expire after 24 hours
- All API responses include proper HTTP status codes
- Location tracking is background-safe

---

**Last Updated**: April 2025
