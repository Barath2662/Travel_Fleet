class BillModel {
  final String id;
  final DateTime? billDate;
  final String vehicleNumber;
  final double totalAmount;
  final double payableAmount;
  final String paymentStatus;

  const BillModel({
    required this.id,
    this.billDate,
    required this.vehicleNumber,
    required this.totalAmount,
    required this.payableAmount,
    required this.paymentStatus,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['_id'] as String,
      billDate: json['billDate'] != null ? DateTime.tryParse(json['billDate'].toString()) : null,
      vehicleNumber: json['vehicleNumber'] as String? ?? 'N/A',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      payableAmount: (json['payableAmount'] as num?)?.toDouble() ?? 0,
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
    );
  }
}
