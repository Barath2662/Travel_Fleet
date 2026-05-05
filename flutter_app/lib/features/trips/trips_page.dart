import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/trip.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';
import 'trip_tracking_page.dart';

class TripsPage extends ConsumerStatefulWidget {
  const TripsPage({super.key});

  @override
  ConsumerState<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends ConsumerState<TripsPage> {
  final _customerName = TextEditingController();
  final _customerMobile = TextEditingController();
  final _pickupLocation = TextEditingController();
  final _places = TextEditingController();
  final _days = TextEditingController(text: '1');
  DateTime _pickupDateTime = DateTime.now();
  String? _driverId;
  String? _vehicleId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final app = ref.read(appStateProvider.notifier);
      await app.fetchDrivers();
      await app.fetchVehicles();
      await app.fetchTrips();
    });
  }

  @override
  void dispose() {
    _customerName.dispose();
    _customerMobile.dispose();
    _pickupLocation.dispose();
    _places.dispose();
    _days.dispose();
    super.dispose();
  }

  Future<void> _pickPickupDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _pickupDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_pickupDateTime),
    );

    if (time == null) return;

    setState(() {
      _pickupDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _createTrip() async {
    if (_customerName.text.trim().isEmpty || _customerMobile.text.trim().isEmpty) {
      _show('Customer name and mobile number are required');
      return;
    }

    if (_pickupLocation.text.trim().isEmpty || _driverId == null || _vehicleId == null) {
      _show('Pickup location, driver, and vehicle are required');
      return;
    }

    await ref.read(appStateProvider.notifier).createTrip({
      'pickupDateTime': _pickupDateTime.toIso8601String(),
      'customerName': _customerName.text.trim(),
      'customerMobile': _customerMobile.text.trim(),
      'pickupLocation': _pickupLocation.text.trim(),
      'placesToVisit': _places.text.trim().isEmpty ? ['Local'] : _places.text.split(',').map((e) => e.trim()).toList(),
      'numberOfDays': int.tryParse(_days.text) ?? 1,
      'driverId': _driverId,
      'vehicleId': _vehicleId,
    });

    _customerName.clear();
    _customerMobile.clear();
    _pickupLocation.clear();
    _places.clear();
    _days.text = '1';
    setState(() {
      _driverId = null;
      _vehicleId = null;
      _pickupDateTime = DateTime.now();
    });
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _assignBata(String tripId, double currentAmount) async {
    final controller = TextEditingController(
      text: currentAmount > 0 ? currentAmount.toStringAsFixed(0) : '',
    );

    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Driver Bata'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Bata Amount'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim());
              if (parsed == null || parsed < 0) {
                _show('Enter a valid amount');
                return;
              }
              Navigator.pop(context, parsed);
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );

    if (amount == null) return;
    await ref.read(appStateProvider.notifier).assignTripBata(tripId, amount);
    _show('Driver bata assigned');
  }

  Future<void> _startTrip(String tripId, TripModel trip) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripTrackingPage(tripId: tripId, trip: trip),
      ),
    );
    if (result != null) {
      _show('Trip started successfully');
    }
  }

  Future<void> _endTrip(String tripId, TripModel trip) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripTrackingPage(tripId: tripId, trip: trip),
      ),
    );
    if (result != null) {
      _show('Trip ended successfully');
    }
  }

  Future<void> _addAdvance(String tripId) async {
    final controller = TextEditingController();
    
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Advance Received'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Advance Amount'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (controller.text.isEmpty) {
                _show('Enter advance amount');
                return;
              }
              final parsed = double.tryParse(controller.text.trim());
              if (parsed == null || parsed <= 0) {
                _show('Enter a valid amount');
                return;
              }
              Navigator.pop(context, parsed);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (amount == null) return;
    await ref.read(appStateProvider.notifier).addAdvance(tripId, amount);
    _show('Advance amount added');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final role = ref.watch(authProvider).role;
    final isWide = MediaQuery.of(context).size.width > 760;
    final dateLabel = DateFormat('dd MMM yyyy • HH:mm').format(_pickupDateTime);
    final visibleTrips = state.trips;

    return RefreshIndicator(
      onRefresh: () async {
        final app = ref.read(appStateProvider.notifier);
        await app.fetchDrivers();
        await app.fetchVehicles();
        await app.fetchTrips();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (role == 'owner' || role == 'employee')
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Schedule Trip', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    if (isWide)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _customerName,
                              decoration: const InputDecoration(labelText: 'Customer Name'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _customerMobile,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(labelText: 'Mobile Number'),
                            ),
                          ),
                        ],
                      )
                    else ...[
                      TextField(
                        controller: _customerName,
                        decoration: const InputDecoration(labelText: 'Customer Name'),
                      ),
                      TextField(
                        controller: _customerMobile,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Mobile Number'),
                      ),
                    ],
                    TextField(controller: _pickupLocation, decoration: const InputDecoration(labelText: 'Pickup Location')),
                    TextField(controller: _places, decoration: const InputDecoration(labelText: 'Places to Visit (comma separated)')),
                    TextField(controller: _days, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Number of Days')),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: _pickPickupDateTime,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Pickup Date & Time',
                          suffixIcon: Icon(Icons.schedule),
                        ),
                        child: Text(dateLabel),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (isWide)
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _driverId,
                              decoration: const InputDecoration(labelText: 'Select Driver'),
                              items: state.drivers
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d.id,
                                      child: Text('${d.name} (${d.phone})'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) => setState(() => _driverId = value),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _vehicleId,
                              decoration: const InputDecoration(labelText: 'Select Vehicle'),
                              items: state.vehicles
                                  .map(
                                    (v) => DropdownMenuItem(
                                      value: v.id,
                                      child: Text(v.number),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) => setState(() => _vehicleId = value),
                            ),
                          ),
                        ],
                      )
                    else ...[
                      DropdownButtonFormField<String>(
                        initialValue: _driverId,
                        decoration: const InputDecoration(labelText: 'Select Driver'),
                        items: state.drivers
                            .map(
                              (d) => DropdownMenuItem(
                                value: d.id,
                                child: Text('${d.name} (${d.phone})'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _driverId = value),
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: _vehicleId,
                        decoration: const InputDecoration(labelText: 'Select Vehicle'),
                        items: state.vehicles
                            .map(
                              (v) => DropdownMenuItem(
                                value: v.id,
                                child: Text(v.number),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _vehicleId = value),
                      ),
                    ],
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _createTrip,
                      child: const Text('Schedule Trip'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (state.loading) const LinearProgressIndicator(),
          if (state.error != null) Text(state.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ...visibleTrips.map(
            (trip) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TRIP ID: ${trip.id.substring(trip.id.length > 6 ? trip.id.length - 6 : 0).toUpperCase()}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: trip.status == 'in_progress' ? Colors.orange.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            trip.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: trip.status == 'in_progress' ? Colors.orange : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${trip.customerName} • ${trip.pickupLocation}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        'Contact: ${trip.customerMobile}\n'
                        'Driver: ${trip.driverName ?? '-'} | Vehicle: ${trip.vehicleNumber ?? '-'}\n'
                        'Days: ${trip.numberOfDays} • Bata: ${trip.driverBataAssigned.toStringAsFixed(0)}',
                      ),
                      isThreeLine: true,
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        if ((role == 'owner' || role == 'employee') && trip.status != 'completed')
                          OutlinedButton.icon(
                            onPressed: () => _assignBata(trip.id, trip.driverBataAssigned),
                            icon: const Icon(Icons.attach_money, size: 16),
                            label: const Text('Assign Bata'),
                          ),
                        if (role == 'driver' && trip.status == 'scheduled')
                          FilledButton.icon(
                            onPressed: () => _startTrip(trip.id, trip),
                            icon: const Icon(Icons.play_arrow, size: 16),
                            label: const Text('Start'),
                          ),
                        if (role == 'driver' && trip.status == 'in_progress')
                          FilledButton.icon(
                            onPressed: () => _endTrip(trip.id, trip),
                            icon: const Icon(Icons.stop, size: 16),
                            label: const Text('End'),
                          ),
                        OutlinedButton.icon(
                          onPressed: () => _addAdvance(trip.id),
                          icon: const Icon(Icons.money, size: 16),
                          label: const Text('Advance'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
