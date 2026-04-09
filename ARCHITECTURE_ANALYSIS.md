# Travel Fleet App - Architecture Analysis Report

## Executive Summary

Travel Fleet is a comprehensive fleet management application built with **Flutter** (frontend) and **Node.js/Express** (backend). The app supports **three user roles** (Owner, Employee, Driver) with role-based access control implemented at both backend and frontend levels. The frontend uses **Flutter Riverpod** for state management, **Material 3** design system, and supports **light/dark themes**.

---

## 1. Authentication & Role Management Implementation

### 1.1 Backend User Model
**File:** [backend/models/User.js](backend/models/User.js)

```javascript
const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    password: { type: String, required: true, minlength: 6 },
    role: {
      type: String,
      enum: ['owner', 'employee', 'driver'],
      default: 'employee',
    },
    fcmToken: { type: String }, // For Firebase Cloud Messaging
  },
  { timestamps: true }
);
```

**Key Features:**
- Three defined roles: `owner`, `employee`, `driver`
- Password stored with bcrypt hashing
- FCM token for push notifications
- Timestamps for created/updated tracking

### 1.2 Backend Authentication Controller
**File:** [backend/controllers/authController.js](backend/controllers/authController.js)

**Authentication Methods:**
- `register()` - Create new user with default role 'employee'
- `login()` - Validates credentials, saves FCM token, returns JWT token
- `createUser()` - Owner-only endpoint to create users with specific roles
- `getProfile()` - Retrieve authenticated user profile
- `updateProfile()` - Update name, email, or password

**Response Format:**
```json
{
  "_id": "user_id",
  "name": "User Name",
  "email": "user@example.com",
  "role": "owner|employee|driver",
  "token": "jwt_token_here"
}
```

### 1.3 Frontend AppUser Model
**File:** [flutter_app/lib/models/app_user.dart](flutter_app/lib/models/app_user.dart)

```dart
class AppUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String token;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      token: json['token'] as String,
    );
  }
}
```

### 1.4 Frontend Auth Provider (State Management)
**File:** [flutter_app/lib/providers/auth_provider.dart](flutter_app/lib/providers/auth_provider.dart)

**AuthState Properties:**
```dart
class AuthState {
  final String? token;
  final String? role;      // Stored role for quick access
  final String? name;
  final String? email;
  final bool loading;
  final String? error;
}
```

**AuthNotifier Methods:**
- `init()` - Load session from SharedPreferences on app start
- `login(email, password)` - Authenticate and store session
- `register(name, email, password, role)` - Create new user account
- `logout()` - Clear session
- `updateProfile(payload)` - Update user information

**Session Storage:**
Uses `AuthStorageService` to persist auth data in SharedPreferences:
```dart
// Keys stored locally
'auth_token', 'auth_role', 'auth_name', 'auth_email'
```

### 1.5 Authentication Flow

**Login/Register Flow:**
1. User enters email/password (and role during registration)
2. Frontend sends request to backend: `POST /auth/login` or `POST /auth/register`
3. Backend validates credentials and returns user data + JWT token
4. Frontend stores session using `AuthStorageService`
5. Auth provider updates state with token and role
6. Router checks if token exists to determine initial route

---

## 2. UI/Screen Structure

### 2.1 Screen Hierarchy

**File:** [flutter_app/lib/features](flutter_app/lib/features)

```
lib/features/
├── auth/
│   └── login_page.dart          # Login/Register combined page
├── dashboard/
│   └── dashboard_page.dart      # Main shell with navigation
├── home/
│   └── home_page.dart           # Dashboard with stats
├── trips/
│   └── trips_page.dart          # Create & manage trips
├── vehicles/
│   └── vehicles_page.dart       # Add & manage vehicles
├── drivers/
│   └── drivers_page.dart        # Manage drivers
├── payments/
│   └── payments_page.dart       # Payment records
├── billing/
│   └── billing_page.dart        # Billing/invoices
├── notifications/
│   └── notifications_page.dart  # Alerts & notifications
├── settings/
│   └── settings_page.dart       # Profile & preferences
└── users/
    └── users_page.dart          # User management (owner only)
```

### 2.2 DashboardPage (Main Shell)
**File:** [flutter_app/lib/features/dashboard/dashboard_page.dart](flutter_app/lib/features/dashboard/dashboard_page.dart)

**Structure:**
- **AppBar:** Shows app name and current user role
- **Navigation:** 
  - Drawer on mobile (< 900px width)
  - NavigationRail on desktop (>= 900px width)
- **Role-Based Menu Item:** Users menu only shown for `owner` role

```dart
final menuItems = [
  const _MenuItem(label: 'Home', icon: Icons.home_outlined, page: HomePage()),
  const _MenuItem(label: 'Trips', icon: Icons.route_outlined, page: TripsPage()),
  const _MenuItem(label: 'Billing', icon: Icons.receipt_long_outlined, page: BillingPage()),
  const _MenuItem(label: 'Vehicles', icon: Icons.directions_car_outlined, page: VehiclesPage()),
  const _MenuItem(label: 'Drivers', icon: Icons.badge_outlined, page: DriversPage()),
  const _MenuItem(label: 'Payments', icon: Icons.payments_outlined, page: PaymentsPage()),
  const _MenuItem(label: 'Alerts', icon: Icons.notifications_none, page: NotificationsPage()),
  const _MenuItem(label: 'Settings', icon: Icons.settings_outlined, page: SettingsPage()),
  if (auth.role == 'owner') const _MenuItem(label: 'Users', icon: Icons.group_outlined, page: UsersPage()),
];
```

### 2.3 Individual Screen Descriptions

#### HomePage
**File:** [flutter_app/lib/features/home/home_page.dart](flutter_app/lib/features/home/home_page.dart)

**Displays:**
- Welcome card with user's name
- Statistics tiles:
  - Trips count
  - Bills (hidden for drivers)
  - Vehicles count
  - Drivers count
  - Payments count
  - My Earnings (only for drivers)
  - Unread alerts count

**Special Logic:** Driver earnings calculation:
```dart
double _driverEarnings(driver) {
  final salaryFromDays = driver.totalWorkingDays * driver.salaryPerDay;
  final salaryFromHours = driver.totalWorkingHours * (driver.salaryPerDay / 8);
  final tripSalary = driver.totalTripsCompleted * driver.salaryPerTrip;
  return (salaryFromDays > salaryFromHours ? salaryFromDays : salaryFromHours) 
    + tripSalary + driver.totalBataEarned;
}
```

#### TripsPage
**File:** [flutter_app/lib/features/trips/trips_page.dart](flutter_app/lib/features/trips/trips_page.dart)

**Displays:**
- Form to create new trips (owner/employee only)
- Fields: customer name, mobile, pickup location, places to visit, days, driver (dropdown), vehicle (dropdown)
- List of trips with status

**Data Model:**
```dart
class TripModel {
  final String id;
  final String customerName;
  final String customerMobile;
  final String pickupLocation;
  final String status;  // pending, in_progress, completed, cancelled
  final int numberOfDays;
  final String? driverName;      // Populated from driverId object
  final String? vehicleNumber;   // Populated from vehicleId object
  final double driverBataAssigned;
}
```

#### VehiclesPage
**File:** [flutter_app/lib/features/vehicles/vehicles_page.dart](flutter_app/lib/features/vehicles/vehicles_page.dart)

**Displays:**
- Form to add vehicles
- Fields: number, category (dropdown: sedan/suv/mvp/van/hatchback/luxury/mini_bus/other), seats, FC date, insurance date, PUC date, next service KM
- Vehicle list
- Bata rate management per category

#### DriversPage
**File:** [flutter_app/lib/features/drivers/drivers_page.dart](flutter_app/lib/features/drivers/drivers_page.dart)

**Planned Features:** Driver management (create, view, edit drivers)

#### PaymentsPage
**File:** [flutter_app/lib/features/payments/payments_page.dart](flutter_app/lib/features/payments/payments_page.dart)

**Planned Features:** Payment management and history

#### BillingPage
**File:** [flutter_app/lib/features/billing/billing_page.dart](flutter_app/lib/features/billing/billing_page.dart)

**Planned Features:** Invoice generation and billing records

#### NotificationsPage
**File:** [flutter_app/lib/features/notifications/notifications_page.dart](flutter_app/lib/features/notifications/notifications_page.dart)

**Planned Features:** Alert/notification management

#### SettingsPage
**File:** [flutter_app/lib/features/settings/settings_page.dart](flutter_app/lib/features/settings/settings_page.dart)

**Displays:**
- Profile settings form (name, email, password)
- Theme mode selector (light/dark/system)
- Update button with loading state

#### UsersPage
**File:** [flutter_app/lib/features/users/users_page.dart](flutter_app/lib/features/users/users_page.dart)

**Access:** Owner only
**Displays:**
- Role gate checking: "Only owner can manage users from this menu."
- Form to add users (name, email, password, role dropdown)
- User list with edit/delete options (if implemented)

#### LoginPage
**File:** [flutter_app/lib/features/auth/login_page.dart](flutter_app/lib/features/auth/login_page.dart)

**Displays:**
- Toggle between Login and Register modes
- Login: Email + Password fields
- Register: Name + Email + Password + Role dropdown (owner/employee/driver)
- Error message display
- Loading indicator in button

---

## 3. Routing & Navigation Implementation

### 3.1 Router Configuration
**File:** [flutter_app/lib/routes/app_router.dart](flutter_app/lib/routes/app_router.dart)

**Defined Routes:**
```dart
class AppRouter {
  static const login = '/login';
  static const dashboard = '/dashboard';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardPage());
      default:
        return MaterialPageRoute(builder: (_) => const LoginPage());
    }
  }
}
```

### 3.2 App Entry Point (main.dart)
**File:** [flutter_app/lib/main.dart](flutter_app/lib/main.dart)

**Navigation Logic:**
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final auth = ref.watch(authProvider);
  final themeMode = ref.watch(themeModeProvider);

  return MaterialApp(
    title: 'Travel Fleet',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: themeMode,
    // Initial route based on auth token
    initialRoute: auth.token == null ? AppRouter.login : AppRouter.dashboard,
    onGenerateRoute: AppRouter.generateRoute,
  );
}
```

**Route Determination:**
- If `auth.token == null` → Show `/login`
- If `auth.token != null` → Show `/dashboard`

### 3.3 Navigation Methods

**Dashboard Screen-to-Screen Navigation:**
All navigation happens within DashboardPage via index-based page switching (no route stack):
```dart
// In DashboardPage._DashboardPageState
int _index = 0;  // Current screen index

final menuItems = [/* screen definitions */];
// When menu item tapped:
setState(() => _index = i);
Navigator.pop(context);  // Close drawer on mobile

// Body shows: menuItems[_index].page
```

**Login/Logout Navigation:**
```dart
// After login
Navigator.pushReplacementNamed(context, AppRouter.dashboard);

// After logout
Navigator.pushNamedAndRemoveUntil(context, AppRouter.login, (_) => false);
```

---

## 4. Current Screens & Their Display

| Screen | File | Purpose | Visible To | Status |
|--------|------|---------|-----------|--------|
| **Login** | `auth/login_page.dart` | Authentication | All | ✅ Implemented |
| **Home** | `home/home_page.dart` | Dashboard stats | All | ✅ Implemented |
| **Trips** | `trips/trips_page.dart` | Trip management | All | ✅ Implemented |
| **Vehicles** | `vehicles/vehicles_page.dart` | Vehicle management | All | ✅ Implemented |
| **Drivers** | `drivers/drivers_page.dart` | Driver management | All | 🔲 Stub |
| **Payments** | `payments/payments_page.dart` | Payment records | All | 🔲 Stub |
| **Billing** | `billing/billing_page.dart` | Invoices | All | 🔲 Stub |
| **Notifications** | `notifications/notifications_page.dart` | Alerts | All | 🔲 Stub |
| **Settings** | `settings/settings_page.dart` | Profile & theme | All | ✅ Implemented |
| **Users** | `users/users_page.dart` | User management | Owner Only | ✅ Implemented |

**Legend:** ✅ Implemented | 🔲 Stub (placeholder screen)

---

## 5. User Role Implementation & Usage

### 5.1 Role Definitions

| Role | Description | Capabilities |
|------|-------------|--------------|
| **owner** | Company owner/admin | Full access: create users, drivers, vehicles, trips, manage payments/billing |
| **employee** | Staff member | Create/manage drivers, vehicles, trips, payments; cannot manage users |
| **driver** | Driver account | View own trips & earnings, start/end trips, apply for leave |

### 5.2 Role-Based Access Control (RBAC)

#### Backend Implementation
**File:** [backend/middleware/authMiddleware.js](backend/middleware/authMiddleware.js)

```javascript
const authorizeRoles = (...roles) => (req, res, next) => {
  if (!req.user || !roles.includes(req.user.role)) {
    res.status(403);
    throw new Error('Forbidden: insufficient permissions');
  }
  next();
};
```

#### Endpoint Role Restrictions

**Auth Routes:** [backend/routes/authRoutes.js](backend/routes/authRoutes.js)
- `POST /auth/users` - **owner only** (create users)

**Driver Routes:** [backend/routes/driverRoutes.js](backend/routes/driverRoutes.js)
- `POST /driver` - **owner, employee**
- `PUT /driver/:id/leave/approve` - **owner only**
- `GET /driver/:id/payroll` - **owner, employee, driver** (can view own payroll)

**Vehicle Routes:** [backend/routes/vehicleRoutes.js](backend/routes/vehicleRoutes.js)
- `POST /vehicle` - **owner, employee**
- `PUT /vehicle/:id` - **owner, employee**

**Trip Routes:** [backend/routes/tripRoutes.js](backend/routes/tripRoutes.js)
- `POST /trip` - **owner, employee**
- `PUT /trip/:id` - **owner, employee**
- `PUT /trip/:id/start` - **driver only**
- `PUT /trip/:id/end` - **driver only**
- `PUT /trip/:id/bata` - **owner, employee**

**Payment Routes:** [backend/routes/paymentRoutes.js](backend/routes/paymentRoutes.js)
- `POST /payment` - **owner, employee**
- `PUT /payment/:id` - **owner, employee**

### 5.3 Frontend Role-Based Rendering

#### Dashboard Menu Filtering
```dart
// ShowUsers menu only for owner
if (auth.role == 'owner') 
  const _MenuItem(label: 'Users', icon: Icons.group_outlined, page: UsersPage());
```

#### HomePage Stats Filtering
```dart
// Hide Bills stat for drivers
if (auth.role != 'driver')
  _StatTile(title: 'Bills', value: state.bills.length.toString(), ...);

// Show earnings only for drivers
if (auth.role == 'driver')
  _StatTile(title: 'My Earnings', value: earning.toStringAsFixed(0), ...);
```

#### UsersPage Access Gate
```dart
if (role != 'owner') {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Text('Only owner can manage users from this menu.'),
    ),
  );
}
```

### 5.4 Current Role Usage Summary

- ✅ **Role stored:** In auth provider state
- ✅ **Role persisted:** In SharedPreferences via AuthStorageService
- ✅ **Role verified:** On backend via JWT token
- ✅ **Menu filtering:** Based on role
- ✅ **Screen access:** Limited for owner-only screens
- ✅ **API authorization:** Enforced on backend endpoints
- ⚠️ **API call filtering:** Not yet implemented on frontend (sends all requests regardless of role)

---

## 6. Theme Implementation

### 6.1 Theme Configuration
**File:** [flutter_app/lib/core/theme/app_theme.dart](flutter_app/lib/core/theme/app_theme.dart)

**Color Scheme:**

**Light Theme:**
- Primary: Royal Blue (#2563EB)
- Secondary: Emerald (#10B981)
- Surface: White (#FFFFFF)
- Background: Light Slate (#F8FAFC)
- Text Primary: Dark Navy (#0F172A)

**Dark Theme:**
- Primary: Light Blue (#60A5FA)
- Secondary: Soft Emerald (#34D399)
- Surface: Slate 800 (#1E293B)
- Background: Navy (#0F172A)
- Text Primary: Light Slate (#F8FAFC)

### 6.2 Material 3 Support
```dart
static final lightTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Inter',
  colorScheme: ColorScheme.fromSeed(
    seedColor: _brandPrimaryLight,
    secondary: _brandSecondaryLight,
    surface: _surfaceLight,
    background: _backgroundLight,
    brightness: Brightness.light,
  ),
  // ... component themes (AppBar, Card, Button, TextField, etc.)
);
```

### 6.3 Theme Mode Provider
**File:** [flutter_app/lib/providers/theme_mode_provider.dart](flutter_app/lib/providers/theme_mode_provider.dart)

**Features:**
- Supported modes: `ThemeMode.light`, `ThemeMode.dark`, `ThemeMode.system`
- Persists preference to SharedPreferences
- Default: System mode
- Switch available in Settings page

```dart
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
```

### 6.4 Theme Usage in main.dart
```dart
return MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: themeMode,  // From provider
  // ...
);
```

### 6.5 Customized Components

- **AppBar:** Centered title, no elevation, transparent bg
- **Cards:** Rounded 16px, shadow, custom margin
- **Buttons:** Elevated, Outlined, Text variants with consistent styling
- **InputDecorations:** Filled background, rounded border, focus states
- **ListTiles:** Rounded shape, custom padding, branded icon color
- **FloatingActionButton:** Rounded square shape, branded colors
- **Dividers:** Custom color and spacing

---

## 7. Role-Based Access Control (RBAC) & Permissions Logic

### 7.1 Current RBAC Implementation

#### Backend Protection
**Token Verification Middleware:** [backend/middleware/authMiddleware.js](backend/middleware/authMiddleware.js)
```javascript
const protect = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401);
    throw new Error('Unauthorized: missing token');
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = await User.findById(decoded.id).select('-password');
    if (!req.user) {
      res.status(401);
      throw new Error('Unauthorized: user not found');
    }
    next();
  } catch (error) {
    res.status(401);
    throw new Error(`Unauthorized: ${error.message}`);
  }
};
```

All API routes use `protect` middleware before `authorizeRoles`.

#### Frontend RBAC Gaps
- ✅ Menu items filtered by role
- ✅ Screens rendered conditionally
- ❌ No API call interception/blocking based on role
- ❌ No pre-flight role checks before triggering API calls

### 7.2 RBAC Matrix

| Action | Owner | Employee | Driver | Backend Check |
|--------|-------|----------|--------|----------------|
| Create User | ✅ | ❌ | ❌ | ✅ |
| Create Driver | ✅ | ✅ | ❌ | ✅ |
| Approve Leave | ✅ | ❌ | ❌ | ✅ |
| Create Trip | ✅ | ✅ | ❌ | ✅ |
| Start Trip | ❌ | ❌ | ✅ | ✅ |
| End Trip | ❌ | ❌ | ✅ | ✅ |
| Add Advance | ✅ | ✅ | ✅ | ✅ |
| Create Payment | ✅ | ✅ | ❌ | ✅ |
| Create Vehicle | ✅ | ✅ | ❌ | ✅ |

---

## 8. Key Files Summary

### Frontend Structure

```
lib/
├── main.dart                          # Entry point, theme & router setup
├── core/
│   ├── constants/
│   │   └── app_constants.dart         # API base URL config
│   ├── services/
│   │   ├── api_service.dart           # HTTP client with auth headers
│   │   └── auth_storage_service.dart  # SharedPreferences for auth
│   └── theme/
│       └── app_theme.dart             # Light/Dark theme definition
├── models/
│   ├── app_user.dart                  # User model
│   ├── driver.dart                    # Driver model with earnings
│   ├── trip.dart                      # Trip model
│   ├── vehicle.dart                   # Vehicle model
│   ├── bill.dart                      # Bill model
│   ├── payment.dart                   # Payment model
│   ├── app_notification.dart          # Notification model
├── providers/
│   ├── auth_provider.dart             # Auth state & notifier
│   ├── app_state_provider.dart        # App data state & notifier
│   └── theme_mode_provider.dart       # Theme mode provider
├── routes/
│   └── app_router.dart                # Route definitions & generation
└── features/
    ├── auth/
    │   └── login_page.dart
    ├── dashboard/
    │   └── dashboard_page.dart
    ├── home/
    │   └── home_page.dart
    ├── trips/
    │   └── trips_page.dart
    ├── vehicles/
    │   └── vehicles_page.dart
    ├── drivers/
    │   └── drivers_page.dart
    ├── payments/
    │   └── payments_page.dart
    ├── billing/
    │   └── billing_page.dart
    ├── notifications/
    │   └── notifications_page.dart
    ├── settings/
    │   └── settings_page.dart
    └── users/
        └── users_page.dart
```

### Backend Structure

```
backend/
├── server.js                          # Express app setup
├── config/
│   └── db.js                          # MongoDB connection
├── models/
│   ├── User.js                        # User schema (roles: owner/employee/driver)
│   ├── Driver.js
│   ├── Trip.js
│   ├── Vehicle.js
│   ├── Bill.js
│   ├── Payment.js
│   ├── Notification.js
│   └── VehicleBataRate.js
├── controllers/
│   ├── authController.js              # Auth operations
│   ├── driverController.js
│   ├── tripController.js
│   └── [other controllers]
├── routes/
│   ├── authRoutes.js                  # POST /auth/register, /auth/login, POST /auth/users (owner)
│   ├── driverRoutes.js
│   ├── tripRoutes.js
│   ├── vehicleRoutes.js
│   └── [other routes]
├── middleware/
│   ├── authMiddleware.js              # protect, authorizeRoles
│   ├── errorMiddleware.js
│   └── validationMiddleware.js
└── services/
    ├── fcmService.js                  # Firebase Cloud Messaging
    ├── pdfService.js                  # PDF generation
    ├── reminderService.js
    └── tokenService.js                # JWT generation
```

---

## 9. API Configuration

**Base URL:** [flutter_app/lib/core/constants/app_constants.dart](flutter_app/lib/core/constants/app_constants.dart)

```dart
static const String productionBaseUrl = 'https://travel-fleet.onrender.com/api';
static final String baseUrl = () {
  // Can be overridden via environment variable
  const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  // ... logic for Android emulator 10.0.2.2 -> 127.0.0.1 mapping
  return fromEnv.isNotEmpty ? fromEnv : productionBaseUrl;
}();
```

**Authentication Header Format:**
```
Authorization: Bearer {token}
```

---

## 10. State Management Details

### 10.1 Auth State (Riverpod StateNotifier)
```dart
class AuthState {
  final String? token;
  final String? role;
  final String? name;
  final String? email;
  final bool loading;
  final String? error;
}
```

### 10.2 App State (Riverpod StateNotifier)
```dart
class AppState {
  final bool loading;
  final String? error;
  final List<TripModel> trips;
  final List<BillModel> bills;
  final List<VehicleModel> vehicles;
  final Map<String, double> vehicleBataRates;
  final List<DriverModel> drivers;
  final List<PaymentModel> payments;
  final List<AppNotification> notifications;
}
```

Both use `copyWith` pattern for immutable updates.

---

## 11. What Needs to be Modified or Created

### 11.1 Frontend Enhancements Needed

1. **API Call Role Filtering**
   - Implement a helper function to check role before making API calls
   - Prevent driver from calling create trip endpoints
   - Show appropriate error messages

2. **Complete Stub Screens**
   - `drivers_page.dart` - Driver CRUD and assignment
   - `payments_page.dart` - Payment display and filtering
   - `billing_page.dart` - Invoice generation and view
   - `notifications_page.dart` - Alert management

3. **Data Refresh on Page Focus**
   - Currently data only loads on home page init
   - Implement `didChangeAppLifecycleState` or use page transitions

4. **Error Handling UI**
   - Better error messages per action
   - Retry mechanisms for failed API calls
   - Network connectivity checks

5. **Input Validation Enhancement**
   - Phone number format validation
   - Email verification
   - Custom validators for business logic

6. **Real-time Features**
   - WebSocket connection for live trip updates
   - Firebase Cloud Messaging for notifications
   - Polling as fallback

### 11.2 Backend Enhancements Needed

1. **Trip Status Management**
   - Implement trip status transitions (pending → in_progress → completed → cancelled)
   - Audit logging for status changes

2. **Driver Leave Management**
   - Complete leave approval workflow
   - Auto-decline overlapping leaves
   - Leave balance calculation

3. **Payroll Calculations**
   - Implement driver earnings endpoint
   - Salary calculations (daily, hourly, per-trip)
   - Bata (daily allowance) tracking

4. **Invoice Generation**
   - PDF generation for bills
   - Email delivery
   - Invoice templates

5. **Notification System**
   - Real-time notification delivery via FCM
   - Notification templates
   - Mark as read functionality

6. **Data Validation**
   - Custom validators for business rules
   - Prevent double-booking of vehicles
   - Driver availability checks

### 11.3 Security Improvements

1. **Frontend**
   - Add certificate pinning for API calls
   - Biometric authentication option
   - Auto-logout after inactivity

2. **Backend**
   - Rate limiting on login/register
   - Role-based field filtering in responses
   - Audit logging for sensitive operations

---

## 12. Code Examples for Reference

### Example 1: Frontend Role Check
```dart
// In appStateProvider.notifier methods:
Future<void> createTrip(Map<String, dynamic> payload) async {
  final currentRole = ref.read(authProvider).role;
  if (currentRole == null || !['owner', 'employee'].contains(currentRole)) {
    throw Exception('Insufficient permissions: only owner/employee can create trips');
  }
  await _post('/trip', payload);
  await fetchTrips();
}
```

### Example 2: Backend Role Authorization
```javascript
// In routes
router.post('/trip', protect, authorizeRoles('owner', 'employee'), tripValidation, validate, createTrip);
```

### Example 3: Login + Role Retrieval
```dart
// Frontend LoginPage
final authNotifier = ref.read(authProvider.notifier);
await authNotifier.login(
  email: _emailController.text.trim(),
  password: _passwordController.text,
);
// After login, role is available in auth.role
```

---

## Summary Table

| Aspect | Status | File Locations |
|--------|--------|-----------------|
| **Auth Model** | ✅ Complete | `backend/models/User.js`, `flutter_app/lib/models/app_user.dart` |
| **Auth Controller** | ✅ Complete | `backend/controllers/authController.js` |
| **Auth Provider** | ✅ Complete | `flutter_app/lib/providers/auth_provider.dart` |
| **Role Definitions** | ✅ Complete | Enum: owner, employee, driver |
| **RBAC Backend** | ✅ Complete | `backend/middleware/authMiddleware.js` |
| **RBAC Frontend** | ⚠️ Partial | Menu/screen filtering done; API calls not checked |
| **Navigation** | ✅ Complete | `flutter_app/lib/routes/app_router.dart`, `flutter_app/lib/main.dart` |
| **Screens** | ⚠️ Partial | 5 implemented, 4 stubs |
| **Theme Support** | ✅ Complete | `flutter_app/lib/core/theme/app_theme.dart` |
| **Light/Dark Mode** | ✅ Complete | `flutter_app/lib/providers/theme_mode_provider.dart` |
| **State Management** | ✅ Complete | Riverpod providers |
| **API Service** | ✅ Complete | `flutter_app/lib/core/services/api_service.dart` |

