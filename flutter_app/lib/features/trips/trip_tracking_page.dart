import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../models/trip.dart';
import '../../providers/app_state_provider.dart';

class TripTrackingPage extends ConsumerStatefulWidget {
  final String tripId;
  final TripModel trip;

  const TripTrackingPage({
    super.key,
    required this.tripId,
    required this.trip,
  });

  @override
  ConsumerState<TripTrackingPage> createState() => _TripTrackingPageState();
}

class _TripTrackingPageState extends ConsumerState<TripTrackingPage> {
  late TextEditingController _startKmController;
  late TextEditingController _endKmController;
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;
  final DateFormat _timeFormat = DateFormat('hh:mm a');
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _startKmController = TextEditingController();
    _endKmController = TextEditingController();
  }

  @override
  void dispose() {
    _startKmController.dispose();
    _endKmController.dispose();
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

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        if (result == LocationPermission.denied) {
          _show('Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _show('Location permission permanently denied');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = position;
      });

      _show(
        'Location captured\nLat: ${position.latitude.toStringAsFixed(4)}, Lon: ${position.longitude.toStringAsFixed(4)}',
      );
    } catch (e) {
      _show('Error getting location: $e');
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _startTrip() async {
    if (_startKmController.text.trim().isEmpty) {
      _show('Please enter starting KM');
      return;
    }

    final startKm = int.tryParse(_startKmController.text.trim());
    if (startKm == null || startKm < 0) {
      _show('Enter valid starting KM');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(appStateProvider.notifier).startTrip(widget.tripId, startKm);
      _show('Trip started successfully');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _show('Error: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _endTrip() async {
    if (_endKmController.text.trim().isEmpty) {
      _show('Please enter ending KM');
      return;
    }

    final endKm = int.tryParse(_endKmController.text.trim());
    if (endKm == null || endKm < 0) {
      _show('Enter valid ending KM');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(appStateProvider.notifier).endTrip(widget.tripId, {
        'endKm': endKm,
        'tollApplicable': false,
        'permitApplicable': false,
        'parkingApplicable': false,
      });
      _show('Trip ended successfully');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _show('Error: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTripsActive = widget.trip.status == 'in_progress';
    final isTripsScheduled = widget.trip.status == 'scheduled';
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Tracking'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Info Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip Details',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      theme,
                      Icons.person,
                      'Customer',
                      widget.trip.customerName,
                    ),
                    _buildDetailRow(
                      theme,
                      Icons.phone,
                      'Contact',
                      widget.trip.customerMobile,
                    ),
                    _buildDetailRow(
                      theme,
                      Icons.location_on,
                      'Pickup Location',
                      widget.trip.pickupLocation,
                    ),
                    _buildDetailRow(
                      theme,
                      Icons.directions_car,
                      'Vehicle',
                      widget.trip.vehicleNumber ?? '-',
                    ),
                    _buildDetailRow(
                      theme,
                      Icons.info,
                      'Status',
                      widget.trip.status.toUpperCase(),
                      valueColor: isTripsActive ? Colors.green : Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Location Section
            if (_currentPosition != null)
              Card(
                elevation: 1,
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Location',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, Lon: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                              style: theme.textTheme.labelSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Accuracy: ${_currentPosition!.accuracy.toStringAsFixed(1)}m',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Start Trip Section
            if (isTripsScheduled) ...[
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Trip',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Date & Time Display
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _dateFormat.format(now),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Time',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _timeFormat.format(now),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Starting KM Input
                      TextField(
                        controller: _startKmController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Starting KM',
                          prefixIcon: const Icon(Icons.speed),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          hintText: 'Enter odometer reading at start',
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Location Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                          icon: _isLoadingLocation
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.location_on_outlined),
                          label: Text(
                            _isLoadingLocation
                                ? 'Getting Location...'
                                : _currentPosition == null
                                    ? 'Capture GPS Location'
                                    : 'Update Location',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Start Button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isSubmitting ? null : _startTrip,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.play_arrow),
                          label: Text(_isSubmitting ? 'Starting...' : 'Start Trip'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // End Trip Section
            if (isTripsActive) ...[
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End Trip',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Date & Time Display
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _dateFormat.format(now),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Time',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _timeFormat.format(now),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Ending KM Input
                      TextField(
                        controller: _endKmController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Ending KM',
                          prefixIcon: const Icon(Icons.speed),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          hintText: 'Enter odometer reading at end',
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Location Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                          icon: _isLoadingLocation
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.location_on_outlined),
                          label: Text(
                            _isLoadingLocation
                                ? 'Getting Location...'
                                : _currentPosition == null
                                    ? 'Capture GPS Location'
                                    : 'Update Location',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // End Button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isSubmitting ? null : _endTrip,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.stop_circle),
                          label: Text(_isSubmitting ? 'Ending...' : 'End Trip'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
