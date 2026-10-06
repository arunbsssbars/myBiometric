import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/shift_swap_request.dart';
import 'audit_log_service.dart';

/// Enterprise Shift Swapping & Peer Coverage Management Service
class ShiftSwapService {
  final FirebaseFirestore? _customFirestore;

  ShiftSwapService({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference _swapCollection(String enterpriseId) {
    return _firestore
        .collection('enterprises')
        .doc(enterpriseId.trim())
        .collection('shift_swaps');
  }

  /// Creates a new shift swap / trade request
  Future<String> createSwapRequest(ShiftSwapRequest request) async {
    final validationError = validateSwapEligibility(
      requesterDate: request.requesterDate,
      targetDate: request.targetDate,
      requesterId: request.requesterId,
      targetId: request.targetEmployeeId,
    );

    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final docRef = request.id.isNotEmpty
        ? _swapCollection(request.enterpriseId).doc(request.id)
        : _swapCollection(request.enterpriseId).doc();

    final populated = request.copyWith(id: docRef.id);
    await docRef.set(populated.toMap());

    // Log enterprise audit entry
    try {
      await AuditLogService().logAction(
        enterpriseId: request.enterpriseId,
        action: 'SHIFT_SWAP_REQUESTED',
        details: '${request.requesterName} requested shift swap with ${request.targetEmployeeName}',
        targetEmployeeId: request.targetEmployeeId,
        targetEmployeeName: request.targetEmployeeName,
        category: AuditLogService.categoryApprovals,
      );
    } catch (_) {}

    return docRef.id;
  }

  /// Peer employee responds to the swap request (Accept / Decline)
  Future<void> peerRespond({
    required String enterpriseId,
    required String swapId,
    required bool accept,
    String? peerNotes,
  }) async {
    final docRef = _swapCollection(enterpriseId).doc(swapId);
    final now = DateTime.now();

    await docRef.update({
      'status': accept ? ShiftSwapStatus.pendingManager.name : ShiftSwapStatus.rejectedByPeer.name,
      'peerRespondedAt': now.toIso8601String(),
      if (peerNotes != null && peerNotes.isNotEmpty) 'peerNotes': peerNotes,
    });

    try {
      await AuditLogService().logAction(
        enterpriseId: enterpriseId,
        action: accept ? 'SHIFT_SWAP_PEER_ACCEPTED' : 'SHIFT_SWAP_PEER_DECLINED',
        details: 'Peer response: ${accept ? "Accepted, escalated to manager" : "Declined"} (Swap: $swapId)',
        category: AuditLogService.categoryApprovals,
      );
    } catch (_) {}
  }

  /// Enterprise Manager or Admin reviews and approves/rejects the swap
  Future<void> managerRespond({
    required String enterpriseId,
    required String swapId,
    required String managerUid,
    required bool approve,
    String? managerNotes,
  }) async {
    final docRef = _swapCollection(enterpriseId).doc(swapId);
    final now = DateTime.now();

    await docRef.update({
      'status': approve ? ShiftSwapStatus.approved.name : ShiftSwapStatus.rejectedByManager.name,
      'managerRespondedAt': now.toIso8601String(),
      'managerUid': managerUid,
      if (managerNotes != null && managerNotes.isNotEmpty) 'managerNotes': managerNotes,
    });

    try {
      await AuditLogService().logAction(
        enterpriseId: enterpriseId,
        action: approve ? 'SHIFT_SWAP_APPROVED' : 'SHIFT_SWAP_REJECTED',
        details: 'Manager verdict: ${approve ? "Approved shift swap" : "Rejected shift swap"} (Swap: $swapId)',
        category: AuditLogService.categoryApprovals,
      );
    } catch (_) {}
  }

  /// Requester cancels their pending swap request
  Future<void> cancelSwapRequest({
    required String enterpriseId,
    required String swapId,
    required String userId,
  }) async {
    final docRef = _swapCollection(enterpriseId).doc(swapId);
    await docRef.update({
      'status': ShiftSwapStatus.cancelled.name,
      'managerNotes': 'Cancelled by requester',
    });
  }

  /// Streams all shift swaps for an enterprise
  Stream<List<ShiftSwapRequest>> streamEnterpriseSwaps(String enterpriseId) {
    return _swapCollection(enterpriseId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ShiftSwapRequest.fromMap(
          doc.data() as Map<String, dynamic>,
          id: doc.id,
        );
      }).toList();
    });
  }

  /// Streams user-specific shift swaps (incoming invites + outgoing requests)
  Stream<List<ShiftSwapRequest>> streamUserSwaps(String enterpriseId, String userId) {
    return _swapCollection(enterpriseId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ShiftSwapRequest.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
          .where((s) => s.requesterId == userId || s.targetEmployeeId == userId)
          .toList();
    });
  }

  /// Validates shift swap scheduling eligibility
  static String? validateSwapEligibility({
    required DateTime requesterDate,
    required DateTime targetDate,
    required String requesterId,
    required String targetId,
    DateTime? now,
  }) {
    if (requesterId.trim().isEmpty || targetId.trim().isEmpty) {
      return 'Both requesting and target employee must be specified.';
    }

    if (requesterId.trim() == targetId.trim()) {
      return 'Cannot initiate a shift swap with yourself.';
    }

    final currentTime = now ?? DateTime.now();
    final todayStart = DateTime(currentTime.year, currentTime.month, currentTime.day);
    final reqDayStart = DateTime(requesterDate.year, requesterDate.month, requesterDate.day);
    final targetDayStart = DateTime(targetDate.year, targetDate.month, targetDate.day);

    if (reqDayStart.isBefore(todayStart)) {
      return 'Requested shift date cannot be in the past.';
    }

    if (targetDayStart.isBefore(todayStart)) {
      return 'Target shift date cannot be in the past.';
    }

    return null;
  }
}
