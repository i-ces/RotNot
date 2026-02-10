import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for AI-powered recipe generation
class RecipeService {
  // Recipe API runs on port 8001 (separate from food detection on 8000)
  // Physical Device: Use your computer's IP address
  // Android Emulator: http://10.0.2.2:8001
  // iOS Simulator: http://localhost:8001
  static const String _recipeApiUrl = 'http://192.168.17.211:8001';

  /// Generate recipe name suggestions from ingredients
  static Future<RecipeSuggestionsResult> suggestRecipes({
    required List<String> ingredients,
    int numRecipes = 3,
  }) async {
    try {
      if (ingredients.isEmpty) {
        return RecipeSuggestionsResult.error('No ingredients provided');
      }

      final response = await http.post(
        Uri.parse('$_recipeApiUrl/recipes/suggest'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ingredients': ingredients,
          'num_recipes': numRecipes,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RecipeSuggestionsResult.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        return RecipeSuggestionsResult.error(
          error['detail'] ?? 'Failed to generate recipes',
        );
      }
    } catch (e) {
      return RecipeSuggestionsResult.error('Connection error: $e');
    }
  }

  /// Get full recipe details for a specific recipe name
  static Future<FullRecipeResult> getFullRecipe({
    required String recipeName,
    List<String>? availableIngredients,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_recipeApiUrl/recipes/full'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'recipe_name': recipeName,
          if (availableIngredients != null)
            'available_ingredients': availableIngredients,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FullRecipeResult.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        return FullRecipeResult.error(
          error['detail'] ?? 'Failed to get recipe',
        );
      }
    } catch (e) {
      return FullRecipeResult.error('Connection error: $e');
    }
  }

  /// Generate a surprise recipe from all ingredients
  static Future<FullRecipeResult> surpriseMe({
    required List<String> ingredients,
  }) async {
    try {
      if (ingredients.isEmpty) {
        return FullRecipeResult.error('No ingredients provided');
      }

      final response = await http.post(
        Uri.parse('$_recipeApiUrl/recipes/surprise'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ingredients': ingredients, 'num_recipes': 1}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FullRecipeResult.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        return FullRecipeResult.error(
          error['detail'] ?? 'Failed to generate surprise recipe',
        );
      }
    } catch (e) {
      return FullRecipeResult.error('Connection error: $e');
    }
  }

  /// Check if recipe API is available
  static Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$_recipeApiUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// Result for recipe suggestions
class RecipeSuggestionsResult {
  final bool success;
  final List<String> recipes;
  final String message;
  final String? error;

  RecipeSuggestionsResult({
    required this.success,
    required this.recipes,
    required this.message,
    this.error,
  });

  factory RecipeSuggestionsResult.fromJson(Map<String, dynamic> json) {
    final recipesList = json['recipes'] as List<dynamic>? ?? [];
    return RecipeSuggestionsResult(
      success: json['success'] as bool,
      recipes: recipesList.map((r) => r.toString()).toList(),
      message: json['message'] as String? ?? '',
    );
  }

  factory RecipeSuggestionsResult.error(String errorMessage) {
    return RecipeSuggestionsResult(
      success: false,
      recipes: [],
      message: '',
      error: errorMessage,
    );
  }

  bool get hasRecipes => recipes.isNotEmpty;
  bool get hasError => error != null;
}

/// Result for full recipe details
class FullRecipeResult {
  final bool success;
  final String recipeName;
  final String fullDescription;
  final String message;
  final String? error;

  FullRecipeResult({
    required this.success,
    required this.recipeName,
    required this.fullDescription,
    required this.message,
    this.error,
  });

  factory FullRecipeResult.fromJson(Map<String, dynamic> json) {
    return FullRecipeResult(
      success: json['success'] as bool,
      recipeName: json['recipe_name'] as String? ?? '',
      fullDescription: json['full_description'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }

  factory FullRecipeResult.error(String errorMessage) {
    return FullRecipeResult(
      success: false,
      recipeName: '',
      fullDescription: '',
      message: '',
      error: errorMessage,
    );
  }

  bool get hasError => error != null;
}
