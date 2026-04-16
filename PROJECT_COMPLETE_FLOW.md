# Travel Fleet Complete Project Flow

## 1. System Overview
Travel Fleet is a role-based fleet management platform made of:
- Backend API: Node.js + Express + MongoDB
- Client App: Flutter (Android, iOS, Desktop/Web scaffolding)
- Auth: JWT bearer token
- Core domains: Authentication, Trips, Drivers, Vehicles, Billing, Payments, Notifications

## 2. High-Level Architecture
- Flutter app sends authenticated HTTP requests to backend `/api/*` endpoints.
- Backend validates token/role and executes business rules.
- MongoDB stores users, trips, drivers, vehicles, bills, and payments.
- Scheduler service runs reminder/alert jobs in backend startup.
- Render deployment runs backend service from `backend/server.js`.

## 3. Startup Flow
1. `backend/server.js` loads environment variables.
2. Database connection is initialized by `backend/config/db.js`.
3. Middleware stack loads: CORS, Helmet, Morgan, JSON parser.
4. Health check route is exposed at `/health`.
5. API routers are mounted under `/api`.
6. Error handlers are attached.
7. Reminder schedulers are started.

## 4. Authentication and Authorization Flow
1. User registers or logs in using auth endpoints.
2. Backend issues JWT token containing user identity.
3. Flutter stores token and sends `Authorization: Bearer <token>` on API calls.
4. `protect` middleware validates token and attaches user to request.
5. `authorizeRoles(...)` enforces role-based access:
- owner: full business control
- employee: operational management
- driver: trip execution and self-service actions

## 5. Main Business Flows

## 5.1 Trip Lifecycle Flow
### Create Trip (owner/employee)
1. Client sends payload to `POST /api/trip`.
2. Backend validates required fields (`pickupDateTime`, customer info, route, driver, vehicle).
3. Backend loads driver and vehicle; rejects invalid IDs.
4. Backend applies default bata from vehicle category rate.
5. Trip is saved with status `scheduled`.

### Start Trip (driver)
1. Driver submits `startKm` to `PUT /api/trip/:id/start`.
2. Backend validates numeric non-negative KM.
3. Backend confirms trip status is `scheduled`.
4. Backend verifies `startKm >= vehicle.currentKm`.
5. Trip is marked `in_progress` with `startTime` and `startKm`.

### End Trip (driver)
1. Driver submits `endKm` + toll/permit/parking flags to `PUT /api/trip/:id/end`.
2. Backend validates payload and confirms trip status is `in_progress`.
3. Backend enforces `endKm >= startKm`.
4. Trip is marked `completed` with `endTime`.
5. Vehicle current KM is updated if end KM is higher.
6. Driver totals are updated:
- total working hours
- total working days
- total trips completed
- total bata earned (one-time credit guard)

## 5.2 Driver Leave Flow
### Apply Leave (driver/employee)
1. Request goes to `POST /api/driver/:id/leave` with from/to/reason.
2. Driver role is restricted to their own profile only.
3. Leave record is stored with default status `pending`.

### Approve or Reject Leave (owner/employee)
1. Request goes to `PUT /api/driver/:id/leave/approve`.
2. Backend validates `leaveId` and status (`pending|approved|rejected`).
3. Leave record is updated with new status and approver.

## 5.3 Payroll Summary Flow
1. Request goes to `GET /api/driver/:id/payroll`.
2. Backend verifies role access (driver can only view own payroll).
3. Salary parts are computed:
- salary from days
- salary from hours
- trip salary
- bata total
4. Leave deduction is applied:
- `approvedLeaveCount * salaryPerDay`
5. API returns: totals, counts, estimated salary, gross payable.

## 5.4 Billing and Payment Flow
1. Bills are created for completed/chargeable work.
2. Payments are created/updated against bills.
3. Bill payment status is synchronized from payment status.
4. Flutter refreshes bills and payments after payment updates.

## 5.5 Vehicle and Driver Admin Flow
- Owners/employees can create and update vehicles.
- Owners/employees can create drivers.
- Optional driver login is created when email/password are supplied.
- Trip assignments bind driver and vehicle references.

## 5.6 Notification Flow
- Notification endpoints provide listing and read-marking.
- Backend services include FCM setup for push notification extension.

## 6. Flutter App Flow
1. App initializes providers and reads saved auth session.
2. If token exists, app loads dashboard; otherwise login flow appears.
3. Feature pages call `AppStateNotifier` methods.
4. Notifier methods call `ApiService` (`GET/POST/PUT`) and refresh list state.
5. Errors are captured and exposed to UI for display.

## 7. API Route Map (Operational)
- Auth: `/api/auth/*`
- Trips: `/api/trip`, `/api/trips`, `/api/trip/:id/start`, `/api/trip/:id/end`
- Drivers: `/api/driver`, `/api/drivers`, `/api/driver/:id/leave`, `/api/driver/:id/payroll`
- Vehicles: `/api/vehicle`, `/api/vehicles`, `/api/vehicle-bata-rates`
- Billing: `/api/bill`, `/api/bills`
- Payments: `/api/payment`, `/api/payments`
- Notifications: `/api/notifications`
- Health: `/health`

## 8. Environment and Deployment Flow
### Local backend
Required env variables (minimum):
- `MONGO_URI` (MongoDB URI)
- `JWT_SECRET`
- `PORT` (optional)

### Render backend
Configured in `render.yaml`:
- service type: web
- rootDir: `backend`
- build: `npm install`
- start: `node server.js`
- env vars mapped for MongoDB, JWT, Firebase

## 9. Validation and Quality Gates
Completed in this review:
- Backend dependency install succeeded.
- Backend JS syntax check passed across source files.
- Runtime boot attempted; blocked by missing/invalid MongoDB URI in active `.env`.
- Critical backend validations were added for trip state and KM integrity.
- Payroll now includes approved-leave deduction.

## 10. Known Runtime Prerequisite
The backend cannot run successfully until `backend/.env` contains a valid MongoDB `MONGO_URI`.
Current `.env` in workspace appears to belong to a different stack and does not provide a MongoDB URI.

## 11. Recommended End-to-End Test Sequence
1. Set valid MongoDB URI in `backend/.env`.
2. Start backend and verify `GET /health`.
3. Login as owner and create vehicle + driver.
4. Create trip and confirm status `scheduled`.
5. Login as driver and start trip.
6. End trip and verify vehicle KM and driver counters changed.
7. Apply leave, approve/reject leave, and validate payroll deduction.
8. Create bill/payment and verify payment status synchronization.
9. Launch Flutter app and run the same user journey from UI.
