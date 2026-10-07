
enum BidStatus {
  submitted,
  accepted,
  rejected,
  withdrawn,
}

class OpenShiftListing {
  final String shiftId;
  final String enterpriseId;
  final String department;
  final String roleRequired;
  final DateTime startTime;
  final DateTime endTime;
  final double shiftHours;
  final double hourlyPremiumMultiplier; // e.g. 1.5x
  final bool isOpen;
  final String? awardedUserId;

  const OpenShiftListing({
    required this.shiftId,
    required this.enterpriseId,
    required this.department,
    required this.roleRequired,
    required this.startTime,
    required this.endTime,
    required this.shiftHours,
    this.hourlyPremiumMultiplier = 1.0,
    this.isOpen = true,
    this.awardedUserId,
  });

  OpenShiftListing copyWith({
    bool? isOpen,
    String? awardedUserId,
  }) {
    return OpenShiftListing(
      shiftId: shiftId,
      enterpriseId: enterpriseId,
      department: department,
      roleRequired: roleRequired,
      startTime: startTime,
      endTime: endTime,
      shiftHours: shiftHours,
      hourlyPremiumMultiplier: hourlyPremiumMultiplier,
      isOpen: isOpen ?? this.isOpen,
      awardedUserId: awardedUserId ?? this.awardedUserId,
    );
  }

  Map<String, dynamic> toJson() => {
    'shiftId': shiftId,
    'enterpriseId': enterpriseId,
    'department': department,
    'roleRequired': roleRequired,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'shiftHours': shiftHours,
    'hourlyPremiumMultiplier': hourlyPremiumMultiplier,
    'isOpen': isOpen,
    'awardedUserId': awardedUserId,
  };

  factory OpenShiftListing.fromJson(Map<String, dynamic> json) {
    return OpenShiftListing(
      shiftId: json['shiftId'] as String? ?? '',
      enterpriseId: json['enterpriseId'] as String? ?? '',
      department: json['department'] as String? ?? 'General',
      roleRequired: json['roleRequired'] as String? ?? 'Staff',
      startTime: DateTime.tryParse(json['startTime'] as String? ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['endTime'] as String? ?? '') ?? DateTime.now(),
      shiftHours: (json['shiftHours'] as num?)?.toDouble() ?? 8.0,
      hourlyPremiumMultiplier: (json['hourlyPremiumMultiplier'] as num?)?.toDouble() ?? 1.0,
      isOpen: json['isOpen'] as bool? ?? true,
      awardedUserId: json['awardedUserId'] as String?,
    );
  }
}

class ShiftBid {
  final String bidId;
  final String shiftId;
  final String userId;
  final String employeeName;
  final int seniorityYears;
  final DateTime submittedAt;
  final BidStatus status;

  const ShiftBid({
    required this.bidId,
    required this.shiftId,
    required this.userId,
    required this.employeeName,
    required this.seniorityYears,
    required this.submittedAt,
    this.status = BidStatus.submitted,
  });

  ShiftBid copyWith({BidStatus? status}) {
    return ShiftBid(
      bidId: bidId,
      shiftId: shiftId,
      userId: userId,
      employeeName: employeeName,
      seniorityYears: seniorityYears,
      submittedAt: submittedAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
    'bidId': bidId,
    'shiftId': shiftId,
    'userId': userId,
    'employeeName': employeeName,
    'seniorityYears': seniorityYears,
    'submittedAt': submittedAt.toIso8601String(),
    'status': status.name,
  };
}

class ShiftBiddingMarketplaceService {
  static final ShiftBiddingMarketplaceService _instance = ShiftBiddingMarketplaceService._internal();
  factory ShiftBiddingMarketplaceService() => _instance;
  ShiftBiddingMarketplaceService._internal();

  final List<OpenShiftListing> _listings = [];
  final List<ShiftBid> _bids = [];

  List<OpenShiftListing> get listings => List.unmodifiable(_listings);
  List<ShiftBid> get bids => List.unmodifiable(_bids);

  void publishShift(OpenShiftListing listing) {
    _listings.add(listing);
  }

  ShiftBid submitBid({
    required String shiftId,
    required String userId,
    required String employeeName,
    required int seniorityYears,
  }) {
    final shiftIndex = _listings.indexWhere((s) => s.shiftId == shiftId);
    if (shiftIndex == -1 || !_listings[shiftIndex].isOpen) {
      throw StateError('Shift $shiftId is not available for bidding');
    }

    final bid = ShiftBid(
      bidId: 'bid_${DateTime.now().millisecondsSinceEpoch}_$userId',
      shiftId: shiftId,
      userId: userId,
      employeeName: employeeName,
      seniorityYears: seniorityYears,
      submittedAt: DateTime.now(),
    );

    _bids.add(bid);
    return bid;
  }

  /// Evaluates all bids for a shift and awards to candidate with highest seniority
  String? awardShiftBySeniority(String shiftId) {
    final shiftBids = _bids.where((b) => b.shiftId == shiftId && b.status == BidStatus.submitted).toList();
    if (shiftBids.isEmpty) return null;

    // Sort by seniority descending, then submission time ascending
    shiftBids.sort((a, b) {
      final comp = b.seniorityYears.compareTo(a.seniorityYears);
      if (comp != 0) return comp;
      return a.submittedAt.compareTo(b.submittedAt);
    });

    final winner = shiftBids.first;

    // Update bids
    for (int i = 0; i < _bids.length; i++) {
      if (_bids[i].shiftId == shiftId) {
        if (_bids[i].bidId == winner.bidId) {
          _bids[i] = _bids[i].copyWith(status: BidStatus.accepted);
        } else {
          _bids[i] = _bids[i].copyWith(status: BidStatus.rejected);
        }
      }
    }

    // Close shift listing
    final sIdx = _listings.indexWhere((s) => s.shiftId == shiftId);
    if (sIdx != -1) {
      _listings[sIdx] = _listings[sIdx].copyWith(
        isOpen: false,
        awardedUserId: winner.userId,
      );
    }

    return winner.userId;
  }

  void clearForTesting() {
    _listings.clear();
    _bids.clear();
  }
}
