import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Lightweight network connectivity verification service.
/// Uses standard DNS lookup with a fast timeout to prevent database operations
/// from hanging indefinitely when offline.
class NetworkConnectionService {
  NetworkConnectionService._();
  static final NetworkConnectionService instance = NetworkConnectionService._();

  /// Checks if an active internet connection can reach public servers.
  static Future<bool> isConnected() async {
    if (kIsWeb) return true; // Web browsers execute HTTP/WebSocket directly
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Verifies connectivity and displays a floating red warning SnackBar if disconnected.
  /// Returns `true` if connected, `false` otherwise.
  static Future<bool> checkConnectionAndNotify(
    BuildContext context, {
    String message = 'No internet connection. Please verify network access to perform this operation.',
  }) async {
    final hasNet = await isConnected();
    if (!hasNet && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
    return hasNet;
  }
}
