class PaymentModel {
  final String id;
  final String billId;
  final String? billCode;
  final String? customerName;
  final String status;
  final double amount;
  final double paymentAmount;
  final DateTime? paidAt;
  final DateTime? paymentDate;
  final String? paymentMethod;
  final String? notes;
  final double remainingBalance;

  const PaymentModel({
    required this.id,
    required this.billId,
    this.billCode,
    this.customerName,
    required this.status,
    required this.amount,
    this.paymentAmount = 0,
    this.paidAt,
    this.paymentDate,
    this.paymentMethod,
    this.notes,
    this.remainingBalance = 0,
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
      paymentAmount: (json['paymentAmount'] as num?)?.toDouble() ?? (json['amount'] as num).toDouble(),
      paidAt: json['paidAt'] != null ? DateTime.tryParse(json['paidAt'].toString()) : null,
      paymentDate: json['paymentDate'] != null ? DateTime.tryParse(json['paymentDate'].toString()) : null,
      paymentMethod: json['paymentMethod'] as String?,
      notes: json['notes'] as String?,
      remainingBalance: (json['remainingBalance'] as num?)?.toDouble() ?? 0,
    );
  }
}
