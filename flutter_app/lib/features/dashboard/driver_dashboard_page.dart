import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../home/home_page.dart';
import '../notifications/notifications_page.dart';
import '../settings/settings_page.dart';
import '../trips/trips_page.dart';
import '../drivers/driver_earnings_page.dart';
import '../../routes/app_router.dart';

class DriverDashboardPage extends ConsumerStatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  ConsumerState<DriverDashboardPage> createState() =>
      _DriverDashboardPageState();
}

class _DriverDashboardPageState extends ConsumerState<DriverDashboardPage> {
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
        description: 'My overview',
      ),
      const _MenuItem(
        label: 'My Trips',
        icon: Icons.route,
        page: TripsPage(),
        description: 'View assigned trips',
      ),
      const _MenuItem(
        label: 'Earnings',
        icon: Icons.trending_up,
        page: DriverEarningsPage(),
        description: 'Track earnings',
      ),
      const _MenuItem(
        label: 'Alerts',
        icon: Icons.notifications,
        page: NotificationsPage(),
        description: 'Notifications',
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
          '${menuItems[_index].label} • Driver',
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
                            Colors.orange,
                            Colors.orange.withValues(alpha: 0.7),
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
                                  : 'D',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.orange,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            auth.name ?? 'Driver',
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
                              color: isSelected ? Colors.orange : null,
                            ),
                            title: Text(
                              item.label,
                              style: isSelected
                                  ? theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    )
                                  : null,
                            ),
                            subtitle: Text(
                              item.description,
                              style: theme.textTheme.bodySmall,
                            ),
                            selected: isSelected,
                            selectedTileColor:
                                Colors.orange.withOpacity(0.1),
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
