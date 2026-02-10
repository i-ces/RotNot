import 'package:flutter/material.dart';
import '../services/recipe_service.dart';
import '../services/api_service.dart';

/// Chat message model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;
  final String? recipeName;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.isLoading = false,
    this.recipeName,
  }) : timestamp = timestamp ?? DateTime.now();
}

class SmartRecipesPage extends StatefulWidget {
  const SmartRecipesPage({super.key});

  @override
  State<SmartRecipesPage> createState() => _SmartRecipesPageState();
}

class _SmartRecipesPageState extends State<SmartRecipesPage> {
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color accentOrange = Color(0xFFE67E22);
  static const Color surfaceColor = Color(0xFF1E1E1E);

  final Map<int, bool> _selectedItems = {};
  bool _isExpanded = false;
  bool _isLoading = false;
  bool _isLoadingItems = true;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Chat messages
  final List<ChatMessage> _messages = [];

  // Food items loaded from API
  List<Map<String, String>> _foodItems = [];
  String? _loadError;

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Get list of selected ingredient names
  List<String> get selectedIngredients {
    return _selectedItems.entries
        .where((e) => e.value)
        .map((e) => _foodItems[e.key]['name']!)
        .toList();
  }

  /// Get all ingredient names
  List<String> get allIngredients {
    return _foodItems.map((e) => e['name']!).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadFoodItems();
    // Add welcome message
    _messages.add(
      ChatMessage(
        text:
            "Hi! I'm your AI Kitchen Assistant. Ask me for recipe ideas, cooking tips, or select ingredients above to generate recipes!",
        isUser: false,
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Clean markdown symbols from text
  String _cleanMarkdown(String text) {
    return text
        .replaceAllMapped(
          RegExp(r'\*\*(.+?)\*\*'),
          (m) => m.group(1) ?? '',
        ) // Remove **bold**
        .replaceAllMapped(
          RegExp(r'\*(.+?)\*'),
          (m) => m.group(1) ?? '',
        ) // Remove *italic*
        .replaceAllMapped(
          RegExp(r'__(.+?)__'),
          (m) => m.group(1) ?? '',
        ) // Remove __bold__
        .replaceAllMapped(
          RegExp(r'_(.+?)_'),
          (m) => m.group(1) ?? '',
        ) // Remove _italic_
        .replaceAll(RegExp(r'^#+\s*', multiLine: true), '') // Remove # headers
        .replaceAll(
          RegExp(r'^\s*[-*]\s+', multiLine: true),
          '• ',
        ) // Convert bullets
        .trim();
  }

  Future<void> _loadFoodItems() async {
    setState(() {
      _isLoadingItems = true;
      _loadError = null;
    });

    try {
      final items = await ApiService.getFoodItems();
      final now = DateTime.now();

      // Convert API items to our format, prioritizing expiring items
      final foodList = <Map<String, String>>[];

      for (final item in items) {
        final name = item['name'] as String? ?? 'Unknown';
        final expiryStr = item['expiryDate'] as String?;

        if (expiryStr != null) {
          final expiryDate = DateTime.tryParse(expiryStr);
          if (expiryDate != null) {
            final daysLeft = expiryDate.difference(now).inDays;
            String daysLabel;

            if (daysLeft < 0) {
              daysLabel = '${daysLeft.abs()} days overdue';
            } else if (daysLeft == 0) {
              daysLabel = 'Expires today';
            } else if (daysLeft == 1) {
              daysLabel = '1 day left';
            } else {
              daysLabel = '$daysLeft days left';
            }

            foodList.add({
              'name': name,
              'days': daysLabel,
              'daysLeft': daysLeft.toString(),
            });
          }
        } else {
          foodList.add({
            'name': name,
            'days': 'No expiry set',
            'daysLeft': '999',
          });
        }
      }

      // Sort by days left (most urgent first)
      foodList.sort((a, b) {
        final aDays = int.tryParse(a['daysLeft'] ?? '999') ?? 999;
        final bDays = int.tryParse(b['daysLeft'] ?? '999') ?? 999;
        return aDays.compareTo(bDays);
      });

      setState(() {
        _foodItems = foodList;
        _isLoadingItems = false;
        // Initialize selection state
        for (int i = 0; i < _foodItems.length; i++) {
          _selectedItems[i] = false;
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingItems = false;
        _loadError = 'Failed to load food items: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int selectedCount = _selectedItems.values.where((v) => v).length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Smart Recipes"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // --- Collapsible Ingredient Selector ---
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                onExpansionChanged: (val) => setState(() => _isExpanded = val),
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                title: Row(
                  children: [
                    Icon(
                      Icons.inventory_2_rounded,
                      color: _isExpanded ? accentGreen : Colors.white60,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedCount > 0
                            ? "$selectedCount ingredient${selectedCount > 1 ? 's' : ''} selected"
                            : "Select ingredients",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: selectedCount > 0
                              ? accentGreen
                              : Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedCount > 0)
                      GestureDetector(
                        onTap: _isLoading ? null : _generateFromSelection,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: accentGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Generate',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.white38,
                    ),
                  ],
                ),
                children: [
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: _isLoadingItems
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                color: accentGreen,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : _foodItems.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'No items in shelf. Add food first!',
                              style: TextStyle(color: Colors.white38),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _foodItems.length,
                            itemBuilder: (context, index) {
                              final item = _foodItems[index];
                              final isSelected = _selectedItems[index] ?? false;
                              return CheckboxListTile(
                                value: isSelected,
                                onChanged: (val) => setState(
                                  () => _selectedItems[index] = val!,
                                ),
                                dense: true,
                                activeColor: accentGreen,
                                checkColor: Colors.black,
                                title: Text(
                                  item['name']!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isSelected
                                        ? accentGreen
                                        : Colors.white,
                                  ),
                                ),
                                subtitle: Text(
                                  item['days']!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white38,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // --- Chat Messages Area ---
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // --- Chat Input ---
          _buildChatInput(),
        ],
      ),
    );
  }

  /// Build a chat message bubble
  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    if (message.isLoading) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, right: 60),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(
              20,
            ).copyWith(bottomLeft: const Radius.circular(4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  color: accentGreen,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Thinking...',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12,
          left: isUser ? 60 : 0,
          right: isUser ? 0 : 60,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: accentGreen.withOpacity(0.2),
                child: const Icon(
                  Icons.restaurant,
                  color: accentGreen,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isUser ? accentGreen : surfaceColor,
                  borderRadius: BorderRadius.circular(20).copyWith(
                    bottomRight: isUser ? const Radius.circular(4) : null,
                    bottomLeft: !isUser ? const Radius.circular(4) : null,
                  ),
                  border: isUser
                      ? null
                      : Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.recipeName != null) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            color: accentGreen,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              message.recipeName!,
                              style: TextStyle(
                                color: accentGreen,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Divider(color: Colors.white.withOpacity(0.1), height: 1),
                      const SizedBox(height: 8),
                    ],
                    SelectableText(
                      message.recipeName != null
                          ? message.text.replaceFirst(
                              '${message.recipeName}\n\n',
                              '',
                            )
                          : message.text,
                      style: TextStyle(
                        color: isUser
                            ? Colors.white
                            : Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white.withOpacity(0.1),
                child: const Icon(
                  Icons.person,
                  color: Colors.white60,
                  size: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Suggestion chips
            if (!_isLoading && _foodItems.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _chatController.text =
                      "What can I make with ${allIngredients.take(3).join(', ')}?";
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    color: accentOrange,
                    size: 18,
                  ),
                ),
              ),
            // Text input
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: _chatController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  onSubmitted: (_) => _handleChatSend(),
                  enabled: !_isLoading,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: _isLoading
                        ? "Generating recipe..."
                        : "Ask for a recipe or cooking tip...",
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Send button
            GestureDetector(
              onTap: _isLoading ? null : _handleChatSend,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isLoading ? Colors.white10 : accentGreen,
                  shape: BoxShape.circle,
                ),
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAILoader(BuildContext context, String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        height: 250,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const LinearProgressIndicator(
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(accentGreen),
            ),
            const SizedBox(height: 32),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Finding the best recipe for your ingredients...",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }

  /// Generate recipes from selected ingredients
  Future<void> _generateFromSelection() async {
    if (selectedIngredients.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // First get recipe suggestions
      final suggestResult = await RecipeService.suggestRecipes(
        ingredients: selectedIngredients,
        numRecipes: 3,
      );

      if (!mounted) return;

      if (suggestResult.hasError) {
        _showErrorSnackbar(suggestResult.error!);
        setState(() => _isLoading = false);
        return;
      }

      if (suggestResult.recipes.isEmpty) {
        _showErrorSnackbar('No recipes found for these ingredients');
        setState(() => _isLoading = false);
        return;
      }

      // Show recipe selection dialog
      setState(() => _isLoading = false);
      _showRecipeSuggestions(suggestResult.recipes, selectedIngredients);
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Failed to generate recipes: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  /// Generate surprise recipe from all ingredients
  Future<void> _generateSurpriseRecipe() async {
    if (allIngredients.isEmpty) return;

    setState(() => _isLoading = true);
    _showAILoader(context, "Scanning your whole shelf...");

    try {
      final result = await RecipeService.surpriseMe(
        ingredients: allIngredients,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loader

      if (result.hasError) {
        _showErrorSnackbar(result.error!);
      } else {
        _showRecipeDetails(result.recipeName, result.fullDescription);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorSnackbar('Failed to generate recipe: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Handle chat message send
  Future<void> _handleChatSend() async {
    final query = _chatController.text.trim();
    if (query.isEmpty) return;

    // Add user message to chat
    setState(() {
      _messages.add(ChatMessage(text: query, isUser: true));
      _isLoading = true;
    });
    _chatController.clear();
    _scrollToBottom();

    // Add loading message
    setState(() {
      _messages.add(ChatMessage(text: '', isUser: false, isLoading: true));
    });
    _scrollToBottom();

    try {
      // Use the chat query as a recipe name to get full recipe
      final result = await RecipeService.getFullRecipe(
        recipeName: query,
        availableIngredients: allIngredients,
      );

      if (!mounted) return;

      // Remove loading message and add response
      setState(() {
        _messages.removeWhere((m) => m.isLoading);
        if (result.hasError) {
          _messages.add(
            ChatMessage(
              text: "Sorry, I couldn't help with that. ${result.error}",
              isUser: false,
            ),
          );
        } else {
          // Clean up any markdown symbols from the response
          final cleanDescription = _cleanMarkdown(result.fullDescription);
          _messages.add(
            ChatMessage(
              text: "${result.recipeName}\n\n$cleanDescription",
              isUser: false,
              recipeName: result.recipeName,
            ),
          );
        }
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.isLoading);
          _messages.add(
            ChatMessage(
              text: "Oops! Something went wrong. Please try again.",
              isUser: false,
            ),
          );
        });
        _scrollToBottom();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Show recipe suggestions to pick from
  void _showRecipeSuggestions(List<String> recipes, List<String> ingredients) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Choose a Recipe",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Based on: ${ingredients.join(', ')}",
              style: const TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: recipes.length,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _fetchFullRecipe(recipe, ingredients);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.restaurant_menu,
                              color: accentGreen,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                recipe,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white24,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fetch and show full recipe details
  Future<void> _fetchFullRecipe(
    String recipeName,
    List<String> ingredients,
  ) async {
    setState(() => _isLoading = true);
    _showAILoader(context, "Getting recipe details...");

    try {
      final result = await RecipeService.getFullRecipe(
        recipeName: recipeName,
        availableIngredients: ingredients,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loader

      if (result.hasError) {
        _showErrorSnackbar(result.error!);
      } else {
        _showRecipeDetails(result.recipeName, result.fullDescription);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorSnackbar('Failed to get recipe: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Show full recipe details in a bottom sheet
  void _showRecipeDetails(String recipeName, String description) {
    // Clean markdown symbols from the description
    final cleanDescription = _cleanMarkdown(description);
    final cleanRecipeName = _cleanMarkdown(recipeName);

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Icons.restaurant, color: accentGreen, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cleanRecipeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                child: Text(
                  cleanDescription,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
