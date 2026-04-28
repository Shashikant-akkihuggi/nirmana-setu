import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// GPS Geofencing Service for Site Attendance Verification
/// 
/// Ensures workers are physically present at the construction site
/// before marking attendance using GPS coordinates and radius validation.
class GeofencingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Maximum allowed GPS accuracy in meters
  static const double maxAccuracyThreshold = 50.0;

  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check and request location permissions
  static Future<LocationPermission> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    return permission;
  }

  /// Get current device location
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable GPS.');
      }

      // Check permissions
      LocationPermission permission = await checkLocationPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied. Please grant permission in settings.');
      }

      // Get current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Validate accuracy
      if (position.accuracy > maxAccuracyThreshold) {
        throw Exception(
          'GPS accuracy too low (${position.accuracy.toStringAsFixed(1)}m). '
          'Please ensure you have clear sky view and try again.'
        );
      }

      return position;
    } catch (e) {
      rethrow;
    }
  }

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in meters
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Convert degrees to radians
  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Get project site location from Firestore
  static Future<Map<String, dynamic>?> getProjectSiteLocation(String projectId) async {
    try {
      DocumentSnapshot projectDoc = await _firestore
          .collection('projects')
          .doc(projectId)
          .get();

      if (!projectDoc.exists) {
        throw Exception('Project not found');
      }

      Map<String, dynamic> projectData = projectDoc.data() as Map<String, dynamic>;
      return projectData['siteLocation'] as Map<String, dynamic>?;
    } catch (e) {
      rethrow;
    }
  }

  /// Verify if current location is within project site geofence
  /// Returns verification result with distance information
  static Future<GeofenceVerificationResult> verifyLocationAtSite(
    String projectId,
  ) async {
    try {
      // Get current location
      Position? currentPosition = await getCurrentLocation();
      if (currentPosition == null) {
        return GeofenceVerificationResult(
          isWithinGeofence: false,
          errorMessage: 'Unable to get current location',
        );
      }

      // Get project site location
      Map<String, dynamic>? siteLocation = await getProjectSiteLocation(projectId);
      if (siteLocation == null) {
        return GeofenceVerificationResult(
          isWithinGeofence: false,
          errorMessage: 'Project site location not configured. Contact Engineer.',
        );
      }

      double siteLat = siteLocation['lat'] ?? 0.0;
      double siteLng = siteLocation['lng'] ?? 0.0;
      double siteRadius = siteLocation['radius'] ?? 100.0;

      // Calculate distance from site
      double distance = calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        siteLat,
        siteLng,
      );

      // Check if within geofence
      bool isWithin = distance <= siteRadius;

      return GeofenceVerificationResult(
        isWithinGeofence: isWithin,
        distance: distance,
        siteRadius: siteRadius,
        currentLat: currentPosition.latitude,
        currentLng: currentPosition.longitude,
        siteLat: siteLat,
        siteLng: siteLng,
        accuracy: currentPosition.accuracy,
        errorMessage: isWithin
            ? null
            : 'You are ${distance.toStringAsFixed(0)}m away from site. '
              'You must be within ${siteRadius.toStringAsFixed(0)}m to mark attendance.',
      );
    } catch (e) {
      return GeofenceVerificationResult(
        isWithinGeofence: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Detect mock/fake GPS (basic detection)
  static Future<bool> isMockLocationEnabled(Position position) async {
    // On Android, check if mock location is enabled
    // Note: This requires additional platform-specific code
    // For now, we'll use accuracy as a basic indicator
    return position.accuracy > 100; // Suspiciously high accuracy might indicate mock
  }

  /// Set project site location (Engineer/Owner only)
  static Future<void> setProjectSiteLocation(
    String projectId,
    double latitude,
    double longitude,
    double radiusInMeters,
  ) async {
    try {
      await _firestore.collection('projects').doc(projectId).update({
        'siteLocation': {
          'lat': latitude,
          'lng': longitude,
          'radius': radiusInMeters,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      });
    } catch (e) {
      rethrow;
    }
  }
}

/// Result of geofence verification
class GeofenceVerificationResult {
  final bool isWithinGeofence;
  final double? distance;
  final double? siteRadius;
  final double? currentLat;
  final double? currentLng;
  final double? siteLat;
  final double? siteLng;
  final double? accuracy;
  final String? errorMessage;

  GeofenceVerificationResult({
    required this.isWithinGeofence,
    this.distance,
    this.siteRadius,
    this.currentLat,
    this.currentLng,
    this.siteLat,
    this.siteLng,
    this.accuracy,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'isWithinGeofence': isWithinGeofence,
      'distance': distance,
      'siteRadius': siteRadius,
      'currentLat': currentLat,
      'currentLng': currentLng,
      'siteLat': siteLat,
      'siteLng': siteLng,
      'accuracy': accuracy,
      'errorMessage': errorMessage,
    };
  }
}
