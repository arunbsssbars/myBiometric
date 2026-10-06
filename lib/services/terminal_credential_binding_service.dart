import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/external_biometric_device.dart';
import '../domain/models/terminal_card_credential.dart';
import 'hikvision_isapi_service.dart';

/// Result of a card binding operation.
class CardBindingResult {
  final bool success;
  final String message;
  final TerminalCardCredential? credential;

  const CardBindingResult({
    required this.success,
    required this.message,
    this.credential,
  });
}

/// Service managing RFID/NFC smart cards, virtual badges, and physical badge syncing to hardware terminals.
class TerminalCredentialBindingService {
  final FirebaseFirestore _firestore;
  final HikvisionIsapiService _isapiService;

  TerminalCredentialBindingService({
    FirebaseFirestore? firestore,
    HikvisionIsapiService? isapiService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _isapiService = isapiService ?? HikvisionIsapiService();

  /// Validates and binds a physical or virtual card badge to an enterprise employee.
  Future<CardBindingResult> bindCardToEmployee({
    required String enterpriseId,
    required String userId,
    required String cardNumber,
    TerminalCardType cardType = TerminalCardType.mifare,
    DateTime? expiresAt,
    String? notes,
  }) async {
    final cleanCardNo = cardNumber.trim().toUpperCase();
    if (cleanCardNo.isEmpty) {
      return const CardBindingResult(success: false, message: 'Card number cannot be empty.');
    }

    // Check for duplicate active card in the enterprise
    final duplicateQuery = await _firestore
        .collection('enterprises')
        .doc(enterpriseId)
        .collection('card_credentials')
        .where('cardNumber', isEqualTo: cleanCardNo)
        .where('status', isEqualTo: TerminalCardStatus.active.name)
        .limit(1)
        .get();

    if (duplicateQuery.docs.isNotEmpty) {
      final existingDoc = duplicateQuery.docs.first;
      if (existingDoc.data()['userId'] != userId) {
        return const CardBindingResult(
          success: false,
          message: 'Card number is already assigned to another active employee.',
        );
      }
    }

    final cardDoc = _firestore
        .collection('enterprises')
        .doc(enterpriseId)
        .collection('card_credentials')
        .doc('card_$cleanCardNo');

    final credential = TerminalCardCredential(
      id: cardDoc.id,
      userId: userId,
      enterpriseId: enterpriseId,
      cardNumber: cleanCardNo,
      cardType: cardType,
      status: TerminalCardStatus.active,
      assignedAt: DateTime.now(),
      expiresAt: expiresAt,
      notes: notes,
    );

    final batch = _firestore.batch();
    batch.set(cardDoc, credential.toMap(), SetOptions(merge: true));

    // Update user document with primary badge number
    final userDoc = _firestore.collection('users').doc(userId);
    batch.update(userDoc, {
      'assignedCardNo': cleanCardNo,
      'cardBindingUpdatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    return CardBindingResult(
      success: true,
      message: 'Card $cleanCardNo successfully bound to employee.',
      credential: credential,
    );
  }

  /// Pushes an employee's card badge to a physical Hikvision MinMoe terminal.
  Future<bool> syncCardToDevice({
    required BiometricTerminalDevice device,
    required String employeeNo,
    required TerminalCardCredential credential,
  }) async {
    if (device.protocol != TerminalProtocol.hikvisionIsapi) {
      return true; // Push/generic devices handle card via roster push
    }

    try {
      final payload = credential.toHikvisionCardInfoPayload(employeeNo: employeeNo);
      final response = await _isapiService.sendDigestRequest(
        device: device,
        endpoint: '/ISAPI/AccessControl/CardInfo/Record',
        method: 'POST',
        jsonBody: payload,
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Revokes an assigned badge credential.
  Future<void> revokeCard({
    required String enterpriseId,
    required String cardId,
    String? reason,
  }) async {
    final docRef = _firestore
        .collection('enterprises')
        .doc(enterpriseId)
        .collection('card_credentials')
        .doc(cardId);

    final snap = await docRef.get();
    if (!snap.exists) return;

    final userId = snap.data()?['userId'];

    final batch = _firestore.batch();
    batch.update(docRef, {
      'status': TerminalCardStatus.revoked.name,
      'revocationReason': reason ?? 'Revoked by administrator',
      'revokedAt': FieldValue.serverTimestamp(),
    });

    if (userId != null && userId.toString().isNotEmpty) {
      final userDoc = _firestore.collection('users').doc(userId.toString());
      batch.update(userDoc, {
        'assignedCardNo': null,
      });
    }

    await batch.commit();
  }
}
