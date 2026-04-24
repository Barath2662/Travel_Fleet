class BillModel {
  final String id;
  final String billCode;
  final String customerName;
  final DateTime? billDate;
  final String vehicleNumber;
  final double totalAmount;
  final double payableAmount;
  final double paidAmount;
  final double remainingAmount;
  final String paymentStatus;

  const BillModel({
    required this.id,
    required this.billCode,
    required this.customerName,
    this.billDate,
    required this.vehicleNumber,
    required this.totalAmount,
    required this.payableAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentStatus,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['_id'] as String,
      billCode: json['billCode'] as String? ?? 'BILL-NA',
      customerName: json['customerName'] as String? ?? 'N/A',
      billDate: json['billDate'] != null ? DateTime.tryParse(json['billDate'].toString()) : null,
      vehicleNumber: json['vehicleNumber'] as String? ?? 'N/A',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      payableAmount: (json['payableAmount'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? ((json['payableAmount'] as num?)?.toDouble() ?? 0),
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
    );
  }
}
