import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/enhanced_widgets.dart';
import '../../models/driver.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart' hide AuthState;

class LeavePage extends ConsumerStatefulWidget {
  const LeavePage({super.key});

  @override
  ConsumerState<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends ConsumerState<LeavePage> {
  late final TextEditingController _reasonController;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    bool isFromDate,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? (_fromDate ?? DateTime.now()) : (_toDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          // Reset toDate if it's before fromDate
          if (_toDate != null && _toDate!.isBefore(picked)) {
            _toDate = null;
          }
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Future<void> _applyLeave() async {
    if (_fromDate == null || _toDate == null || _reasonController.text.trim().isEmpty) {
      _show('Please fill all fields');
      return;
    }

    if (_toDate!.isBefore(_fromDate!)) {
      _show('End date must be after start date');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final auth = ref.read(authProvider);
      final drivers = ref.read(appStateProvider).drivers;

      // Find the driver ID for the current user
      final currentDriver = drivers.firstWhere(
        (d) => d.loginEmail == auth.email,
      );

      await ref.read(appStateProvider.notifier).applyDriverLeave(
        currentDriver.id,
        from: _fromDate!,
        to: _toDate!,
        reason: _reasonController.text.trim(),
      );

      _show('Leave application submitted');
      _fromDate = null;
      _toDate = null;
      _reasonController.clear();
    } catch (e) {
      _show('Error: ${e.toString()}');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final state = ref.watch(appStateProvider);

    // Get current driver's leaves
    final currentDriver = state.drivers.firstWhere(
      (d) => d.loginEmail == auth.email,
      orElse: () => DriverModel(
        id: '',
        name: '',
        phone: '',
        totalWorkingHours: 0,
        totalWorkingDays: 0,
      ),
    );

    final leaves = currentDriver.leaves;
    final approvedLeaves = leaves.where((l) => l.status == 'approved').toList();
    final pendingLeaves = leaves.where((l) => l.status == 'pending').toList();
    final rejectedLeaves = leaves.where((l) => l.status == 'rejected').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Management'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Apply Leave Form
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apply for Leave',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // From Date
                    GestureDetector(
                      onTap: () => _selectDate(context, true),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outline),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'From Date',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    _fromDate == null
                                        ? 'Select date'
                                        : DateFormat('dd MMM yyyy').format(_fromDate!),
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // To Date
                    GestureDetector(
                      onTap: () => _selectDate(context, false),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outline),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'To Date',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    _toDate == null
                                        ? 'Select date'
                                        : DateFormat('dd MMM yyyy').format(_toDate!),
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Reason
                    TextField(
                      controller: _reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Reason for Leave',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'Enter reason for your leave...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSubmitting ? null : _applyLeave,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        label: Text(_isSubmitting ? 'Submitting...' : 'Submit Leave Request'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Leave Statistics
            if (leaves.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Approved',
                      value: '${approvedLeaves.length}',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: 'Pending',
                      value: '${pendingLeaves.length}',
                      icon: Icons.hourglass_bottom,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: 'Rejected',
                      value: '${rejectedLeaves.length}',
                      icon: Icons.cancel,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            // Leave History
            if (leaves.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_note,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No leave records',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Text(
                'Leave History',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...leaves.map((leave) {
                final statusColor = leave.status == 'approved'
                    ? Colors.green
                    : leave.status == 'pending'
                        ? Colors.orange
                        : Colors.red;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(
                      leave.status == 'approved'
                          ? Icons.check_circle
                          : leave.status == 'pending'
                              ? Icons.hourglass_bottom
                              : Icons.cancel,
                      color: statusColor,
                    ),
                    title: Text(
                      '${DateFormat('dd MMM').format(leave.from)} - ${DateFormat('dd MMM yyyy').format(leave.to)}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          leave.reason,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(leave.status.toUpperCase()),
                      backgroundColor: statusColor.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
