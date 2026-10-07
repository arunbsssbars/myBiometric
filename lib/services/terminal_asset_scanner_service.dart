
enum TrackedAssetCategory {
  laptop,
  toolingKey,
  ppeSafetyGear,
  radioWalkieTalkie,
}

class AssetCheckoutTransaction {
  final String transactionId;
  final String assetBarcode;
  final String assetName;
  final TrackedAssetCategory category;
  final String userId;
  final String employeeName;
  final DateTime checkedOutAt;
  final DateTime? returnedAt;
  final bool isReturned;

  const AssetCheckoutTransaction({
    required this.transactionId,
    required this.assetBarcode,
    required this.assetName,
    required this.category,
    required this.userId,
    required this.employeeName,
    required this.checkedOutAt,
    this.returnedAt,
    this.isReturned = false,
  });

  AssetCheckoutTransaction copyWith({
    DateTime? returnedAt,
    bool? isReturned,
  }) {
    return AssetCheckoutTransaction(
      transactionId: transactionId,
      assetBarcode: assetBarcode,
      assetName: assetName,
      category: category,
      userId: userId,
      employeeName: employeeName,
      checkedOutAt: checkedOutAt,
      returnedAt: returnedAt ?? this.returnedAt,
      isReturned: isReturned ?? this.isReturned,
    );
  }

  Map<String, dynamic> toJson() => {
    'transactionId': transactionId,
    'assetBarcode': assetBarcode,
    'assetName': assetName,
    'category': category.name,
    'userId': userId,
    'employeeName': employeeName,
    'checkedOutAt': checkedOutAt.toIso8601String(),
    'returnedAt': returnedAt?.toIso8601String(),
    'isReturned': isReturned,
  };

  factory AssetCheckoutTransaction.fromJson(Map<String, dynamic> json) {
    return AssetCheckoutTransaction(
      transactionId: json['transactionId'] as String? ?? '',
      assetBarcode: json['assetBarcode'] as String? ?? '',
      assetName: json['assetName'] as String? ?? 'Equipment Asset',
      category: TrackedAssetCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => TrackedAssetCategory.toolingKey,
      ),
      userId: json['userId'] as String? ?? '',
      employeeName: json['employeeName'] as String? ?? 'Employee',
      checkedOutAt: DateTime.tryParse(json['checkedOutAt'] as String? ?? '') ?? DateTime.now(),
      returnedAt: json['returnedAt'] != null ? DateTime.tryParse(json['returnedAt'] as String) : null,
      isReturned: json['isReturned'] as bool? ?? false,
    );
  }
}

class TerminalAssetScannerService {
  static final TerminalAssetScannerService _instance = TerminalAssetScannerService._internal();
  factory TerminalAssetScannerService() => _instance;
  TerminalAssetScannerService._internal();

  final List<AssetCheckoutTransaction> _transactions = [];

  List<AssetCheckoutTransaction> get transactions => List.unmodifiable(_transactions);

  AssetCheckoutTransaction checkoutAsset({
    required String assetBarcode,
    required String assetName,
    required TrackedAssetCategory category,
    required String userId,
    required String employeeName,
  }) {
    final tx = AssetCheckoutTransaction(
      transactionId: 'asset_tx_${DateTime.now().millisecondsSinceEpoch}_$userId',
      assetBarcode: assetBarcode,
      assetName: assetName,
      category: category,
      userId: userId,
      employeeName: employeeName,
      checkedOutAt: DateTime.now(),
    );

    _transactions.insert(0, tx);
    return tx;
  }

  bool returnAsset(String assetBarcode, String userId) {
    final index = _transactions.indexWhere(
      (tx) => tx.assetBarcode == assetBarcode && tx.userId == userId && !tx.isReturned,
    );
    if (index == -1) return false;

    _transactions[index] = _transactions[index].copyWith(
      returnedAt: DateTime.now(),
      isReturned: true,
    );
    return true;
  }

  List<AssetCheckoutTransaction> getActiveCustodyAssets(String userId) {
    return _transactions.where((tx) => tx.userId == userId && !tx.isReturned).toList();
  }

  bool hasUnreturnedEquipment(String userId) {
    return _transactions.any((tx) => tx.userId == userId && !tx.isReturned);
  }

  void clearForTesting() {
    _transactions.clear();
  }
}
