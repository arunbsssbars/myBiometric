import 'package:flutter/material.dart';

/// Type of shift differential
enum DifferentialType {
  nightShift,
  weekend,
  holiday,
  hazardOrRemote,
}

/// Represents a rule for calculating pay premiums/differentials based on shift timing or day
class ShiftDifferentialRule {
  final String id;
  final String name;
  final DifferentialType type;
  final TimeOfDay? nightWindowStart; // e.g. 22:00
  final TimeOfDay? nightWindowEnd; // e.g. 06:00
  final List<int> applicableDaysOfWeek; // 1 (Mon) - 7 (Sun)
  final double rateMultiplier; // e.g. 1.25 for 125%
  final double flatBonusPerHour; // e.g. $2.50/hr

  const ShiftDifferentialRule({
    required this.id,
    required this.name,
    required this.type,
    this.nightWindowStart,
    this.nightWindowEnd,
    this.applicableDaysOfWeek = const [],
    this.rateMultiplier = 1.0,
    this.flatBonusPerHour = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'nightStartHour': nightWindowStart?.hour,
      'nightStartMinute': nightWindowStart?.minute,
      'nightEndHour': nightWindowEnd?.hour,
      'nightEndMinute': nightWindowEnd?.minute,
      'applicableDaysOfWeek': applicableDaysOfWeek,
      'rateMultiplier': rateMultiplier,
      'flatBonusPerHour': flatBonusPerHour,
    };
  }

  factory ShiftDifferentialRule.fromMap(Map<String, dynamic> map) {
    return ShiftDifferentialRule(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: DifferentialType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => DifferentialType.nightShift,
      ),
      nightWindowStart: map['nightStartHour'] != null
          ? TimeOfDay(hour: map['nightStartHour'], minute: map['nightStartMinute'] ?? 0)
          : null,
      nightWindowEnd: map['nightEndHour'] != null
          ? TimeOfDay(hour: map['nightEndHour'], minute: map['nightEndMinute'] ?? 0)
          : null,
      applicableDaysOfWeek: (map['applicableDaysOfWeek'] as List<dynamic>?)?.map((e) => e as int).toList() ?? const [],
      rateMultiplier: (map['rateMultiplier'] as num?)?.toDouble() ?? 1.0,
      flatBonusPerHour: (map['flatBonusPerHour'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Evaluation result of a shift differential calculation
class ShiftDifferentialResult {
  final double standardHours;
  final double nightHours;
  final double weekendHours;
  final double holidayHours;
  final double totalPremiumAmount;

  const ShiftDifferentialResult({
    required this.standardHours,
    required this.nightHours,
    required this.weekendHours,
    required this.holidayHours,
    required this.totalPremiumAmount,
  });
}
