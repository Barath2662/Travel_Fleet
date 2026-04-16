import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';

class DriverEarningsPage extends ConsumerStatefulWidget {
  const DriverEarningsPage({super.key});

  @override
  ConsumerState<DriverEarningsPage> createState() => _DriverEarningsPageState();
}

class _DriverEarningsPageState extends ConsumerState<DriverEarningsPage> {
  Map<String, dynamic>? _payroll;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadPayroll);
  }

  Future<void> _loadPayroll() async {
    final auth = ref.read(authProvider);
    final app = ref.read(appStateProvider.notifier);

    setState(() => _loading = true);
    try {
      await app.fetchDrivers();
      final drivers = ref.read(appStateProvider).drivers;
      final me = drivers.where((d) => d.loginEmail == auth.email).toList();
      if (me.isEmpty) {
        setState(() {
          _payroll = null;
          _loading = false;
        });
        return;
      }

      final payroll = await app.fetchDriverPayroll(me.first.id);
      if (!mounted) return;
      setState(() {
        _payroll = payroll;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String money(dynamic value) => ((value as num?)?.toDouble() ?? 0).toStringAsFixed(2);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_payroll == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No driver payroll profile found for this account.',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Earnings Overview',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _EarningsCard(
                title: 'Gross Payable',
                amount: money(_payroll!['grossPayable']),
                subtitle: 'Net with bata + trips',
                color: Colors.green,
              ),
              _EarningsCard(
                title: 'Estimated Salary',
                amount: money(_payroll!['estimatedSalary']),
                subtitle: 'After leave deduction',
                color: Colors.blue,
              ),
              _EarningsCard(
                title: 'Trip Salary',
                amount: money(_payroll!['tripSalary']),
                subtitle: 'Per completed trip',
                color: Colors.orange,
              ),
              _EarningsCard(
                title: 'Total Bata',
                amount: money(_payroll!['totalBata']),
                subtitle: 'Credited bata',
                color: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Payroll Summary',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _summaryTile('Working Days', '${_payroll!['totalWorkingDays'] ?? 0}'),
              _summaryTile('Working Hours', money(_payroll!['totalWorkingHours'])),
              _summaryTile('Completed Trips', '${_payroll!['totalTripsCompleted'] ?? 0}'),
              _summaryTile('Salary From Days', money(_payroll!['salaryFromDays'])),
              _summaryTile('Salary From Hours', money(_payroll!['salaryFromHours'])),
              _summaryTile('Leave Deduction', money(_payroll!['leaveDeduction'])),
              _summaryTile('Approved Leaves', '${_payroll!['approvedLeaveCount'] ?? 0}'),
              _summaryTile('Pending Leaves', '${_payroll!['pendingLeaveCount'] ?? 0}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(String label, String value) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(value),
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard({
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String amount;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Icon(
                    Icons.trending_up,
                    color: color,
                    size: 20,
                  ),
                ],
              ),
              Text(
                amount,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
