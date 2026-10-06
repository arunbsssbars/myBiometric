import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class GeofenceStatus {
  final bool isWithinGeofence;
  final double distanceMeters;
  final double allowedRadiusMeters;
  final Position currentPosition;
  final bool isMocked;

  GeofenceStatus({
    required this.isWithinGeofence,
    required this.distanceMeters,
    required this.allowedRadiusMeters,
    required this.currentPosition,
    this.isMocked = false,
  });
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Checks if location services are enabled and requests permission if needed
  Future<bool> checkAndRequestPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("Location services are disabled.");
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint("Location permissions denied.");
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint("Location permissions permanently denied.");
        return false;
      }

      return true;
    } catch (e) {
      debugPrint("Error checking location permissions: $e");
      return false;
    }
  }

  /// Retrieves the current device position with high accuracy
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
    } catch (e) {
      debugPrint("Error fetching current position: $e");
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  /// Calculates geodesic distance between two coordinate pairs in meters
  double calculateDistanceMeters({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Evaluates whether current position falls within the specified office radius
  GeofenceStatus evaluateGeofence({
    required Position position,
    required double officeLatitude,
    required double officeLongitude,
    required double allowedRadiusMeters,
  }) {
    final distance = calculateDistanceMeters(
      startLatitude: position.latitude,
      startLongitude: position.longitude,
      endLatitude: officeLatitude,
      endLongitude: officeLongitude,
    );

    final isMocked = position.isMocked;
    return GeofenceStatus(
      isWithinGeofence: distance <= allowedRadiusMeters && !isMocked,
      distanceMeters: distance,
      allowedRadiusMeters: allowedRadiusMeters,
      currentPosition: position,
      isMocked: isMocked,
    );
  }
}
