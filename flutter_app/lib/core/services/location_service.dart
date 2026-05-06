import 'dart:math';

import 'package:location/location.dart';

import '../helpers/platform_helper.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  /// Check and request location permissions
  Future<bool> requestLocationPermissions() async {
    try {
      if (!isMobilePlatform) return false;

      final location = Location();
      final serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        final enabled = await location.requestService();
        if (!enabled) return false;
      }

      var permission = await location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await location.requestPermission();
      }

      return permission == PermissionStatus.granted ||
          permission == PermissionStatus.grantedLimited;
    } catch (e) {
      return false;
    }
  }

  /// Get current position
  Future<LocationData?> getCurrentPosition() async {
    try {
      if (!isMobilePlatform) return null;
      final hasPermission = await requestLocationPermissions();
      if (!hasPermission) return null;

      final location = Location();
      return await location.getLocation();
    } catch (e) {
      return null;
    }
  }

  /// Get location updates stream
  Stream<LocationData> getLocationStream() {
    final location = Location();
    return location.onLocationChanged;
  }

  /// Get address from coordinates (latitude, longitude format)
  Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      // Return formatted coordinate string
      // For full address lookup, you'd need the geocoding package
      return '$latitude, $longitude';
    } catch (e) {
      return 'Unable to get address';
    }
  }

  /// Calculate distance between two coordinates in kilometers
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * (pi / 180.0);

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    if (!isMobilePlatform) return false;
    final location = Location();
    return await location.serviceEnabled();
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    if (!isMobilePlatform) return false;
    final location = Location();
    return await location.requestService();
  }
}
