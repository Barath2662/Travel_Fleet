import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';
import 'driver_dashboard_view.dart';
import '../trips/trip_tracking_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  double _driverEarnings(dynamic driver) {
    final salaryFromDays = driver.totalWorkingDays * driver.salaryPerDay;
    final salaryFromHours =
        driver.totalWorkingHours * (driver.salaryPerDay / 8);
    final tripSalary = driver.totalTripsCompleted * driver.salaryPerTrip;
    return (salaryFromDays > salaryFromHours
            ? salaryFromDays
            : salaryFromHours) +
        tripSalary +
        driver.totalBataEarned;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final app = ref.read(appStateProvider.notifier);
      await Future.wait([
        app.fetchTrips(),
        app.fetchBills(),
        app.fetchVehicles(),
        app.fetchDrivers(),
        app.fetchPayments(),
        app.fetchNotifications(),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final state = ref.watch(appStateProvider);
    final theme = Theme.of(context);
    final authUserId = auth.userId;
    final myDriver = state.drivers
      .where((d) => (authUserId != null && d.userId == authUserId) || d.loginEmail == auth.email)
        .cast<dynamic>()
        .toList();
    final hasDriverProfile = myDriver.isNotEmpty;
    final earning = hasDriverProfile ? _driverEarnings(myDriver.first) : 0.0;

    return RefreshIndicator(
      onRefresh: () async {
        final app = ref.read(appStateProvider.notifier);
        await Future.wait([
          app.fetchTrips(),
          app.fetchBills(),
          app.fetchVehicles(),
          app.fetchDrivers(),
          app.fetchPayments(),
          app.fetchNotifications(),
        ]);
      },
      child: Builder(builder: (context) {
        if (auth.role == 'driver') {
          final activeTrips = state.trips
              .where(
                  (t) => t.status == 'in_progress' || t.status == 'scheduled')
              .toList();
          final currentTrip = activeTrips.isNotEmpty ? activeTrips.first : null;
          final upcoming =
              activeTrips.length > 1 ? activeTrips.skip(1).toList() : [];

          Map<String, dynamic>? currentTripData;
          if (currentTrip != null) {
            final dropPoints = currentTrip.placesToVisit;
            currentTripData = {
              'id': currentTrip.id,
              'status': currentTrip.status,
              'pickup': currentTrip.pickupLocation,
              'drop': dropPoints.isNotEmpty
                  ? dropPoints.join(', ')
                  : currentTrip.pickupLocation,
              'vehicle': currentTrip.vehicleNumber ?? 'Assigned Vehicle',
            };
          }

          return DriverDashboardView(
            driverName: auth.name ?? 'Driver',
            monthlyEarnings: earning,
            currentTrip: currentTripData,
            upcomingTrips: upcoming,
            onStartTrip: () {
              if (currentTrip != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TripTrackingPage(tripId: currentTrip.id, trip: currentTrip),
                  ),
                );
              }
            },
            onEndTrip: () {
              if (currentTrip != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TripTrackingPage(tripId: currentTrip.id, trip: currentTrip),
                  ),
                );
              }
            },
            onTripTap: (trip) {
              // Detail view
            },
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Welcome, ${auth.name ?? 'User'}',
                    style: theme.textTheme.headlineSmall),
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                DashboardCard(
                    title: 'Trips',
                    count: state.trips.length.toString(),
                    icon: Icons.route_outlined,
                    color: theme.colorScheme.primary,
                    onTap: () => Navigator.pushNamed(context, '/dashboard'), // Since tabs manage trips, pushing inside the app via existing logic won't cleanly jump to them unless we had independent routes, but I'll use Navigator.push directly if they were root level, but let's push a placeholder or standard named route
                ),
                if (auth.role != 'driver')
                  DashboardCard(
                      title: 'Bills',
                      count: state.bills.length.toString(),
                      icon: Icons.receipt_long_outlined,
                      color: theme.colorScheme.secondary),
                DashboardCard(
                    title: 'Vehicles',
                    count: state.vehicles.length.toString(),
                    icon: Icons.directions_car_outlined,
                    color: theme.colorScheme.tertiary),
                DashboardCard(
                    title: 'Drivers',
                    count: state.drivers.length.toString(),
                    icon: Icons.badge_outlined,
                    color: theme.colorScheme.primary),
                DashboardCard(
                    title: 'Payments',
                    count: state.payments.length.toString(),
                    icon: Icons.payments_outlined,
                    color: theme.colorScheme.secondary),
                if (auth.role == 'driver')
                  DashboardCard(
                    title: 'My Earnings',
                    count: earning.toStringAsFixed(0),
                    icon: Icons.currency_rupee,
                    color: theme.colorScheme.primary,
                  ),
                DashboardCard(
                  title: 'Unread Alerts',
                  count: state.notifications
                      .where((n) => !n.isRead)
                      .length
                      .toString(),
                  icon: Icons.notifications_none,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String count;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final contentColor = isDark ? Colors.white : Colors.black87;

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withAlpha(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(icon, size: 22, color: color),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
                ],
              ),
              const Spacer(),
              Text(
                count,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: contentColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
