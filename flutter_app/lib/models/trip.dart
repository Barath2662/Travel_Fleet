class TripModel {
  final String id;
  final String customerName;
  final String customerMobile;
  final String pickupLocation;
  final List<String> placesToVisit;
  final String status;
  final int numberOfDays;
  final String? driverName;
  final String? vehicleNumber;
  final double driverBataAssigned;

  const TripModel({
    required this.id,
    required this.customerName,
    required this.customerMobile,
    required this.pickupLocation,
    required this.placesToVisit,
    required this.status,
    required this.numberOfDays,
    this.driverName,
    this.vehicleNumber,
    this.driverBataAssigned = 0,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    final driverRaw = json['driverId'];
    final vehicleRaw = json['vehicleId'];

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
      driverName: driverRaw is Map<String, dynamic>
          ? (driverRaw['name'] as String?)
          : null,
      vehicleNumber: vehicleRaw is Map<String, dynamic>
          ? (vehicleRaw['number'] as String?)
          : null,
      driverBataAssigned: (json['driverBataAssigned'] as num?)?.toDouble() ?? 0,
    );
  }
}
