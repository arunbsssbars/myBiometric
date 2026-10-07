
enum CommuteMode {
  bicycleWalking,
  publicTransit,
  evCar,
  carpool,
  gasolineCar,
}

class CommuteTripRecord {
  final String userId;
  final String employeeName;
  final String department;
  final double roundTripDistanceKm;
  final CommuteMode mode;
  final bool isRemoteWorkDay;
  final DateTime date;

  const CommuteTripRecord({
    required this.userId,
    required this.employeeName,
    required this.department,
    required this.roundTripDistanceKm,
    required this.mode,
    required this.isRemoteWorkDay,
    required this.date,
  });

  /// Grams of CO2 per kilometer based on EPA & GHG protocol averages
  double get co2FactorGramsPerKm {
    switch (mode) {
      case CommuteMode.bicycleWalking:
        return 0.0;
      case CommuteMode.publicTransit:
        return 35.0;
      case CommuteMode.evCar:
        return 50.0;
      case CommuteMode.carpool:
        return 85.0;
      case CommuteMode.gasolineCar:
        return 170.0;
    }
  }

  /// Baseline emissions if driven solo in gasoline car
  double get baselineCo2Kg => (roundTripDistanceKm * 170.0) / 1000.0;

  /// Actual emissions produced
  double get actualCo2Kg => isRemoteWorkDay ? 0.0 : (roundTripDistanceKm * co2FactorGramsPerKm) / 1000.0;

  /// CO2 saved in kg compared to standard ICE vehicle commute
  double get co2SavedKg => (baselineCo2Kg - actualCo2Kg).clamp(0.0, 1000.0);
}

class DepartmentEsgSummary {
  final String department;
  final double totalCo2SavedKg;
  final double totalActualCo2Kg;
  final int totalWorkDays;
  final int remoteWorkDays;
  final double greenCommuteRatePercentage;

  const DepartmentEsgSummary({
    required this.department,
    required this.totalCo2SavedKg,
    required this.totalActualCo2Kg,
    required this.totalWorkDays,
    required this.remoteWorkDays,
    required this.greenCommuteRatePercentage,
  });
}

class CommuteCarbonEstimatorService {
  static final CommuteCarbonEstimatorService _instance = CommuteCarbonEstimatorService._internal();
  factory CommuteCarbonEstimatorService() => _instance;
  CommuteCarbonEstimatorService._internal();

  final List<CommuteTripRecord> _records = [];

  List<CommuteTripRecord> get records => List.unmodifiable(_records);

  void recordCommute(CommuteTripRecord record) {
    _records.add(record);
  }

  DepartmentEsgSummary evaluateDepartmentEsg(String department) {
    final deptRecords = _records.where((r) => r.department == department).toList();
    if (deptRecords.isEmpty) {
      return DepartmentEsgSummary(
        department: department,
        totalCo2SavedKg: 0.0,
        totalActualCo2Kg: 0.0,
        totalWorkDays: 0,
        remoteWorkDays: 0,
        greenCommuteRatePercentage: 100.0,
      );
    }

    double totalSaved = 0.0;
    double totalActual = 0.0;
    int remoteDays = 0;
    int greenDays = 0;

    for (final r in deptRecords) {
      totalSaved += r.co2SavedKg;
      totalActual += r.actualCo2Kg;
      if (r.isRemoteWorkDay) {
        remoteDays++;
        greenDays++;
      } else if (r.mode == CommuteMode.bicycleWalking ||
          r.mode == CommuteMode.publicTransit ||
          r.mode == CommuteMode.evCar) {
        greenDays++;
      }
    }

    final greenRate = (greenDays / deptRecords.length) * 100.0;

    return DepartmentEsgSummary(
      department: department,
      totalCo2SavedKg: totalSaved,
      totalActualCo2Kg: totalActual,
      totalWorkDays: deptRecords.length,
      remoteWorkDays: remoteDays,
      greenCommuteRatePercentage: greenRate,
    );
  }

  void clearForTesting() {
    _records.clear();
  }
}
