import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Default fallback (Kathmandu) if location unavailable
  static const double defaultLat = 27.7000;
  static const double defaultLng = 85.3333;

  /// Check & request location permissions, then get current position.
  /// Returns the user's current [Position] or `null` if denied/unavailable.
  static Future<Position?> getCurrentLocation() async {
    // 1. Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are off — can't do anything
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
      // Permission permanently denied — user must enable from settings
      return null;
    }

    // 3. Permission granted — get position
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Opens the device's location/app settings so the user can enable permissions.
  static Future<bool> openSettings() async {
    return await Geolocator.openLocationSettings();
  }
}
