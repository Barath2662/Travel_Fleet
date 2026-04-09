import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/enhanced_widgets.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';

class DriversPage extends ConsumerStatefulWidget {
  const DriversPage({super.key});

  @override
  ConsumerState<DriversPage> createState() => _DriversPageState();
}

class _DriversPageState extends ConsumerState<DriversPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _license = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _leaveReason = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(appStateProvider.notifier).fetchDrivers());
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _license.dispose();
    _email.dispose();
    _password.dispose();
    _leaveReason.dispose();
    super.dispose();
  }

  Future<void> _createDriver() async {
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty || _license.text.trim().isEmpty) {
      _show('Name, phone and license are required');
      return;
    }

    final hasLogin = _email.text.trim().isNotEmpty || _password.text.isNotEmpty;
    if (hasLogin && (_email.text.trim().isEmpty || _password.text.isEmpty)) {
      _show('Enter both email and password to create unique driver login');
      return;
    }

    await ref.read(appStateProvider.notifier).createDriver({
      'name': _name.text.trim(),
      'phone': _phone.text.trim(),
      'licenseNumber': _license.text.trim(),
      'salaryPerDay': 1000,
      'bataRate': 300,
      if (hasLogin) 'email': _email.text.trim(),
      if (hasLogin) 'password': _password.text,
    });

    _name.clear();
    _phone.clear();
    _license.clear();
    _email.clear();
    _password.clear();
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _applyLeave(String driverId) async {
    final now = DateTime.now();
    final from = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (from == null || !mounted) return;

    final to = await showDatePicker(
      context: context,
      initialDate: from,
      firstDate: from,
      lastDate: from.add(const Duration(days: 90)),
    );

    if (to == null || !mounted) return;

    _leaveReason.clear();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Reason'),
        content: TextField(
          controller: _leaveReason,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Reason'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, _leaveReason.text.trim()),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) {
      _show('Leave reason is required');
      return;
    }

    await ref.read(appStateProvider.notifier).applyDriverLeave(driverId, from: from, to: to, reason: reason);
    _show('Leave request submitted');
  }

  Future<void> _approveLeave(String driverId, String leaveId, String status) async {
    await ref.read(appStateProvider.notifier).approveDriverLeave(driverId, leaveId: leaveId, status: status);
    _show('Leave marked as $status');
  }

  Future<void> _showPayroll(String driverId) async {
    final payroll = await ref.read(appStateProvider.notifier).fetchDriverPayroll(driverId);
    if (!mounted) return;

    String asMoney(dynamic value) {
      final numVal = (value as num?)?.toDouble() ?? 0;
      return numVal.toStringAsFixed(2);
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payroll • ${payroll['driverName'] ?? ''}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Working Days: ${payroll['totalWorkingDays'] ?? 0}'),
            Text('Working Hours: ${asMoney(payroll['totalWorkingHours'])}'),
            Text('Completed Trips: ${payroll['totalTripsCompleted'] ?? 0}'),
            const SizedBox(height: 8),
            Text('Salary by Days: ${asMoney(payroll['salaryFromDays'])}'),
            Text('Salary by Hours: ${asMoney(payroll['salaryFromHours'])}'),
            Text('Trip Salary: ${asMoney(payroll['tripSalary'])}'),
            Text('Credited Bata: ${asMoney(payroll['totalBata'])}'),
            const Divider(),
            Text('Estimated Base: ${asMoney(payroll['estimatedSalary'])}'),
            Text('Gross Payable: ${asMoney(payroll['grossPayable'])}'),
            const SizedBox(height: 8),
            Text('Approved Leaves: ${payroll['approvedLeaveCount'] ?? 0}'),
            Text('Pending Leaves: ${payroll['pendingLeaveCount'] ?? 0}'),
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final auth = ref.watch(authProvider);
    final role = auth.role;
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd MMM yyyy');
    final visibleDrivers = role == 'driver'
        ? state.drivers.where((d) => d.loginEmail != null && d.loginEmail == auth.email).toList()
        : state.drivers;

    return RefreshIndicator(
      onRefresh: () => ref.read(appStateProvider.notifier).fetchDrivers(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (role == 'owner' || role == 'employee')
            EnhancedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.person_add,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Add Driver',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Driver Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _license,
                    decoration: const InputDecoration(
                      labelText: 'License Number',
                      prefixIcon: Icon(Icons.credit_card),
                    ),
                  ),
                  if (role == 'owner') ...[
                    const SizedBox(height: 16),
                    Divider(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.2)),
                    const SizedBox(height: 12),
                    Text(
                      'Optional: Create Login for Driver',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Driver Login Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Driver Login Password',
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save),
                      onPressed: _createDriver,
                      label: const Text('Save Driver'),
                    ),
                  ),
                ],
              ),
            ),
          if (state.loading) const LinearProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Drivers (${visibleDrivers.length})',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...visibleDrivers.map((d) {
            final isCurrentDriver = role == 'driver' && auth.email == d.loginEmail;
            return EnhancedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        child: Text(
                          (d.name.isNotEmpty ? d.name[0] : 'D').toUpperCase(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.name,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              d.phone,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCurrentDriver)
                        Chip(
                          label: const Text('Me'),
                          backgroundColor: theme.colorScheme.primaryContainer,
                          labelStyle: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.route,
                        label: 'Trips',
                        value: '${d.totalTripsCompleted}',
                      ),
                      _InfoChip(
                        icon: Icons.schedule,
                        label: 'Days',
                        value: '${d.totalWorkingDays}',
                      ),
                      _InfoChip(
                        icon: Icons.access_time,
                        label: 'Hours',
                        value: '${d.totalWorkingHours.toStringAsFixed(1)}',
                      ),
                      _InfoChip(
                        icon: Icons.trending_up,
                        label: 'Bata',
                        value: '\$${d.totalBataEarned.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                  if (d.loginEmail != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Login: ${d.loginEmail}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if ((role == 'owner' || role == 'employee'))
                        OutlinedButton.icon(
                          icon: const Icon(Icons.money),
                          onPressed: () => _showPayroll(d.id),
                          label: const Text('Payroll'),
                        ),
                      if ((role == 'driver' && isCurrentDriver) ||
                          (role == 'employee'))
                        OutlinedButton.icon(
                          icon: const Icon(Icons.holiday_village),
                          onPressed: () => _applyLeave(d.id),
                          label: const Text('Apply Leave'),
                        ),
                      if (isCurrentDriver)
                        FilledButton.icon(
                          icon: const Icon(Icons.trending_up),
                          onPressed: () => _showPayroll(d.id),
                          label: const Text('My Earnings'),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
          if (role == 'owner') ...[
            const SizedBox(height: 24),
            Text(
              'Pending Leave Requests',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...state.drivers.expand((d) {
              final pending = d.leaves.where((l) => l.status == 'pending').toList();
              return pending.map(
                (leave) => EnhancedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${d.name} • ${dateFmt.format(leave.from)} to ${dateFmt.format(leave.to)}',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  leave.reason,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.close),
                              onPressed: () =>
                                  _approveLeave(d.id, leave.id, 'rejected'),
                              label: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              icon: const Icon(Icons.check),
                              onPressed: () =>
                                  _approveLeave(d.id, leave.id, 'approved'),
                              label: const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
