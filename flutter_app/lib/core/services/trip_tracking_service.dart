import 'dart:async';

import 'package:location/location.dart';

import '../config/app_config.dart';
import '../helpers/platform_helper.dart';
import 'api_service.dart';

class TripTrackingService {
  TripTrackingService._internal();

  static final TripTrackingService _instance = TripTrackingService._internal();

  factory TripTrackingService() => _instance;

  final Location _location = Location();
  final StreamController<LocationData> _controller = StreamController<LocationData>.broadcast();
  StreamSubscription<LocationData>? _subscription;
  DateTime? _lastSentAt;
  String? _activeTripId;
  bool _isTracking = false;

  Stream<LocationData> get locationStream => _controller.stream;

  bool get isTracking => _isTracking;

  Future<void> startTracking({
    required String tripId,
    required ApiService api,
    required String token,
  }) async {
    if (!isMobilePlatform) {
      return;
    }

    if (!AppConfig.continuousLocationTracking) {
      return;
    }

    if (_isTracking && _activeTripId == tripId) {
      return;
    }

    await stopTracking();

    final serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      final enabled = await _location.requestService();
      if (!enabled) {
        return;
      }
    }

    var permission = await _location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await _location.requestPermission();
      if (permission != PermissionStatus.granted && permission != PermissionStatus.grantedLimited) {
        return;
      }
    }

    await _location.enableBackgroundMode(enable: true);
    await _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: AppConfig.locationUpdateInterval * 1000,
      distanceFilter: AppConfig.locationAccuracyThreshold.toDouble(),
    );

    _activeTripId = tripId;
    _isTracking = true;
    _lastSentAt = null;

    _subscription = _location.onLocationChanged.listen((locationData) async {
      _controller.add(locationData);

      final lat = locationData.latitude;
      final lon = locationData.longitude;
      final accuracy = locationData.accuracy ?? 0;

      if (lat == null || lon == null) return;
      if (accuracy > AppConfig.locationAccuracyThreshold * 5) return;

      final now = DateTime.now();
      if (_lastSentAt != null && now.difference(_lastSentAt!).inSeconds < AppConfig.locationUpdateInterval) {
        return;
      }

      try {
        await api.post(
          '/trip/$tripId/route-point',
          {'latitude': lat, 'longitude': lon},
          token: token,
        );
        _lastSentAt = now;
      } catch (_) {
        // Best-effort tracking: ignore transient errors.
      }
    });
  }

  Future<void> stopTracking() async {
    _activeTripId = null;
    _isTracking = false;
    _lastSentAt = null;
    await _subscription?.cancel();
    _subscription = null;
  }
}
