import 'dart:io' show Platform;
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Default fallback (Kathmandu) if location unavailable
  static const double defaultLat = 27.7000;
  static const double defaultLng = 85.3333;

  /// Check & request location permissions, then get current position.
  /// Returns the user's current [Position] or `null` if denied/unavailable.
  static Future<Position?> getCurrentLocation() async {
    // Geolocator doesn't work on desktop (Linux/Windows/macOS)
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      return null;
    }

    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // 2. Check permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Ask user for permission
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // 3. Permission granted — get position with timeout
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (_) {
      // If anything fails, try last known position
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  /// Opens the device's location/app settings so the user can enable permissions.
  static Future<bool> openSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }
}
