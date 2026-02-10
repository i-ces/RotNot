import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  // Physical Device: Use your computer's IP address
  // Android Emulator: http://10.0.2.2:8000
  // iOS Simulator: http://localhost:8000
  static const String _baseUrl = 'http://10.210.210.194:8000';

  /// Expose base URL for connection testing
  static String get baseUrl => _baseUrl;

  /// Build headers with Firebase ID token
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// GET request
  static Future<http.Response> get(String endpoint) async {
    final headers = await _headers();
    return http.get(Uri.parse('$_baseUrl$endpoint'), headers: headers);
  }

  /// POST request
  static Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final headers = await _headers();
    return http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  /// PUT request
  static Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final headers = await _headers();
    return http.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  /// DELETE request
  static Future<http.Response> delete(String endpoint) async {
    final headers = await _headers();
    return http.delete(Uri.parse('$_baseUrl$endpoint'), headers: headers);
  }

  /// PATCH request
  static Future<http.Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final headers = await _headers();
    return http.patch(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  /// Check backend health status
  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Health check failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to backend: $e');
    }
  }

  // ─── User Profile API ────────────────────────────────────────────────────────

  /// Get current user's profile
  /// GET /api/users/profile
  static Future<Map<String, dynamic>> getUserProfile() async {
    final response = await get('/users/profile');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['profile'] as Map<String, dynamic>;
    } else if (response.statusCode == 404) {
      throw Exception('Profile not found');
    } else {
      throw Exception('Failed to get profile: ${response.statusCode}');
    }
  }

  /// Update user profile
  /// PUT /api/users/profile
  static Future<Map<String, dynamic>> updateUserProfile({
    String? name,
    String? phone,
    String? email,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (email != null) body['email'] = email;

    final response = await put('/users/profile', body: body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['profile'] as Map<String, dynamic>;
    } else {
      throw Exception('Failed to update profile: ${response.statusCode}');
    }
  }

  /// Create or update user profile
  /// POST or PUT /api/users/profile
  static Future<Map<String, dynamic>> createOrUpdateUserProfile({
    required String role,
    String? name,
    String? email,
    String? phone,
  }) async {
    final body = <String, dynamic>{'role': role};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;

    // Try to update first (PUT), if fails try create (POST)
    try {
      final response = await put('/users/profile', body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['profile'] as Map<String, dynamic>;
      }
    } catch (e) {
      // If update fails, try create
    }

    // Create new profile
    final response = await post('/users/profile', body: body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['data']['profile'] as Map<String, dynamic>;
    } else {
      throw Exception(
        'Failed to create/update profile: ${response.statusCode}',
      );
    }
  }

  // ─── Food Items API ──────────────────────────────────────────────────────────

  /// Get all food items for the current user
  /// GET /api/foods
  static Future<List<dynamic>> getFoodItems() async {
    final response = await get('/foods');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['foodItems'] as List<dynamic>;
    } else {
      throw Exception('Failed to get food items: ${response.statusCode}');
    }
  }

  /// Create a new food item
  /// POST /api/foods
  static Future<Map<String, dynamic>> createFoodItem(
    Map<String, dynamic> foodData,
  ) async {
    final response = await post('/foods', body: foodData);
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['data']['foodItem'] as Map<String, dynamic>;
    } else {
      throw Exception('Failed to create food item: ${response.statusCode}');
    }
  }

  /// Update a food item
  /// PUT /api/foods/:id
  static Future<Map<String, dynamic>> updateFoodItem(
    String id,
    Map<String, dynamic> foodData,
  ) async {
    final response = await put('/foods/$id', body: foodData);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['foodItem'] as Map<String, dynamic>;
    } else {
      throw Exception('Failed to update food item: ${response.statusCode}');
    }
  }

  /// Delete a food item
  /// DELETE /api/foods/:id
  static Future<void> deleteFoodItem(String id) async {
    final response = await delete('/foods/$id');
    if (response.statusCode != 200) {
      throw Exception('Failed to delete food item: ${response.statusCode}');
    }
  }

  // ─── Donations API ───────────────────────────────────────────────────────────

  /// Get all donations
  /// GET /api/donations
  static Future<List<dynamic>> getDonations() async {
    final response = await get('/donations');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['donations'] as List<dynamic>;
    } else {
      throw Exception('Failed to get donations: ${response.statusCode}');
    }
  }

  /// Create a new donation
  /// POST /api/donations
  static Future<Map<String, dynamic>> createDonation(
    Map<String, dynamic> donationData,
  ) async {
    final response = await post('/donations', body: donationData);
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['data']['donation'] as Map<String, dynamic>;
    } else {
      throw Exception('Failed to create donation: ${response.statusCode}');
    }
  }

  // ─── Food Banks API ──────────────────────────────────────────────────────────

  /// Get nearby food banks based on location
  /// GET /api/food-banks/nearby?lat=27.7172&lng=85.3240&maxDistance=10000
  static Future<List<dynamic>> getNearbyFoodBanks({
    required double lat,
    required double lng,
    int maxDistance = 10000, // meters (default 10km)
  }) async {
    final response = await get(
      '/food-banks/nearby?lat=$lat&lng=$lng&maxDistance=$maxDistance',
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['foodBanks'] as List<dynamic>;
    } else {
      throw Exception(
        'Failed to get nearby food banks: ${response.statusCode}',
      );
    }
  }

  /// Get all food banks
  /// GET /api/food-banks
  static Future<List<dynamic>> getAllFoodBanks() async {
    final response = await get('/food-banks');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['foodBanks'] as List<dynamic>;
    } else {
      throw Exception('Failed to get food banks: ${response.statusCode}');
    }
  }
}
