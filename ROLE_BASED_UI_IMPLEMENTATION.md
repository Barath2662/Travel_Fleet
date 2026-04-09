# Travel Fleet - Role-Based UI Implementation

## 🎯 Overview

The Travel Fleet application has been completely restructured with **role-based UI and permissions** system. Each user role (Owner, Employee, Driver) now has a completely customized dashboard with only the features they need.

---

## 👥 User Roles & Features

### 1️⃣ Owner/Admin Dashboard
**Access Level**: Full system control

**Features**:
- 📊 Dashboard with analytics & system overview
- 🚗 Trip management (schedule, assign, track)
- 🛣️ Vehicle management (add, edit, delete, bata rates)
- 👔 Employee management (create, edit, remove)
- 👨‍💼 Driver management (hire, assign vehicles, manage payroll)
- 💰 Billing & invoicing system
- 💳 Payment tracking & reconciliation
- 🔔 System alerts & notifications
- ✅ Leave request approvals
- 💵 Salary management & payroll processing
- 👥 Manage users (Owner only)

**UI Color Scheme**: Primary Blue (#2563EB)

---

### 2️⃣ Employee Dashboard
**Access Level**: Operational management

**Features**:
- 📊 Dashboard with overview stats
- 🚗 Trip scheduling & assignment
- 🛣️ Vehicle information
- 👨‍💼 Driver oversight & management
- 💰 Billing details
- 💳 Payment information
- 🔔 Alerts & notifications
- 📝 Apply for leave
- ⚙️ Settings & profile

**UI Color Scheme**: Cyan (#06B6D4)

---

### 3️⃣ Driver Dashboard
**Access Level**: Trip execution & personal management

**Features**:
- 📊 Dashboard with trip alerts
- 🚗 My assigned trips
- 🗺️ GPS-based trip tracking
- 📍 Auto-location based on GPS
- 📝 Enter trip details
- 💰 Track earnings (daily, weekly, monthly, total)
- 📝 Apply for leave
- 🔔 Notifications
- ⚙️ Profile & settings

**Special Features**:
- Real-time GPS tracking
- Auto-filling location coordinates
- Trip distance calculation
- Earnings breakdown by trip type
- Leave request system

**UI Color Scheme**: Orange (#F97316)

---

## 🏗️ Architecture

### Navigation Structure

```
MainApp
├── Login Screen (unauthenticated)
│
└── Dashboard (authenticated)
    ├── OwnerDashboardPage (if role == owner)
    │   ├── Home
    │   ├── Trips
    │   ├── Vehicles
    │   ├── Drivers
    │   ├── Employees
    │   ├── Billing
    │   ├── Payments
    │   ├── Alerts
    │   └── Settings
    │
    ├── EmployeeDashboardPage (if role == employee)
    │   ├── Home
    │   ├── Trips
    │   ├── Vehicles
    │   ├── Drivers
    │   ├── Billing
    │   ├── Payments
    │   ├── Alerts
    │   └── Settings
    │
    └── DriverDashboardPage (if role == driver)
        ├── Home
        ├── My Trips
        ├── Earnings
        ├── Alerts
        └── Settings
```

---

## 🔐 Permission System

### Role-Based Permissions

```dart
enum UserRole { owner, employee, driver }

// Example checks
if (auth.userRole.canManageDrivers) { /* show feature */ }
if (auth.userRole.canScheduleTrip) { /* enable button */ }
if (auth.userRole.canUseGPS) { /* enable location tracking */ }
```

### Permission Matrix

| Operation | Owner | Employee | Driver |
|-----------|-------|----------|--------|
| Schedule Trip | ✅ | ✅ | ✅ |
| Assign Vehicle/Driver | ✅ | ✅ | ❌ |
| Manage Vehicles | ✅ | ✅ | ❌ |
| Manage Employees | ✅ | ❌ | ❌ |
| Manage Drivers | ✅ | ✅ | ❌ |
| View Billing | ✅ | ✅ | ❌ |
| Approve Leaves | ✅ | ❌ | ❌ |
| Manage Salary | ✅ | ❌ | ❌ |
| Update Driver Earnings | ✅ | ✅ | ❌ |
| Start/End Trip | ❌ | ❌ | ✅ |
| Enter Trip Details | ❌ | ❌ | ✅ |
| Use GPS Tracking | ❌ | ❌ | ✅ |
| View Own Earnings | ✅ | ❌ | ✅ |
| Apply Leave | ✅ | ✅ | ✅ |

---

## 🎨 UI/UX Enhancements

### Enhanced Components

1. **Enhanced Cards** - Animated cards with hover effects
2. **Stat Cards** - Cards displaying metrics with icons
3. **Role-Based Containers** - Feature cards with descriptions
4. **Info Chips** - Compact information display

### Theme Support

#### Light Mode
- Primary: Royal Blue (#2563EB)
- Secondary: Emerald (#10B981)
- Background: White
- Text: Dark Blue

#### Dark Mode
- Primary: Light Blue (#60A5FA)
- Secondary: Soft Emerald (#34D399)
- Background: Dark Navy (#0F172A)
- Text: Light Gray

### Animations
- Smooth page transitions (300ms)
- Card press animations
- List item animations
- Theme transition animations

---

## 🗺️ GPS & Location Features (Driver Only)

### Capabilities
- Real-time location tracking
- Auto-location filling via GPS
- Distance calculation between points
- Address lookup from coordinates
- Location history
- Background location tracking

### Implementation
```dart
final locationService = LocationService();

// Get current position
final position = await locationService.getCurrentPosition();

// Get location updates stream
final locationStream = locationService.getLocationStream();

// Get address from coordinates
final address = await locationService.getAddressFromCoordinates(
  latitude,
  longitude,
);

// Calculate distance
final distanceKm = locationService.calculateDistance(
  startLat, startLon, endLat, endLon,
);
```

### Permissions Required
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `ACCESS_BACKGROUND_LOCATION`

---

## 📱 APK Build Instructions

### Prerequisites
```bash
# Ensure Flutter is installed
flutter --version

# Ensure dependencies are available
flutter pub get

# Build dependencies
flutter build apk --help
```

### Build Commands

**Debug APK**:
```bash
flutter build apk
# Output: flutter_app/build/app/outputs/apk/debug/app-debug.apk
```

**Release APK**:
```bash
flutter build apk --release
# Output: flutter_app/build/app/outputs/apk/release/app-release.apk
```

**App Bundle** (for Play Store):
```bash
flutter build appbundle --release
# Output: flutter_app/build/app/outputs/bundle/release/app-release.aab
```

**Split APK by ABI** (optimized):
```bash
flutter build apk --split-per-abi
```

### Installation on Device
```bash
# Install on connected device
flutter install

# Or manually
adb install build/app/outputs/apk/release/app-release.apk
```

---

## 🔧 Configuration

### API Configuration
Edit `lib/core/config/app_config.dart`:
```dart
static const String apiBaseUrl = 'http://your-server:3000/api';
```

### Environment Setup
```dart
// Set environment
EnvironmentConfig.setEnvironment(Environment.production);

// Get current base URL
final url = EnvironmentConfig.baseUrl;
```

### Feature Flags
```dart
// In app_config.dart
static const bool enableGPS = true;
static const bool enableNotifications = true;
static const bool enableOfflineMode = false;
```

---

## 🐛 Error Handling

### Custom Error Handler
```dart
import 'core/services/error_handler.dart';

// Handle errors
AppErrorHandler.handleError(
  context,
  exception,
  title: 'Operation Failed',
  onRetry: () { /* retry logic */ },
);

// Show snackbar
AppErrorHandler.showSnackBar(
  context,
  'Successfully saved!',
  isError: false,
);
```

### Exception Types
- `AppException` - Base exception
- `NetworkException` - Network related errors
- `AuthException` - Authentication failures
- `ValidationException` - Input validation errors
- `PermissionException` - Permission denied errors

---

## ✅ Input Validation

### Validators
```dart
import 'core/utils/validators.dart';

AppValidator.validateEmail('user@example.com');
AppValidator.validatePassword('password123');
AppValidator.validatePhone('+1234567890');
AppValidator.validateAmount('100.50');
AppValidator.validateLicenseNumber('DL1234567890');
```

---

## 📊 State Management

**Framework**: Riverpod 2.6.1

### Key Providers
- `authProvider` - Authentication state
- `themeModeProvider` - Theme toggle
- `appStateProvider` - App state (trips, drivers, etc.)

### Usage
```dart
final auth = ref.watch(authProvider);
final role = auth.userRole;
final isAuthenticated = auth.isAuthenticated;
```

---

## 📊 Database Models

### User
```json
{
  "_id": "ObjectId",
  "name": "String",
  "email": "String",
  "password": "String (hashed)",
  "role": "owner|employee|driver",
  "createdAt": "DateTime",
  "updatedAt": "DateTime"
}
```

### Driver
```json
{
  "_id": "ObjectId",
  "name": "String",
  "phone": "String",
  "licenseNumber": "String",
  "salaryPerDay": "Number",
  "bataRate": "Number",
  "loginEmail": "String (optional)",
  "totalWorkingDays": "Number",
  "totalWorkingHours": "Number",
  "totalTripsCompleted": "Number",
  "totalBataEarned": "Number"
}
```

---

## 🚀 Deployment

### Backend (Node.js)
1. Configure environment variables
2. Connect to MongoDB
3. Deploy using provided `render.yaml`

### Frontend (Flutter APK)
1. Build release APK (see APK Build section)
2. Sign the APK with release keystore
3. Distribute via app store or direct distribution
4. Update API URL for production

---

## 🧪 Testing

### Test Credentials
```
Owner:
  Email: owner@example.com
  Password: password123
  Role: owner

Employee:
  Email: employee@example.com
  Password: password123
  Role: employee

Driver:
  Email: driver@example.com
  Password: password123
  Role: driver
```

### Test Checklist
- [ ] Login with each role
- [ ] Verify appropriate dashboard loads
- [ ] Test role-specific features
- [ ] Check theme switching
- [ ] Verify GPS functionality (driver)
- [ ] Test offline behavior
- [ ] Check data persistence
- [ ] Verify error handling

---

## 📚 File Structure

```
lib/
├── core/
│   ├── config/
│   │   └── app_config.dart
│   ├── constants/
│   │   └── role_permissions.dart
│   ├── helpers/
│   │   └── role_based_helper.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   ├── auth_storage_service.dart
│   │   ├── error_handler.dart
│   │   ├── location_service.dart
│   │   └── fcm_service.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── utils/
│   │   └── validators.dart
│   └── widgets/
│       └── enhanced_widgets.dart
│
├── features/
│   ├── auth/
│   │   └── login_page.dart
│   ├── dashboard/
│   │   ├── dashboard_page.dart (dispatcher)
│   │   ├── owner_dashboard_page.dart
│   │   ├── employee_dashboard_page.dart
│   │   └── driver_dashboard_page.dart
│   ├── drivers/
│   │   ├── drivers_page.dart
│   │   └── driver_earnings_page.dart
│   ├── trips/
│   ├── vehicles/
│   ├── billing/
│   ├── payments/
│   ├── notifications/
│   ├── settings/
│   └── users/
│
├── models/
│   ├── app_user.dart
│   ├── driver.dart
│   ├── trip.dart
│   ├── vehicle.dart
│   ├── payment.dart
│   ├── bill.dart
│   ├── app_notification.dart
│   └── app_notification.dart
│
├── providers/
│   ├── auth_provider.dart
│   ├── theme_mode_provider.dart
│   └── app_state_provider.dart
│
├── routes/
│   └── app_router.dart
│
└── main.dart
```

---

## 🎓 Best Practices Implemented

1. **Role-Based Access Control**: Permissions checked at UI and API levels
2. **Error Handling**: Comprehensive error handling with user-friendly messages
3. **Input Validation**: All user inputs validated before submission
4. **State Management**: Centralized state using Riverpod
5. **Theme Support**: Full light and dark mode support
6. **Responsive Design**: Optimized for phones and tablets
7. **Animations**: Smooth transitions and visual feedback
8. **Code Organization**: Clear folder structure and separation of concerns
9. **Documentation**: Inline comments and comprehensive guides

---

## 🔍 Troubleshooting

### Common Issues

**APK Build Fails**
```bash
flutter clean
flutter pub get
flutter build apk -v
```

**GPS Not Working**
- Enable location services
- Grant permissions in app settings
- Check device location accuracy

**API Connection Issues**
- Verify backend is running
- Check API URL configuration
- Test network connectivity

**Theme Not Switching**
```bash
flutter clean
flutter pub get
```

**Permission Denied**
- Ensure user has required role
- Check backend authorization
- Verify token is valid

---

## 📝 Changelog

### v1.0.0 - Initial Release
- ✅ Role-based UI implementation
- ✅ Owner/Admin dashboard with full features
- ✅ Employee dashboard with operational features
- ✅ Driver dashboard with GPS tracking
- ✅ Enhanced UI with animations
- ✅ Light and dark theme support
- ✅ Permission system
- ✅ Error handling
- ✅ Input validation
- ✅ APK build configuration

---

## 📞 Support

For issues or questions:
1. Check the BUILD_AND_SETUP_GUIDE.md
2. Review error logs
3. Test with demo credentials
4. Verify backend connectivity

---

**Last Updated**: April 2025
**Version**: 1.0.0
**Status**: Production Ready
