import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../models/trip.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';

class BillingPage extends ConsumerStatefulWidget {
  const BillingPage({super.key});

  @override
  ConsumerState<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends ConsumerState<BillingPage> {
  static final RegExp _mongoIdRegex = RegExp(r'^[a-fA-F0-9]{24}$');

  TextEditingController? _tripIdController;
  final _customerName = TextEditingController();
  final _pickupLocation = TextEditingController();
  final _dropLocation = TextEditingController();
  final _tripDate = TextEditingController();
  final _vehicleNumber = TextEditingController();
  final _driverName = TextEditingController();
  final _distance = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _startKm = TextEditingController(text: '0');
  final _endKm = TextEditingController(text: '0');
  final _totalKm = TextEditingController(text: '0');
  final _ratePerKm = TextEditingController(text: '0');
  final _dayRent = TextEditingController(text: '0');
  final _totalDays = TextEditingController(text: '0');
  final _hourRate = TextEditingController(text: '0');
  final _totalHours = TextEditingController(text: '0');
  final _driverBata = TextEditingController(text: '0');
  final _toll = TextEditingController(text: '0');
  final _permit = TextEditingController(text: '0');
  final _parking = TextEditingController(text: '0');
  final _waiting = TextEditingController(text: '0');
  final _extra = TextEditingController(text: '0');
  final _fastag = TextEditingController(text: '0');
  final _advance = TextEditingController(text: '0');
  final _gstPercent = TextEditingController(text: '0');
  final _total = TextEditingController(text: '0');
  final _gstAmount = TextEditingController(text: '0');
  final _finalAmount = TextEditingController(text: '0');
  final _paidAmount = TextEditingController(text: '0');
  final _balanceAmount = TextEditingController(text: '0');
  final _search = TextEditingController();
  DateTime? _filterDate;

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  Timer? _debounce;
  TripModel? _cachedTrip;
  String? _lastTripId;
  String? _tripStatus;
  bool _fetchingTrip = false;
  bool _isRecalculating = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(appStateProvider.notifier).fetchBills();
      await ref.read(appStateProvider.notifier).fetchTrips();
    });
    for (final controller in [
      _startKm,
      _endKm,
      _totalKm,
      _ratePerKm,
      _dayRent,
      _totalDays,
      _hourRate,
      _totalHours,
      _driverBata,
      _toll,
      _permit,
      _parking,
      _waiting,
      _extra,
      _fastag,
      _advance,
      _gstPercent,
    ]) {
      controller.addListener(_recalculate);
    }
    _startKm.addListener(_syncTotalKmFromStartEnd);
    _endKm.addListener(_syncTotalKmFromStartEnd);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tripIdController?.removeListener(_handleTripIdInput);
    _customerName.dispose();
    _pickupLocation.dispose();
    _dropLocation.dispose();
    _tripDate.dispose();
    _vehicleNumber.dispose();
    _driverName.dispose();
    _distance.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _startKm.dispose();
    _endKm.dispose();
    _totalKm.dispose();
    _ratePerKm.dispose();
    _dayRent.dispose();
    _totalDays.dispose();
    _hourRate.dispose();
    _totalHours.dispose();
    _driverBata.dispose();
    _toll.dispose();
    _permit.dispose();
    _parking.dispose();
    _waiting.dispose();
    _extra.dispose();
    _fastag.dispose();
    _advance.dispose();
    _gstPercent.dispose();
    _total.dispose();
    _gstAmount.dispose();
    _finalAmount.dispose();
    _paidAmount.dispose();
    _balanceAmount.dispose();
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

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String get _tripIdValue => _tripIdController?.text.trim() ?? '';
  String _formatTime(TimeOfDay? time) {
    if (time == null) return '-';
    final resolved = TimeOfDay(hour: time.hour, minute: time.minute);
    return resolved.format(context);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final current = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? TimeOfDay.now(),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
        _startTimeController.text = _formatTime(picked);
      } else {
        _endTime = picked;
        _endTimeController.text = _formatTime(picked);
      }
      _syncTotalHoursFromTimes();
    });
  }

  void _syncTotalKmFromStartEnd() {
    final start = double.tryParse(_startKm.text.trim());
    final end = double.tryParse(_endKm.text.trim());
    if (start == null || end == null) return;
    final total = (end - start).clamp(0, 1000000);
    _totalKm.text = total.toStringAsFixed(0);
  }

  void _syncTotalHoursFromTimes() {
    if (_startTime == null || _endTime == null) return;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, _startTime!.hour, _startTime!.minute);
    final end = DateTime(now.year, now.month, now.day, _endTime!.hour, _endTime!.minute);
    final diff = end.difference(start).inMinutes;
    final hours = diff > 0 ? diff / 60 : 0;
    _totalHours.text = hours.toStringAsFixed(2);
  }


  void _handleTripIdInput() {
    _onTripIdChanged(_tripIdValue);
  }

  void _onTripIdChanged(String value) {
    _debounce?.cancel();
    if (value.isEmpty) {
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadTrip(value);
    });
  }

  Future<void> _loadTrip(String tripId) async {
    if (!_mongoIdRegex.hasMatch(tripId)) {
      return;
    }
    if (_lastTripId == tripId && _cachedTrip != null) {
      _applyTrip(_cachedTrip!);
      return;
    }

    setState(() => _fetchingTrip = true);
    try {
      final trip = await ref.read(appStateProvider.notifier).fetchTripById(tripId);
      _cachedTrip = trip;
      _lastTripId = tripId;
      _applyTrip(trip);
      await _checkExistingBill(tripId);
    } catch (e) {
      _show(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _fetchingTrip = false);
      }
    }
  }

  Future<void> _checkExistingBill(String tripId) async {
    try {
      final existing = await ref.read(appStateProvider.notifier).checkBillByTripId(tripId);
      if (existing != null && mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Invoice already exists'),
            content: Text('Invoice ${existing.billCode} already exists for this trip.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              FilledButton(
                onPressed: () {
                  _search.text = existing.billCode;
                  setState(() {});
                  Navigator.pop(context);
                },
                child: const Text('Search Invoice'),
              ),
            ],
          ),
        );
      }
    } catch (_) {
      // Ignore check failures to avoid blocking billing.
    }
  }

  void _applyTrip(TripModel trip) {
    _customerName.text = trip.customerName;
    _pickupLocation.text = trip.pickupLocation;
    _dropLocation.text = trip.placesToVisit.isNotEmpty ? trip.placesToVisit.last : '-';
    _tripDate.text = trip.pickupDateTime != null
        ? DateFormat.yMMMd().format(trip.pickupDateTime!)
        : '-';
    _vehicleNumber.text = trip.vehicleNumber ?? '-';
    _driverName.text = trip.driverName ?? '-';
    final startKm = trip.startKm ?? 0;
    final endKm = trip.endKm ?? 0;
    _startKm.text = startKm.toString();
    _endKm.text = endKm.toString();
    _totalKm.text = (endKm - startKm).clamp(0, 1000000).toString();
    _distance.text = _totalKm.text;
    _totalDays.text = trip.numberOfDays.toString();
    _driverBata.text = trip.driverBataAssigned.toStringAsFixed(2);
    _toll.text = trip.tollAmount.toStringAsFixed(2);
    _permit.text = (trip.permitCharges > 0 ? trip.permitCharges : trip.permitAmount).toStringAsFixed(2);
    _parking.text = (trip.parkingCharges > 0 ? trip.parkingCharges : trip.parkingAmount).toStringAsFixed(2);
    _extra.text = trip.extraCharges.toStringAsFixed(2);
    _fastag.text = trip.fastagAmount.toStringAsFixed(2);
    _advance.text = (trip.totalAdvance > 0 ? trip.totalAdvance : trip.advanceTotal).toStringAsFixed(2);
    if (trip.startTime != null) {
      _startTime = TimeOfDay.fromDateTime(trip.startTime!);
      _startTimeController.text = _formatTime(_startTime);
    }
    if (trip.endTime != null) {
      _endTime = TimeOfDay.fromDateTime(trip.endTime!);
      _endTimeController.text = _formatTime(_endTime);
    }
    _syncTotalHoursFromTimes();
    _tripStatus = trip.status;
    _recalculate();
  }

  double _parse(TextEditingController controller) {
    return double.tryParse(controller.text.trim()) ?? 0;
  }

  String _displayPaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'COMPLETED';
      case 'partial':
        return 'PARTIAL';
      case 'pending':
      default:
        return status.toUpperCase();
    }
  }

  void _recalculate() {
    if (_isRecalculating) return;
    _isRecalculating = true;

    final totalKm = _parse(_totalKm);
    final ratePerKm = _parse(_ratePerKm);
    final dayRent = _parse(_dayRent);
    final totalDays = _parse(_totalDays);
    final hourRate = _parse(_hourRate);
    final totalHours = _parse(_totalHours);
    final driverBata = _parse(_driverBata);
    final toll = _parse(_toll);
    final permit = _parse(_permit);
    final parking = _parse(_parking);
    final waiting = _parse(_waiting);
    final extra = _parse(_extra);
    final fastag = _parse(_fastag);
    final advance = _parse(_advance);
    final paid = _parse(_paidAmount);
    final gstPercent = _parse(_gstPercent);

    final kmCharge = totalKm * ratePerKm;
    final dayCharge = totalDays * dayRent;
    final hourCharge = totalHours * hourRate;
    final total = kmCharge + dayCharge + hourCharge + toll + permit + parking + driverBata + waiting + extra + fastag;
    final gstAmount = total * (gstPercent / 100);
    final finalAmount = (total + gstAmount - advance).clamp(0, double.infinity);
    final balance = (finalAmount - paid).clamp(0, double.infinity);

    _total.text = total.toStringAsFixed(2);
    _gstAmount.text = gstAmount.toStringAsFixed(2);
    _finalAmount.text = finalAmount.toStringAsFixed(2);
    _balanceAmount.text = balance.toStringAsFixed(2);

    _isRecalculating = false;
  }

  Future<void> _createBill() async {
    final role = ref.read(authProvider).role;
    if (role != 'owner' && role != 'employee') {
      _show('You do not have permission to create invoices');
      return;
    }

    final tripIdInput = _tripIdValue;
    if (tripIdInput.isNotEmpty && !_mongoIdRegex.hasMatch(tripIdInput)) {
      _show('Enter a valid Trip ID');
      return;
    }

    if (_tripStatus != null && !['completed', 'approved'].contains(_tripStatus)) {
      _show('Billing allowed only for completed/approved trips');
      return;
    }

    if (tripIdInput.isNotEmpty) {
      final existing = await ref.read(appStateProvider.notifier).checkBillByTripId(tripIdInput);
      if (existing != null) {
        _show('Invoice already exists for this trip');
        return;
      }
    }

    try {
      final payload = {
        if (tripIdInput.isNotEmpty) 'tripId': tripIdInput,
        'billDate': DateTime.now().toIso8601String(),
        'tripDate': _cachedTrip?.pickupDateTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'customerName': _customerName.text.trim(),
        'pickupLocation': _pickupLocation.text.trim(),
        'dropLocation': _dropLocation.text.trim(),
        'vehicleNumber': _vehicleNumber.text.trim(),
        'driverName': _driverName.text.trim(),
        'tripStatus': _tripStatus,
        'startKm': _parse(_startKm),
        'endKm': _parse(_endKm),
        'totalKm': _parse(_totalKm),
        'ratePerKm': _parse(_ratePerKm),
        'dayRent': _parse(_dayRent),
        'totalDays': _parse(_totalDays),
        'numberOfDays': _parse(_totalDays),
        'hourRent': _parse(_hourRate),
        'totalHours': _parse(_totalHours),
        'numberOfHours': _parse(_totalHours),
        'driverBata': _parse(_driverBata),
        'tollCharges': _parse(_toll),
        'permitCharges': _parse(_permit),
        'parkingCharges': _parse(_parking),
        'waitingCharges': _parse(_waiting),
        'extraCharges': _parse(_extra),
        'fastagCharges': _parse(_fastag),
        'advanceReceived': _parse(_advance),
        'gstPercent': _parse(_gstPercent),
        if (_startTime != null)
          'startTime': DateTime.now()
              .copyWith(hour: _startTime!.hour, minute: _startTime!.minute)
              .toIso8601String(),
        if (_endTime != null)
          'endTime': DateTime.now()
              .copyWith(hour: _endTime!.hour, minute: _endTime!.minute)
              .toIso8601String(),
      };

      final bill = await ref.read(appStateProvider.notifier).createBill(payload);
      _show('Invoice generated successfully');

      final pdfUrl = AppConfig.getApiEndpoint('/bill/${bill.id}/pdf');
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Invoice Ready'),
            content: const Text('Preview and download the invoice PDF now?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await launchUrl(Uri.parse(pdfUrl), mode: LaunchMode.externalApplication);
                },
                child: const Text('Preview PDF'),
              ),
            ],
          ),
        );
      }
    } catch (error) {
      _show(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Widget _numberField(TextEditingController controller, String label, {bool enabled = true}) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final theme = Theme.of(context);
    final query = _search.text.trim().toLowerCase();
    final visibleBills = state.bills.where((bill) {
      final queryMatched = query.isEmpty ||
          bill.billCode.toLowerCase().contains(query) ||
          bill.customerName.toLowerCase().contains(query) ||
          bill.vehicleNumber.toLowerCase().contains(query) ||
          (bill.tripId ?? '').toLowerCase().contains(query) ||
          (bill.driverName ?? '').toLowerCase().contains(query) ||
          bill.paymentStatus.toLowerCase().contains(query);
      final dateMatched = _matchesDate(bill.billDate, _filterDate);
      return queryMatched && dateMatched;
    }).toList();

    final completedTrips = state.trips
        .where((trip) => ['completed', 'approved'].contains(trip.status))
        .toList();

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
                  Text('Create Invoice', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Autocomplete<TripModel>(
                    optionsBuilder: (value) {
                      final input = value.text.trim().toLowerCase();
                      if (input.isEmpty) return const Iterable<TripModel>.empty();
                      return completedTrips.where((trip) {
                        final vehicle = trip.vehicleNumber ?? '';
                        final haystack = '${trip.id} ${trip.customerName} $vehicle'.toLowerCase();
                        return haystack.contains(input);
                      });
                    },
                    displayStringForOption: (trip) => trip.id,
                    onSelected: (trip) {
                      _tripIdController?.text = trip.id;
                      _applyTrip(trip);
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      if (_tripIdController == null) {
                        _tripIdController = controller;
                        _tripIdController!.addListener(_handleTripIdInput);
                      }
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Trip ID',
                          suffixIcon: _fetchingTrip
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: null,
                    hint: const Text('Recent Completed Trips'),
                    items: completedTrips.take(6).map((trip) {
                      return DropdownMenuItem(
                        value: trip.id,
                        child: Text('${trip.id.substring(trip.id.length - 6)} - ${trip.customerName}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      _tripIdController?.text = value;
                      _loadTrip(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_cachedTrip != null)
                    Card(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Customer: ${_customerName.text}', style: theme.textTheme.bodyMedium),
                                  Text('Route: ${_pickupLocation.text} -> ${_dropLocation.text}'),
                                  Text('Vehicle: ${_vehicleNumber.text}'),
                                  Text('Driver: ${_driverName.text}'),
                                ],
                              ),
                            ),
                            Chip(label: Text((_tripStatus ?? '').toUpperCase())),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    runSpacing: 12,
                    spacing: 12,
                    children: [
                      SizedBox(width: 280, child: TextField(controller: _customerName, decoration: const InputDecoration(labelText: 'Customer Name'))),
                      SizedBox(width: 280, child: TextField(controller: _pickupLocation, decoration: const InputDecoration(labelText: 'Pickup Location'))),
                      SizedBox(width: 280, child: TextField(controller: _dropLocation, decoration: const InputDecoration(labelText: 'Drop Location'))),
                      SizedBox(width: 200, child: TextField(controller: _tripDate, enabled: false, decoration: const InputDecoration(labelText: 'Trip Date'))),
                      SizedBox(width: 200, child: TextField(controller: _vehicleNumber, decoration: const InputDecoration(labelText: 'Vehicle Number'))),
                      SizedBox(width: 200, child: TextField(controller: _driverName, decoration: const InputDecoration(labelText: 'Driver Name'))),
                      SizedBox(width: 200, child: TextField(controller: _distance, enabled: false, decoration: const InputDecoration(labelText: 'Total KM'))),
                      SizedBox(width: 200, child: _numberField(_startKm, 'Starting KM')),
                      SizedBox(width: 200, child: _numberField(_endKm, 'Closing KM')),
                      SizedBox(width: 200, child: _numberField(_totalKm, 'Total KM')),
                      SizedBox(
                        width: 200,
                        child: TextField(
                          readOnly: true,
                          decoration: const InputDecoration(labelText: 'Start Time'),
                          controller: _startTimeController,
                          onTap: () => _pickTime(isStart: true),
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: TextField(
                          readOnly: true,
                          decoration: const InputDecoration(labelText: 'End Time'),
                          controller: _endTimeController,
                          onTap: () => _pickTime(isStart: false),
                        ),
                      ),
                      SizedBox(width: 200, child: _numberField(_totalHours, 'Total Hours')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Charges', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    runSpacing: 12,
                    spacing: 12,
                    children: [
                      SizedBox(width: 200, child: _numberField(_ratePerKm, 'Charge Per KM')),
                      SizedBox(width: 200, child: _numberField(_dayRent, 'Day Rent')),
                      SizedBox(width: 200, child: _numberField(_totalDays, 'Number of Days')),
                      SizedBox(width: 200, child: _numberField(_hourRate, 'Charge Per Hour')),
                      SizedBox(width: 200, child: _numberField(_driverBata, 'Driver Bata')),
                      SizedBox(width: 200, child: _numberField(_toll, 'Toll Charges')),
                      SizedBox(width: 200, child: _numberField(_permit, 'Permit Charges')),
                      SizedBox(width: 200, child: _numberField(_parking, 'Parking Charges')),
                      SizedBox(width: 200, child: _numberField(_waiting, 'Waiting Charges')),
                      SizedBox(width: 200, child: _numberField(_extra, 'Extra Charges')),
                      SizedBox(width: 200, child: _numberField(_fastag, 'FASTag Amount')),
                      SizedBox(width: 200, child: _numberField(_advance, 'Advance Paid')),
                      SizedBox(width: 200, child: _numberField(_gstPercent, 'GST %')),
                      SizedBox(width: 200, child: _numberField(_total, 'Total', enabled: false)),
                      SizedBox(width: 200, child: _numberField(_gstAmount, 'GST Amount', enabled: false)),
                      SizedBox(width: 200, child: _numberField(_finalAmount, 'Payable Amount', enabled: false)),
                      SizedBox(width: 200, child: _numberField(_paidAmount, 'Paid Amount', enabled: false)),
                      SizedBox(width: 200, child: _numberField(_balanceAmount, 'Balance', enabled: false)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _createBill,
                    child: const Text('Generate Invoice'),
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
                  Text('Find Bills', style: theme.textTheme.titleMedium),
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
          if (state.error != null)
            Text(state.error!, style: TextStyle(color: theme.colorScheme.error)),
          ...visibleBills.map(
            (bill) => Card(
              child: ListTile(
                title: Text('${bill.billCode} - ${bill.customerName}'),
                subtitle: Text(
                  'Trip: ${bill.tripId ?? '-'} - Driver: ${bill.driverName ?? '-'}\n'
                  'Total: ${bill.totalAmount.toStringAsFixed(2)} - Advance: ${bill.advanceReceived.toStringAsFixed(2)}\n'
                  'Paid: ${bill.paidAmount.toStringAsFixed(2)} - Remaining: ${bill.remainingAmount.toStringAsFixed(2)}\n'
                  '${DateFormat.yMMMd().format(bill.billDate ?? DateTime.now())}',
                ),
                isThreeLine: true,
                trailing: Chip(label: Text(_displayPaymentStatus(bill.paymentStatus))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
