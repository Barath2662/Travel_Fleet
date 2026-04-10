import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../billing/billing_page.dart';
import '../drivers/drivers_page.dart';
import '../home/home_page.dart';
import '../notifications/notifications_page.dart';
import '../payments/payments_page.dart';
import '../settings/settings_page.dart';
import '../trips/trips_page.dart';
import '../users/users_page.dart';
import '../vehicles/vehicles_page.dart';
import '../../routes/app_router.dart';

class OwnerDashboardPage extends ConsumerStatefulWidget {
  const OwnerDashboardPage({super.key});

  @override
  ConsumerState<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends ConsumerState<OwnerDashboardPage> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = 0;
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRouter.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isWide = MediaQuery.of(context).size.width >= 900;
    final theme = Theme.of(context);

    final menuItems = [
      const _MenuItem(
        label: 'Dashboard',
        icon: Icons.dashboard,
        page: HomePage(),
        description: 'Overview & analytics',
      ),
      const _MenuItem(
        label: 'Trips',
        icon: Icons.route,
        page: TripsPage(),
        description: 'Schedule & manage trips',
      ),
      const _MenuItem(
        label: 'Vehicles',
        icon: Icons.directions_car,
        page: VehiclesPage(),
        description: 'Vehicle management',
      ),
      const _MenuItem(
        label: 'Drivers',
        icon: Icons.person_pin,
        page: DriversPage(),
        description: 'Manage drivers',
      ),
      const _MenuItem(
        label: 'Employees',
        icon: Icons.group,
        page: UsersPage(),
        description: 'Manage employees',
      ),
      const _MenuItem(
        label: 'Billing',
        icon: Icons.receipt_long,
        page: BillingPage(),
        description: 'Billing & invoices',
      ),
      const _MenuItem(
        label: 'Payments',
        icon: Icons.payments,
        page: PaymentsPage(),
        description: 'Payment tracking',
      ),
      const _MenuItem(
        label: 'Alerts',
        icon: Icons.notifications,
        page: NotificationsPage(),
        description: 'Notifications & alerts',
      ),
      const _MenuItem(
        label: 'Settings',
        icon: Icons.settings,
        page: SettingsPage(),
        description: 'App settings',
      ),
    ];

    if (_index >= menuItems.length) {
      _index = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${menuItems[_index].label} • Owner',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      drawer: isWide
          ? null
          : Drawer(
              child: SafeArea(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: theme.colorScheme.surface,
                            child: Text(
                              auth.name?.isNotEmpty == true
                                  ? auth.name!.substring(0, 1).toUpperCase()
                                  : 'O',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            auth.name ?? 'Owner',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            auth.email ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: menuItems.length,
                        itemBuilder: (context, i) {
                          final item = menuItems[i];
                          final isSelected = _index == i;
                          return ListTile(
                            leading: Icon(
                              item.icon,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                            title: Text(
                              item.label,
                              style: isSelected
                                  ? theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    )
                                  : null,
                            ),
                            subtitle: Text(
                              item.description,
                              style: theme.textTheme.bodySmall,
                            ),
                            selected: isSelected,
                            selectedTileColor: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            onTap: () {
                              setState(() => _index = i);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Logout'),
                      onTap: _logout,
                    ),
                  ],
                ),
              ),
            ),
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: _index,
              labelType: NavigationRailLabelType.all,
              minWidth: 100,
              groupAlignment: 0.0,
              onDestinationSelected: (value) =>
                  setState(() => _index = value),
              destinations: menuItems
                  .map((item) => NavigationRailDestination(
                        icon: Icon(item.icon),
                        label: Text(item.label),
                      ))
                  .toList(),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Padding(
                key: ValueKey(_index),
                padding: const EdgeInsets.all(8),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: menuItems[_index].page,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.label,
    required this.icon,
    required this.page,
    required this.description,
  });

  final String label;
  final IconData icon;
  final Widget page;
  final String description;
}
