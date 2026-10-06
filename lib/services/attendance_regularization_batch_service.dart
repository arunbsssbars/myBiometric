import '../domain/models/attendance_regularization_request.dart';

/// Result summary of batch processing regularization requests
class RegularizationBatchResult {
  final int totalProcessed;
  final int approvedCount;
  final int rejectedCount;
  final List<String> modifiedRequestIds;

  const RegularizationBatchResult({
    required this.totalProcessed,
    required this.approvedCount,
    required this.rejectedCount,
    required this.modifiedRequestIds,
  });
}

/// Service for bulk operations on attendance regularization requests
class AttendanceRegularizationBatchService {
  /// Bulk processes multiple pending regularization requests
  static RegularizationBatchResult processBatch({
    required List<AttendanceRegularizationRequest> requests,
    required RegularizationStatus targetStatus, // approved or rejected
    required String reviewerUid,
    required String reviewerName,
    String resolutionNote = 'Bulk resolved by administrator',
    DateTime? actionTime,
  }) {
    int approved = 0;
    int rejected = 0;
    final List<String> modifiedIds = [];

    for (final req in requests) {
      if (req.status == RegularizationStatus.pending) {
        modifiedIds.add(req.id);
        if (targetStatus == RegularizationStatus.approved) {
          approved++;
        } else if (targetStatus == RegularizationStatus.rejected) {
          rejected++;
        }
      }
    }

    return RegularizationBatchResult(
      totalProcessed: modifiedIds.length,
      approvedCount: approved,
      rejectedCount: rejected,
      modifiedRequestIds: modifiedIds,
    );
  }
}
