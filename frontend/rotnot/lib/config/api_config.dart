/// API Configuration
///
/// Update the BASE_URL based on your testing environment:
/// - Android Emulator: http://10.0.2.2:3000
/// - iOS Simulator: http://localhost:3000
/// - Physical Device: http://YOUR_COMPUTER_IP:3000 (e.g., http://192.168.1.5:3000)
/// - Web: http://localhost:3000

class ApiConfig {
  // Change this based on your environment
  static const String BASE_URL_ANDROID = 'http://10.0.2.2:3000/api';
  static const String BASE_URL_IOS = 'http://localhost:3000/api';
  static const String BASE_URL_PHYSICAL = 'http://YOUR_IP_HERE:3000/api';

  // Default to Android emulator
  static const String BASE_URL = BASE_URL_ANDROID;
}
