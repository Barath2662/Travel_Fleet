class PaymentModel {
  final String id;
  final String billId;
  final String? billCode;
  final String? customerName;
  final String status;
  final double amount;
  final DateTime? paidAt;
  final String? notes;

  const PaymentModel({
    required this.id,
    required this.billId,
    this.billCode,
    this.customerName,
    required this.status,
    required this.amount,
    this.paidAt,
    this.notes,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    final bill = json['billId'];
    final billMap = bill is Map<String, dynamic> ? bill : null;

    return PaymentModel(
      id: json['_id'] as String,
      billId: billMap?['_id'] as String? ?? json['billId'] as String? ?? '',
      billCode: billMap?['billCode'] as String?,
      customerName: billMap?['customerName'] as String?,
      status: json['status'] as String? ?? 'pending',
      amount: (json['amount'] as num).toDouble(),
      paidAt: json['paidAt'] != null ? DateTime.tryParse(json['paidAt'].toString()) : null,
      notes: json['notes'] as String?,
    );
  }
}
