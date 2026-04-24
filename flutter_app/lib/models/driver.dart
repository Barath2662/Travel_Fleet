class DriverModel {
  final String id;
  final String? userId;
  final String name;
  final String phone;
  final String? loginEmail;
  final List<DriverLeaveModel> leaves;
  final double salaryPerDay;
  final double salaryPerTrip;
  final double bataRate;
  final double totalWorkingHours;
  final int totalWorkingDays;
  final int totalTripsCompleted;
  final double totalBataEarned;

  const DriverModel({
    required this.id,
    this.userId,
    required this.name,
    required this.phone,
    this.loginEmail,
    this.leaves = const [],
    this.salaryPerDay = 0,
    this.salaryPerTrip = 0,
    this.bataRate = 0,
    required this.totalWorkingHours,
    required this.totalWorkingDays,
    this.totalTripsCompleted = 0,
    this.totalBataEarned = 0,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    final user = json['userId'];

    return DriverModel(
      id: json['_id'] as String,
      userId: user is Map<String, dynamic> ? (user['_id'] as String?) : null,
      name: json['name'] as String,
      phone: json['phone'] as String,
      loginEmail: user is Map<String, dynamic> ? (user['email'] as String?) : null,
      leaves: (json['leaves'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DriverLeaveModel.fromJson)
          .toList(),
        salaryPerDay: (json['salaryPerDay'] as num?)?.toDouble() ?? 0,
        salaryPerTrip: (json['salaryPerTrip'] as num?)?.toDouble() ?? 0,
        bataRate: (json['bataRate'] as num?)?.toDouble() ?? 0,
      totalWorkingHours: (json['totalWorkingHours'] as num?)?.toDouble() ?? 0,
      totalWorkingDays: (json['totalWorkingDays'] as num?)?.toInt() ?? 0,
      totalTripsCompleted: (json['totalTripsCompleted'] as num?)?.toInt() ?? 0,
      totalBataEarned: (json['totalBataEarned'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DriverLeaveModel {
  final String id;
  final DateTime from;
  final DateTime to;
  final String reason;
  final String status;

  const DriverLeaveModel({
    required this.id,
    required this.from,
    required this.to,
    required this.reason,
    required this.status,
  });

  factory DriverLeaveModel.fromJson(Map<String, dynamic> json) {
    return DriverLeaveModel(
      id: json['_id'] as String,
      from: DateTime.parse(json['from'] as String),
      to: DateTime.parse(json['to'] as String),
      reason: (json['reason'] as String?) ?? '-',
      status: (json['status'] as String?) ?? 'pending',
    );
  }
}
