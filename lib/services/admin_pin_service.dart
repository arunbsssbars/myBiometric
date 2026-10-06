import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages admin terminal PIN with local persistence and Firestore cloud synchronization.
/// Falls back to Firestore `kioskPin` field, then '1234' if nothing is set.
class AdminPinService {
  AdminPinService._();
  static final AdminPinService instance = AdminPinService._();
  factory AdminPinService() => instance;

  static const String _keyPrefix = 'admin_pin_';
  static const String _salt = 'myBiometric_salt_v1';

  String _prefKey(String enterpriseId) => '$_keyPrefix$enterpriseId';

  /// Simple repeatable hash: base64(salt + pin).
  String _hash(String pin) => base64Encode(utf8.encode('$_salt:$pin'));

  /// Returns true if a custom PIN has been stored locally.
  Future<bool> hasPin(String enterpriseId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_prefKey(enterpriseId));
  }

  /// Persist a new PIN locally (hashed).
  Future<void> setPin(String enterpriseId, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey(enterpriseId), _hash(pin));
  }

  /// Clears the locally stored PIN (falls back to Firestore / default).
  Future<void> clearPin(String enterpriseId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey(enterpriseId));
  }

  /// Returns true if [pin] matches the stored PIN or Firestore `kioskPin`.
  /// Synchronizes local cache automatically when verified against cloud.
  Future<bool> verifyPin(String enterpriseId, String pin) async {
    final cleanPin = pin.trim();
    if (cleanPin.isEmpty) return false;

    // 1. Try local cache first
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_prefKey(enterpriseId));
      if (stored != null && stored == _hash(cleanPin)) {
        return true;
      }
    } catch (e) {
      debugPrint('AdminPinService local check error: $e');
    }

    // 2. Query Firestore directly for the enterprise's current kioskPin
    try {
      final doc = await FirebaseFirestore.instance
          .collection('enterprises')
          .doc(enterpriseId.trim())
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final cloudPin = (data['kioskPin'] as String?)?.trim() ??
            (data['adminPin'] as String?)?.trim();

        if (cloudPin != null && cloudPin.isNotEmpty) {
          if (cloudPin == cleanPin) {
            // Update local cache so offline verification succeeds subsequently
            await setPin(enterpriseId, cleanPin);
            return true;
          }
        } else {
          // If no custom pin in cloud, default is 1234
          if (cleanPin == '1234') {
            return true;
          }
        }
      } else {
        // Fallback default
        if (cleanPin == '1234') return true;
      }
    } catch (e) {
      debugPrint('AdminPinService Firestore query fallback: $e');
      // If offline and no local pin was set, default 1234 is allowed
      if (cleanPin == '1234') return true;
    }

    return false;
  }

  /// Returns the effective PIN to use for verification.
  Future<String> getEffectivePin(
    String enterpriseId,
    Map<String, dynamic>? firestoreEntData,
  ) async {
    final hasLocal = await hasPin(enterpriseId);
    if (hasLocal) return '__local__';
    final firestorePin = (firestoreEntData?['kioskPin'] as String?) ??
        (firestoreEntData?['adminPin'] as String?);
    return firestorePin ?? '1234';
  }

  /// Unified PIN check: works for both local and Firestore-stored PINs.
  Future<bool> checkPin(
    String enterpriseId,
    String enteredPin,
    Map<String, dynamic>? firestoreEntData,
  ) async {
    final clean = enteredPin.trim();
    // 1. Check in passed firestoreEntData if provided
    if (firestoreEntData != null) {
      final cloudPin = (firestoreEntData['kioskPin'] as String?)?.trim() ??
          (firestoreEntData['adminPin'] as String?)?.trim() ??
          '1234';
      if (clean == cloudPin) {
        // Cache to local
        await setPin(enterpriseId, clean);
        return true;
      }
    }
    // 2. Full verification with local and Firestore lookup
    return verifyPin(enterpriseId, clean);
  }
}
