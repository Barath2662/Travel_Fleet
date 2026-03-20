class BillModel {
  final String id;
  final String vehicleNumber;
  final double totalAmount;
  final double payableAmount;
  final String paymentStatus;

  const BillModel({
    required this.id,
    required this.vehicleNumber,
    required this.totalAmount,
    required this.payableAmount,
    required this.paymentStatus,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['_id'] as String,
      vehicleNumber: json['vehicleNumber'] as String? ?? 'N/A',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      payableAmount: (json['payableAmount'] as num?)?.toDouble() ?? 0,
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
    );
  }
}
