class VehicleModel {
  final String id;
  final String number;
  final String category;
  final int seats;
  final int currentKm;
  final int nextServiceKm;
  final DateTime? fcDate;
  final DateTime? insuranceDate;
  final DateTime? pucDate;
  final DateTime? permitDate;

  const VehicleModel({
    required this.id,
    required this.number,
    required this.category,
    required this.seats,
    required this.currentKm,
    required this.nextServiceKm,
    this.fcDate,
    this.insuranceDate,
    this.pucDate,
    this.permitDate,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['_id'] as String,
      number: json['number'] as String,
      category: (json['category'] as String?) ?? 'sedan',
      seats: (json['seats'] as num?)?.toInt() ?? 4,
      currentKm: (json['currentKm'] as num?)?.toInt() ?? 0,
      nextServiceKm: (json['nextServiceKm'] as num).toInt(),
      fcDate: json['fcDate'] == null ? null : DateTime.tryParse(json['fcDate'].toString()),
      insuranceDate: json['insuranceDate'] == null ? null : DateTime.tryParse(json['insuranceDate'].toString()),
      pucDate: json['pucDate'] == null ? null : DateTime.tryParse(json['pucDate'].toString()),
      permitDate: json['permitDate'] == null ? null : DateTime.tryParse(json['permitDate'].toString()),
    );
  }
}
