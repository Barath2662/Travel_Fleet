class BillModel {
  final String id;
  final String billCode;
  final String customerName;
  final DateTime? billDate;
  final String vehicleNumber;
  final String? tripId;
  final String? driverName;
  final String? pickupLocation;
  final String? dropLocation;
  final String? tripStatus;
  final double baseFare;
  final double ratePerKm;
  final double kmCharge;
  final double dayRent;
  final double dayCharge;
  final double hourRent;
  final double hourCharge;
  final double totalKm;
  final double totalHours;
  final double totalDays;
  final double totalAmount;
  final double gstPercent;
  final double gstAmount;
  final double finalAmount;
  final double payableAmount;
  final double advanceReceived;
  final double waitingCharges;
  final double extraCharges;
  final double fastagCharges;
  final double paidAmount;
  final double remainingAmount;
  final double balanceAmount;
  final String paymentStatus;

  const BillModel({
    required this.id,
    required this.billCode,
    required this.customerName,
    this.billDate,
    required this.vehicleNumber,
    this.tripId,
    this.driverName,
    this.pickupLocation,
    this.dropLocation,
    this.tripStatus,
    this.baseFare = 0,
    this.ratePerKm = 0,
    this.kmCharge = 0,
    this.dayRent = 0,
    this.dayCharge = 0,
    this.hourRent = 0,
    this.hourCharge = 0,
    this.totalKm = 0,
    this.totalHours = 0,
    this.totalDays = 0,
    required this.totalAmount,
    this.gstPercent = 0,
    this.gstAmount = 0,
    this.finalAmount = 0,
    required this.payableAmount,
    required this.advanceReceived,
    this.waitingCharges = 0,
    this.extraCharges = 0,
    this.fastagCharges = 0,
    required this.paidAmount,
    required this.remainingAmount,
    this.balanceAmount = 0,
    required this.paymentStatus,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] as String;
    final rawCode = (json['billCode'] as String? ?? '').trim();
    final billYear = json['billYear'] as num?;
    final billSequence = json['billSequence'] as num?;
    final fallbackCode = (billYear != null && billSequence != null)
      ? 'samp-${(billYear.toInt() % 100).toString().padLeft(2, '0')}${billSequence.toInt().toString().padLeft(3, '0')}'
      : 'samp-${id.substring(id.length > 5 ? id.length - 5 : 0).toUpperCase()}';
    final trip = json['tripId'];
    final tripMap = trip is Map<String, dynamic> ? trip : null;
    final driverMap = tripMap?['driverId'] as Map<String, dynamic>?;

    return BillModel(
      id: id,
      billCode: rawCode.isEmpty || rawCode == 'BILL-NA' ? fallbackCode : rawCode,
      customerName: json['customerName'] as String? ?? 'N/A',
      billDate: json['billDate'] != null ? DateTime.tryParse(json['billDate'].toString()) : null,
      vehicleNumber: json['vehicleNumber'] as String? ?? 'N/A',
      tripId: tripMap?['_id'] as String?,
      driverName: driverMap?['name'] as String?,
      pickupLocation: json['pickupLocation'] as String?,
      dropLocation: json['dropLocation'] as String?,
      tripStatus: json['tripStatus'] as String?,
      baseFare: (json['baseFare'] as num?)?.toDouble() ?? 0,
      ratePerKm: (json['ratePerKm'] as num?)?.toDouble() ?? 0,
      kmCharge: (json['kmCharge'] as num?)?.toDouble() ?? 0,
      dayRent: (json['dayRent'] as num?)?.toDouble() ?? 0,
      dayCharge: (json['dayCharge'] as num?)?.toDouble() ?? 0,
      hourRent: (json['hourRent'] as num?)?.toDouble() ?? 0,
      hourCharge: (json['hourCharge'] as num?)?.toDouble() ?? 0,
      totalKm: (json['totalKm'] as num?)?.toDouble() ?? 0,
      totalHours: (json['totalHours'] as num?)?.toDouble() ?? 0,
      totalDays: (json['totalDays'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      gstPercent: (json['gstPercent'] as num?)?.toDouble() ?? 0,
      gstAmount: (json['gstAmount'] as num?)?.toDouble() ?? 0,
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0,
      payableAmount: (json['payableAmount'] as num?)?.toDouble() ?? 0,
      advanceReceived: (json['advanceReceived'] as num?)?.toDouble() ?? 0,
      waitingCharges: (json['waitingCharges'] as num?)?.toDouble() ?? 0,
      extraCharges: (json['extraCharges'] as num?)?.toDouble() ?? 0,
      fastagCharges: (json['fastagCharges'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0,
      balanceAmount: (json['balanceAmount'] as num?)?.toDouble() ?? 0,
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
    );
  }
}
