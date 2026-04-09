import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/role_permissions.dart';
import '../../providers/auth_provider.dart';
import 'owner_dashboard_page.dart';
import 'employee_dashboard_page.dart';
import 'driver_dashboard_page.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    
    if (!auth.isAuthenticated) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final userRole = auth.userRole;

    switch (userRole) {
      case UserRole.owner:
        return const OwnerDashboardPage();
      case UserRole.employee:
        return const EmployeeDashboardPage();
      case UserRole.driver:
        return const DriverDashboardPage();
    }
  }
}
