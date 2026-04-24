import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';

class PaymentsPage extends ConsumerStatefulWidget {
  const PaymentsPage({super.key});

  @override
  ConsumerState<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends ConsumerState<PaymentsPage> {
  final _billId = TextEditingController();
  final _amount = TextEditingController();
  String _status = 'pending';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(appStateProvider.notifier).fetchPayments());
  }

  @override
  void dispose() {
    _billId.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _createPayment() async {
    if (_billId.text.trim().isEmpty || _amount.text.trim().isEmpty) {
      _show('Bill ID and amount are required');
      return;
    }

    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      _show('Enter a valid amount greater than 0');
      return;
    }

    try {
      await ref.read(appStateProvider.notifier).createPayment({
        'billId': _billId.text.trim(),
        'amount': amount,
        'status': _status,
        'notes': 'Updated from mobile app',
      });

      _billId.clear();
      _amount.clear();
      _show('Payment saved');
    } catch (error) {
      _show(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final role = ref.watch(authProvider).role;

    return RefreshIndicator(
      onRefresh: () => ref.read(appStateProvider.notifier).fetchPayments(),
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
                  const SizedBox(height: 12),
                  TextField(controller: _billId, decoration: const InputDecoration(labelText: 'Bill ID')),
                  TextField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'paid', child: Text('Paid')),
                    ],
                    onChanged: (value) => setState(() => _status = value ?? 'pending'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: (role == 'owner' || role == 'employee') ? _createPayment : null,
                    child: const Text('Save Payment'),
                  ),
                ],
              ),
            ),
          ),
          if (state.loading) const LinearProgressIndicator(),
          ...state.payments.map(
            (p) => Card(
              child: ListTile(
                title: Text('Amount: ${p.amount.toStringAsFixed(2)}'),
                trailing: Chip(label: Text(p.status)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
