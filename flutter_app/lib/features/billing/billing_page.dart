import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';

class BillingPage extends ConsumerStatefulWidget {
  const BillingPage({super.key});

  @override
  ConsumerState<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends ConsumerState<BillingPage> {
  static final RegExp _mongoIdRegex = RegExp(r'^[a-fA-F0-9]{24}$');

  final _tripId = TextEditingController();
  final _vehicleNumber = TextEditingController();
  final _tripDetails = TextEditingController();
  final _startKm = TextEditingController();
  final _endKm = TextEditingController();
  final _ratePerKm = TextEditingController();
  final _dayRent = TextEditingController(text: '0');
  final _hourRent = TextEditingController(text: '0');
  final _driverBata = TextEditingController(text: '0');
  final _toll = TextEditingController(text: '0');
  final _fastag = TextEditingController(text: '0');
  final _permit = TextEditingController(text: '0');
  final _parking = TextEditingController(text: '0');
  final _advance = TextEditingController(text: '0');
  final _search = TextEditingController();
  DateTime? _filterDate;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(appStateProvider.notifier).fetchBills());
  }

  @override
  void dispose() {
    _tripId.dispose();
    _vehicleNumber.dispose();
    _tripDetails.dispose();
    _startKm.dispose();
    _endKm.dispose();
    _ratePerKm.dispose();
    _dayRent.dispose();
    _hourRent.dispose();
    _driverBata.dispose();
    _toll.dispose();
    _fastag.dispose();
    _permit.dispose();
    _parking.dispose();
    _advance.dispose();
    _search.dispose();
    super.dispose();
  }

  bool _matchesDate(DateTime? billDate, DateTime? filterDate) {
    if (filterDate == null) return true;
    if (billDate == null) return false;
    return billDate.year == filterDate.year &&
        billDate.month == filterDate.month &&
        billDate.day == filterDate.day;
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

  Future<void> _createBill() async {
    final tripIdInput = _tripId.text.trim();
    final vehicleNumber = _vehicleNumber.text.trim();
    final tripDetails = _tripDetails.text.trim();
    final tripId = _mongoIdRegex.hasMatch(tripIdInput) ? tripIdInput : null;
    final startKm = double.tryParse(_startKm.text) ?? 0;
    final endKm = double.tryParse(_endKm.text) ?? 0;
    final ratePerKm = double.tryParse(_ratePerKm.text) ?? 0;

    try {
      await ref.read(appStateProvider.notifier).createBill({
        if (tripId != null) 'tripId': tripId,
        'billDate': DateTime.now().toIso8601String(),
        'tripDate': DateTime.now().toIso8601String(),
        if (vehicleNumber.isNotEmpty) 'vehicleNumber': vehicleNumber,
        'tripDetails': tripDetails.isEmpty ? 'Business trip' : tripDetails,
        'startKm': startKm,
        'endKm': endKm,
        'ratePerKm': ratePerKm,
        'dayRent': double.tryParse(_dayRent.text) ?? 0,
        'hourRent': double.tryParse(_hourRent.text) ?? 0,
        'numberOfDays': 1,
        'numberOfHours': 0,
        'driverBata': double.tryParse(_driverBata.text) ?? 0,
        'tollCharges': double.tryParse(_toll.text) ?? 0,
        'fastagCharges': double.tryParse(_fastag.text) ?? 0,
        'permitCharges': double.tryParse(_permit.text) ?? 0,
        'parkingCharges': double.tryParse(_parking.text) ?? 0,
        'advanceReceived': double.tryParse(_advance.text) ?? 0,
      });
      _show('Bill generated successfully');
    } catch (error) {
      _show(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _numberField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final role = ref.watch(authProvider).role;
    final query = _search.text.trim().toLowerCase();
    final visibleBills = state.bills.where((bill) {
      final queryMatched = query.isEmpty ||
          bill.billCode.toLowerCase().contains(query) ||
          bill.customerName.toLowerCase().contains(query);
      final dateMatched = _matchesDate(bill.billDate, _filterDate);
      return queryMatched && dateMatched;
    }).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(appStateProvider.notifier).fetchBills(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Create Invoice', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextField(controller: _tripId, decoration: const InputDecoration(labelText: 'Trip ID')),
                  TextField(controller: _vehicleNumber, decoration: const InputDecoration(labelText: 'Vehicle Number')),
                  TextField(controller: _tripDetails, decoration: const InputDecoration(labelText: 'Trip Details')),
                  _numberField(_startKm, 'Start KM'),
                  _numberField(_endKm, 'End KM'),
                  _numberField(_ratePerKm, 'Rate Per KM'),
                  _numberField(_dayRent, 'Day Rent'),
                  _numberField(_hourRent, 'Hour Rent'),
                  _numberField(_driverBata, 'Driver Bata'),
                  _numberField(_toll, 'Toll Charges'),
                  _numberField(_fastag, 'FASTag Charges'),
                  _numberField(_permit, 'Permit Charges'),
                  _numberField(_parking, 'Parking Charges'),
                  _numberField(_advance, 'Advance Received'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: (role == 'owner' || role == 'employee') ? _createBill : null,
                    child: const Text('Generate Bill'),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Find Bills', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Search by Bill ID or Customer',
                      prefixIcon: Icon(Icons.search),
                    ),
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
                        TextButton(
                          onPressed: () => setState(() => _filterDate = null),
                          child: const Text('Clear'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (state.loading) const LinearProgressIndicator(),
          if (state.error != null) Text(state.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ...visibleBills.map(
            (bill) => Card(
              child: ListTile(
                title: Text('${bill.billCode} • ${bill.customerName}'),
                subtitle: Text(
                  'Vehicle: ${bill.vehicleNumber}\n'
                  'Total: ${bill.totalAmount.toStringAsFixed(2)} • Paid: ${bill.paidAmount.toStringAsFixed(2)}\n'
                  'Remaining: ${bill.remainingAmount.toStringAsFixed(2)} • ${DateFormat.yMMMd().format(bill.billDate ?? DateTime.now())}',
                ),
                isThreeLine: true,
                trailing: Chip(label: Text(bill.paymentStatus.toUpperCase())),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
