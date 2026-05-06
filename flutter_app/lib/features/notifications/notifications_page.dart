import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/enhanced_widgets.dart';
import '../../models/app_notification.dart';
import '../../providers/app_state_provider.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _promptFastagAmount(AppNotification notification) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter FASTag Amount'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'FASTag Amount'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              Navigator.pop(context, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (amount == null) return;
    if (notification.relatedEntityId == null) {
      _show('Missing FASTag request reference');
      return;
    }

    try {
      await ref
          .read(appStateProvider.notifier)
          .setFastagAmount(requestId: notification.relatedEntityId!, amount: amount);
      _show('FASTag amount saved');
    } catch (e) {
      _show('Error: $e');
    }
  }

  Future<void> _handleLeaveAction(AppNotification notification, String status) async {
    final meta = notification.meta;
    final leaveId = meta['leaveId']?.toString();
    if (leaveId == null) {
      _show('Leave request reference missing');
      return;
    }

    try {
      if (notification.type == 'leave_request_driver') {
        final driverId = meta['driverId']?.toString();
        if (driverId == null) {
          _show('Driver reference missing');
          return;
        }
        await ref.read(appStateProvider.notifier).approveDriverLeave(
          driverId,
          leaveId: leaveId,
          status: status,
        );
      } else if (notification.type == 'leave_request_employee') {
        final userId = meta['userId']?.toString();
        if (userId == null) {
          _show('Employee reference missing');
          return;
        }
        await ref.read(appStateProvider.notifier).approveEmployeeLeave(
          userId,
          leaveId: leaveId,
          status: status,
        );
      }

      await ref.read(appStateProvider.notifier).fetchNotifications();
      _show('Leave request updated');
    } catch (e) {
      _show('Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(appStateProvider.notifier).fetchNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () => ref.read(appStateProvider.notifier).fetchNotifications(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alerts & Notifications',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${state.notifications.length} notification${state.notifications.length != 1 ? 's' : ''}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (state.loading) const LinearProgressIndicator(),
          if (state.notifications.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You will receive alerts about trips, payments, and system updates here',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            )
          else
            ...state.notifications.map((n) {
              final isRead = n.isRead;
              final isPending = n.status == 'pending';

              Widget? actionArea;
              if (isPending && n.type == 'fastag_request') {
                actionArea = FilledButton(
                  onPressed: () => _promptFastagAmount(n),
                  child: const Text('Enter Amount'),
                );
              } else if (isPending && (n.type == 'leave_request_driver' || n.type == 'leave_request_employee')) {
                actionArea = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => _handleLeaveAction(n, 'rejected'),
                      child: const Text('Reject'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => _handleLeaveAction(n, 'approved'),
                      child: const Text('Approve'),
                    ),
                  ],
                );
              }

              return EnhancedCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 40,
                          color: isRead ? Colors.transparent : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            n.title,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isRead
                                  ? theme.colorScheme.onSurfaceVariant
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text(n.status.toUpperCase()),
                          backgroundColor: n.status == 'completed'
                              ? theme.colorScheme.surfaceVariant
                              : theme.colorScheme.primaryContainer,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      n.message,
                      style: theme.textTheme.bodySmall,
                    ),
                    if (actionArea != null) ...[
                      const SizedBox(height: 12),
                      actionArea,
                    ],
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: isRead
                          ? Icon(
                              Icons.done_all,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            )
                          : IconButton(
                              icon: Icon(
                                Icons.mark_email_read_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              onPressed: () =>
                                  ref.read(appStateProvider.notifier).markNotificationRead(n.id),
                            ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

