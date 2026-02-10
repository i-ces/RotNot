import 'dart:convert';
import 'dart:io';
import 'api_service.dart';

/// Detected food item from AI scanner
class DetectedFood {
  final String name;
  final double confidence;
  final int count;

  DetectedFood({required this.name, required this.confidence, this.count = 1});

  factory DetectedFood.fromJson(Map<String, dynamic> json) {
    return DetectedFood(
      name: json['name'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      count: json['count'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'confidence': confidence,
    'count': count,
  };

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(0)}%';

  String get displayName => name[0].toUpperCase() + name.substring(1);

  String get emoji {
    const emojis = {
      'banana': '🍌',
      'apple': '🍎',
      'sandwich': '🥪',
      'orange': '🍊',
      'broccoli': '🥦',
      'carrot': '🥕',
      'hot dog': '🌭',
      'pizza': '🍕',
      'donut': '🍩',
      'cake': '🎂',
    };
    return emojis[name.toLowerCase()] ?? '🍽️';
  }
}

/// Result of food detection
class FoodDetectionResult {
  final bool success;
  final List<DetectedFood> foods;
  final String message;
  final String? error;

  FoodDetectionResult({
    required this.success,
    required this.foods,
    required this.message,
    this.error,
  });

  factory FoodDetectionResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final foodsList = data?['foods'] as List<dynamic>? ?? [];

    return FoodDetectionResult(
      success: json['success'] as bool,
      foods: foodsList
          .map((f) => DetectedFood.fromJson(f as Map<String, dynamic>))
          .toList(),
      message: json['message'] as String? ?? '',
    );
  }

  factory FoodDetectionResult.error(String errorMessage) {
    return FoodDetectionResult(
      success: false,
      foods: [],
      message: '',
      error: errorMessage,
    );
  }

  bool get hasFood => foods.isNotEmpty;
  bool get hasError => error != null;

  Map<String, dynamic> toJson() => {
    'success': success,
    'foods': foods.map((f) => f.toJson()).toList(),
    'message': message,
  };
}

/// Service for food detection via AI scanner
class FoodDetectionService {
  /// Detect food from image file (converts to base64)
  static Future<FoodDetectionResult> detectFromFile(File imageFile) async {
    try {
      // Read file and convert to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      print('Image file size: ${bytes.length} bytes');
      print('Base64 length: ${base64Image.length} chars');

      return detectFromBase64(base64Image);
    } catch (e) {
      print('Error reading image file: $e');
      return FoodDetectionResult.error('Failed to read image: $e');
    }
  }

  /// Detect food from base64 encoded image
  static Future<FoodDetectionResult> detectFromBase64(
    String base64Image,
  ) async {
    try {
      print('Sending image to API, base64 length: ${base64Image.length}');

      final response = await ApiService.post(
        '/detect/base64',
        body: {'image': base64Image},
      );

      print('API response status: ${response.statusCode}');
      print(
        'API response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FoodDetectionResult.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        return FoodDetectionResult.error(
          error['message'] ?? 'Detection failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Detection error: $e');
      return FoodDetectionResult.error('Connection error: $e');
    }
  }

  /// Check if detection service is available
  static Future<bool> checkHealth() async {
    try {
      final response = await ApiService.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
