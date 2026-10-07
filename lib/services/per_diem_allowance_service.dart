
enum MealVoucherTier {
  standardLunch,
  lateNightDinner,
  extendedShiftMeal,
}

class PerDiemPolicy {
  final String id;
  final String enterpriseId;
  final String currencyCode; // e.g. "USD", "INR", "EUR"
  final double minHoursForMealVoucher; // e.g. 6.0
  final double mealVoucherAmount; // e.g. 15.0
  final double minHoursForFullPerDiem; // e.g. 10.0
  final double fullPerDiemAmount; // e.g. 45.0
  final bool nightShiftSurchargeEnabled;
  final double nightShiftSurchargeAmount; // e.g. 10.0

  const PerDiemPolicy({
    required this.id,
    required this.enterpriseId,
    this.currencyCode = 'USD',
    this.minHoursForMealVoucher = 6.0,
    this.mealVoucherAmount = 15.0,
    this.minHoursForFullPerDiem = 10.0,
    this.fullPerDiemAmount = 45.0,
    this.nightShiftSurchargeEnabled = true,
    this.nightShiftSurchargeAmount = 10.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'enterpriseId': enterpriseId,
    'currencyCode': currencyCode,
    'minHoursForMealVoucher': minHoursForMealVoucher,
    'mealVoucherAmount': mealVoucherAmount,
    'minHoursForFullPerDiem': minHoursForFullPerDiem,
    'fullPerDiemAmount': fullPerDiemAmount,
    'nightShiftSurchargeEnabled': nightShiftSurchargeEnabled,
    'nightShiftSurchargeAmount': nightShiftSurchargeAmount,
  };

  factory PerDiemPolicy.fromJson(Map<String, dynamic> json) {
    return PerDiemPolicy(
      id: json['id'] as String? ?? '',
      enterpriseId: json['enterpriseId'] as String? ?? '',
      currencyCode: json['currencyCode'] as String? ?? 'USD',
      minHoursForMealVoucher: (json['minHoursForMealVoucher'] as num?)?.toDouble() ?? 6.0,
      mealVoucherAmount: (json['mealVoucherAmount'] as num?)?.toDouble() ?? 15.0,
      minHoursForFullPerDiem: (json['minHoursForFullPerDiem'] as num?)?.toDouble() ?? 10.0,
      fullPerDiemAmount: (json['fullPerDiemAmount'] as num?)?.toDouble() ?? 45.0,
      nightShiftSurchargeEnabled: json['nightShiftSurchargeEnabled'] as bool? ?? true,
      nightShiftSurchargeAmount: (json['nightShiftSurchargeAmount'] as num?)?.toDouble() ?? 10.0,
    );
  }
}

class PerDiemDisbursementRecord {
  final String id;
  final String enterpriseId;
  final String userId;
  final String employeeName;
  final DateTime shiftDate;
  final double workedHours;
  final bool isNightShift;
  final double totalAllowance;
  final String currencyCode;
  final List<String> qualificationReasons;
  final DateTime generatedAt;

  const PerDiemDisbursementRecord({
    required this.id,
    required this.enterpriseId,
    required this.userId,
    required this.employeeName,
    required this.shiftDate,
    required this.workedHours,
    required this.isNightShift,
    required this.totalAllowance,
    required this.currencyCode,
    required this.qualificationReasons,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'enterpriseId': enterpriseId,
    'userId': userId,
    'employeeName': employeeName,
    'shiftDate': shiftDate.toIso8601String(),
    'workedHours': workedHours,
    'isNightShift': isNightShift,
    'totalAllowance': totalAllowance,
    'currencyCode': currencyCode,
    'qualificationReasons': qualificationReasons,
    'generatedAt': generatedAt.toIso8601String(),
  };

  factory PerDiemDisbursementRecord.fromJson(Map<String, dynamic> json) {
    return PerDiemDisbursementRecord(
      id: json['id'] as String? ?? '',
      enterpriseId: json['enterpriseId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      employeeName: json['employeeName'] as String? ?? 'Employee',
      shiftDate: DateTime.tryParse(json['shiftDate'] as String? ?? '') ?? DateTime.now(),
      workedHours: (json['workedHours'] as num?)?.toDouble() ?? 0.0,
      isNightShift: json['isNightShift'] as bool? ?? false,
      totalAllowance: (json['totalAllowance'] as num?)?.toDouble() ?? 0.0,
      currencyCode: json['currencyCode'] as String? ?? 'USD',
      qualificationReasons: (json['qualificationReasons'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      generatedAt: DateTime.tryParse(json['generatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class PerDiemAllowanceService {
  static final PerDiemAllowanceService _instance = PerDiemAllowanceService._internal();
  factory PerDiemAllowanceService() => _instance;
  PerDiemAllowanceService._internal();

  final List<PerDiemDisbursementRecord> _records = [];

  List<PerDiemDisbursementRecord> get records => List.unmodifiable(_records);

  PerDiemDisbursementRecord evaluateShiftAllowance({
    required PerDiemPolicy policy,
    required String userId,
    required String employeeName,
    required DateTime shiftDate,
    required double workedHours,
    required bool isNightShift,
  }) {
    double allowance = 0.0;
    final reasons = <String>[];

    if (workedHours >= policy.minHoursForFullPerDiem) {
      allowance += policy.fullPerDiemAmount;
      reasons.add('Full Day Per Diem (${workedHours.toStringAsFixed(1)} hrs >= ${policy.minHoursForFullPerDiem} hrs)');
    } else if (workedHours >= policy.minHoursForMealVoucher) {
      allowance += policy.mealVoucherAmount;
      reasons.add('Meal Voucher (${workedHours.toStringAsFixed(1)} hrs >= ${policy.minHoursForMealVoucher} hrs)');
    }

    if (isNightShift && policy.nightShiftSurchargeEnabled) {
      allowance += policy.nightShiftSurchargeAmount;
      reasons.add('Night Shift Surcharge');
    }

    final record = PerDiemDisbursementRecord(
      id: 'perdiem_${DateTime.now().millisecondsSinceEpoch}_$userId',
      enterpriseId: policy.enterpriseId,
      userId: userId,
      employeeName: employeeName,
      shiftDate: shiftDate,
      workedHours: workedHours,
      isNightShift: isNightShift,
      totalAllowance: allowance,
      currencyCode: policy.currencyCode,
      qualificationReasons: reasons,
      generatedAt: DateTime.now(),
    );

    _records.insert(0, record);
    return record;
  }

  double calculateTotalDisbursedForEmployee(String userId, String currencyCode) {
    return _records
        .where((r) => r.userId == userId && r.currencyCode == currencyCode)
        .fold(0.0, (acc, r) => acc + r.totalAllowance);
  }

  void clearForTesting() {
    _records.clear();
  }
}
