class TripModel {
  final String id;
  final String customerName;
  final String customerMobile;
  final String pickupLocation;
  final List<String> placesToVisit;
  final String status;
  final int numberOfDays;
  final DateTime? pickupDateTime;
  final String? driverName;
  final String? vehicleNumber;
  final int? startKm;
  final int? endKm;
  final double tollAmount;
  final double permitAmount;
  final double parkingAmount;
  final double fastagAmount;
  final String? tripNotes;
  final double driverBataAssigned;
  final double advanceTotal;
  final TripLocation? currentLocation;

  const TripModel({
    required this.id,
    required this.customerName,
    required this.customerMobile,
    required this.pickupLocation,
    required this.placesToVisit,
    required this.status,
    required this.numberOfDays,
    this.pickupDateTime,
    this.driverName,
    this.vehicleNumber,
    this.startKm,
    this.endKm,
    this.tollAmount = 0,
    this.permitAmount = 0,
    this.parkingAmount = 0,
    this.fastagAmount = 0,
    this.tripNotes,
    this.driverBataAssigned = 0,
    this.advanceTotal = 0,
    this.currentLocation,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    final driverRaw = json['driverId'];
    final vehicleRaw = json['vehicleId'];

    final currentLocationRaw = json['currentLocation'];
    final currentLocation = currentLocationRaw is Map<String, dynamic>
      ? TripLocation.fromJson(currentLocationRaw)
      : null;

    return TripModel(
      id: json['_id'] as String,
      customerName: (json['customerName'] as String?) ?? '-',
      customerMobile: (json['customerMobile'] as String?) ?? '-',
      pickupLocation: json['pickupLocation'] as String,
      placesToVisit: ((json['placesToVisit'] as List<dynamic>?) ?? const [])
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList(),
      status: json['status'] as String,
      numberOfDays: (json['numberOfDays'] as num).toInt(),
      pickupDateTime: json['pickupDateTime'] != null
          ? DateTime.tryParse(json['pickupDateTime'].toString())
          : null,
      driverName: driverRaw is Map<String, dynamic>
          ? (driverRaw['name'] as String?)
          : null,
      vehicleNumber: vehicleRaw is Map<String, dynamic>
          ? (vehicleRaw['number'] as String?)
          : null,
      startKm: (json['startKm'] as num?)?.toInt(),
      endKm: (json['endKm'] as num?)?.toInt(),
      tollAmount: (json['tollAmount'] as num?)?.toDouble() ?? 0,
      permitAmount: (json['permitAmount'] as num?)?.toDouble() ?? 0,
      parkingAmount: (json['parkingAmount'] as num?)?.toDouble() ?? 0,
      fastagAmount: (json['fastagAmount'] as num?)?.toDouble() ?? 0,
      tripNotes: json['tripNotes'] as String?,
      driverBataAssigned: (json['driverBataAssigned'] as num?)?.toDouble() ?? 0,
      advanceTotal: (json['advanceTotal'] as num?)?.toDouble() ?? 0,
      currentLocation: currentLocation,
    );
  }
}

class TripLocation {
  final double latitude;
  final double longitude;
  final DateTime? capturedAt;

  const TripLocation({
    required this.latitude,
    required this.longitude,
    this.capturedAt,
  });

  factory TripLocation.fromJson(Map<String, dynamic> json) {
    return TripLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      capturedAt: json['capturedAt'] != null ? DateTime.tryParse(json['capturedAt'].toString()) : null,
    );
  }
}
