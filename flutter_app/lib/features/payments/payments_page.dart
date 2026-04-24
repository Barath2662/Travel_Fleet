import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';

class PaymentsPage extends ConsumerStatefulWidget {
  const PaymentsPage({super.key});

  @override
  ConsumerState<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends ConsumerState<PaymentsPage> {
  final _search = TextEditingController();
  DateTime? _filterDate;
  String _statusFilter = 'all';
  bool _paymentActionInProgress = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final app = ref.read(appStateProvider.notifier);
      await app.fetchBills();
      await app.fetchPayments();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matchesDate(DateTime? billDate, DateTime? filterDate) {
    if (filterDate == null) return true;
    if (billDate == null) return false;
    return billDate.year == filterDate.year && billDate.month == filterDate.month && billDate.day == filterDate.day;
  }

  Future<void> _pickFilterDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 3),
    );
    if (selected != null) {
      setState(() => _filterDate = selected);
    }
  }

  Future<void> _addPayment({
    required String billId,
    required double amount,
    required String mode,
    required String note,
  }) async {
    if (_paymentActionInProgress) return;

    if (amount <= 0) {
      _show('Amount must be greater than 0');
      return;
    }

    setState(() => _paymentActionInProgress = true);
    try {
      await ref.read(appStateProvider.notifier).createPayment({
        'billId': billId,
        'amount': amount,
        'status': 'paid',
        'mode': mode,
        'notes': note,
      });
      _show('Payment updated');
    } catch (error) {
      _show(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _paymentActionInProgress = false);
      }
    }
  }

  Future<void> _addPartialPayment(String billId) async {
    final amountController = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Partial Payment'),
        content: TextField(
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(amountController.text.trim());
              if (value == null || value <= 0) {
                _show('Enter a valid amount');
                return;
              }
              Navigator.pop(context, value);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (amount == null) return;
    await _addPayment(
      billId: billId,
      amount: amount,
      mode: 'partial',
      note: 'Partial payment from app',
    );
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final role = ref.watch(authProvider).role;
    final canManagePayments = role == 'owner';
    final search = _search.text.trim().toLowerCase();
    final visibleBills = state.bills.where((bill) {
      final queryMatch = search.isEmpty ||
          bill.billCode.toLowerCase().contains(search) ||
          bill.customerName.toLowerCase().contains(search);
      final statusMatch = _statusFilter == 'all' || bill.paymentStatus == _statusFilter;
      final dateMatch = _matchesDate(bill.billDate, _filterDate);
      return queryMatch && statusMatch && dateMatch;
    }).toList();
    final recentPayments = state.payments.take(10).toList();

    return RefreshIndicator(
      onRefresh: () async {
        final app = ref.read(appStateProvider.notifier);
        await app.fetchBills();
        await app.fetchPayments();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Tracking', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    canManagePayments
                        ? 'Use actions on each bill to mark paid, add partial payment, or pay remaining.'
                        : 'You can view payment progress. Payment actions are restricted to owner role.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Search by Bill ID or Customer',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _statusFilter,
                    decoration: const InputDecoration(labelText: 'Status Filter'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'partial', child: Text('Partial')),
                      DropdownMenuItem(value: 'paid', child: Text('Paid')),
                    ],
                    onChanged: (value) => setState(() => _statusFilter = value ?? 'all'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _filterDate == null
                              ? 'All dates'
                              : 'Date: ${DateFormat.yMMMd().format(_filterDate!)}',
                        ),
                      ),
                      TextButton(onPressed: _pickFilterDate, child: const Text('Pick Date')),
                      if (_filterDate != null)
                        TextButton(onPressed: () => setState(() => _filterDate = null), child: const Text('Clear')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (state.loading) const LinearProgressIndicator(),
          ...visibleBills.map(
            (bill) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${bill.billCode} • ${bill.customerName}', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text('Date: ${DateFormat.yMMMd().format(bill.billDate ?? DateTime.now())}'),
                    Text('Total: ${bill.totalAmount.toStringAsFixed(2)} • Payable: ${bill.payableAmount.toStringAsFixed(2)}'),
                    Text('Paid: ${bill.paidAmount.toStringAsFixed(2)} • Remaining: ${bill.remainingAmount.toStringAsFixed(2)}'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Chip(label: Text(bill.paymentStatus.toUpperCase())),
                        const Spacer(),
                        if (canManagePayments && bill.remainingAmount > 0)
                          OutlinedButton(
                            onPressed: _paymentActionInProgress
                                ? null
                                : () => _addPayment(
                                      billId: bill.id,
                                      amount: bill.remainingAmount,
                                      mode: bill.paymentStatus == 'partial' ? 'remaining' : 'full',
                                      note: 'Settlement from app',
                                    ),
                            child: Text(bill.paymentStatus == 'partial' ? 'Pay Remaining' : 'Mark as Paid'),
                          ),
                      ],
                    ),
                    if (canManagePayments && bill.remainingAmount > 0)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _paymentActionInProgress ? null : () => _addPartialPayment(bill.id),
                          child: const Text('Add Partial Payment'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Recent Payments', style: Theme.of(context).textTheme.titleMedium),
          ...recentPayments.map(
            (p) => Card(
              child: ListTile(
                title: Text('${p.billCode ?? p.billId} • ${p.amount.toStringAsFixed(2)}'),
                subtitle: Text('${p.customerName ?? 'Customer'} • ${p.paidAt != null ? DateFormat.yMMMd().add_jm().format(p.paidAt!) : 'No date'}'),
                trailing: Chip(label: Text(p.status.toUpperCase())),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
