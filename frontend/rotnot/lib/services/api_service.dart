import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Backend URL configuration
  // For Android Emulator: Use 10.0.2.2 instead of localhost
  // For iOS Simulator: Use localhost
  // For Physical Device: Use your computer's IP address (e.g., 192.168.1.x)
  static const String _baseUrlAndroid = 'http://10.0.2.2:3000/api';
  static const String _baseUrlIOS = 'http://localhost:3000/api';
  static const String _baseUrlWeb = 'http://localhost:3000/api';

  // Auto-detect platform and use appropriate URL
  static String get baseUrl {
    // You can uncomment the platform-specific logic when needed
    // if (Platform.isAndroid) return _baseUrlAndroid;
    // if (Platform.isIOS) return _baseUrlIOS;
    // if (kIsWeb) return _baseUrlWeb;

    // For development, defaulting to Android emulator
    return _baseUrlAndroid;
  }

  final _storage = const FlutterSecureStorage();

  // Helper method to get auth token
  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // Helper method to save auth token
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  // Helper method to delete auth token
  Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }

  // Helper method to get headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // GET request
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
        body: json.encode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // PUT request
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
        body: json.encode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // DELETE request
  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Handle HTTP responses
  dynamic _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return json.decode(response.body);
      case 400:
        throw Exception('Bad request: ${response.body}');
      case 401:
        throw Exception('Unauthorized: Please login again');
      case 403:
        throw Exception('Forbidden: Access denied');
      case 404:
        throw Exception('Not found: ${response.body}');
      case 500:
        throw Exception('Server error: Please try again later');
      default:
        throw Exception('Error: ${response.statusCode}');
    }
  }

  // API Methods for your backend routes

  // Health check
  Future<Map<String, dynamic>> checkHealth() async {
    return await get('/health');
  }

  // Food Items
  Future<List<dynamic>> getFoodItems() async {
    return await get('/foods');
  }

  Future<Map<String, dynamic>> createFoodItem(
    Map<String, dynamic> foodData,
  ) async {
    return await post('/foods', foodData);
  }

  Future<Map<String, dynamic>> updateFoodItem(
    String id,
    Map<String, dynamic> foodData,
  ) async {
    return await put('/foods/$id', foodData);
  }

  Future<void> deleteFoodItem(String id) async {
    await delete('/foods/$id');
  }

  // Donations
  Future<List<dynamic>> getDonations() async {
    return await get('/donations');
  }

  Future<Map<String, dynamic>> createDonation(
    Map<String, dynamic> donationData,
  ) async {
    return await post('/donations', donationData);
  }

  // User Profile
  Future<Map<String, dynamic>> getUserProfile() async {
    return await get('/users/profile');
  }

  Future<Map<String, dynamic>> updateUserProfile(
    Map<String, dynamic> profileData,
  ) async {
    return await put('/users/profile', profileData);
  }
}
