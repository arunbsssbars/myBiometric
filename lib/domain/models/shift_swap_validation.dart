/// Result of validating a shift swap proposal
class ShiftSwapValidationResult {
  final bool isValid;
  final List<String> ruleViolations;
  final bool hasRestPeriodViolation;
  final bool hasOvertimeCapViolation;

  const ShiftSwapValidationResult({
    required this.isValid,
    required this.ruleViolations,
    required this.hasRestPeriodViolation,
    required this.hasOvertimeCapViolation,
  });
}
