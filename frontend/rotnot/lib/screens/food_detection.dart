import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/food_detection_service.dart';
import '../services/api_service.dart';

class FoodDetectionScreen extends StatefulWidget {
  const FoodDetectionScreen({super.key});

  @override
  State<FoodDetectionScreen> createState() => _FoodDetectionScreenState();
}

class _FoodDetectionScreenState extends State<FoodDetectionScreen> {
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color surfaceColor = Color(0xFF1E1E1E);

  bool _hasPermission = false;
  bool _isLoading = false;
  bool _isCameraInitialized = false;
  CameraController? _cameraController;
  File? _capturedImage;
  FoodDetectionResult? _detectionResult;

  // Shelf items for matching detected food
  List<Map<String, dynamic>> _shelfItems = [];
  Map<String, Map<String, dynamic>> _matchedShelfItems =
      {}; // food name -> shelf item
  bool _isAddingToShelf = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    setState(() {
      _hasPermission = status.isGranted;
    });
    if (status.isGranted) {
      await _initializeCamera();
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasPermission = status.isGranted;
    });

    if (status.isGranted) {
      await _initializeCamera();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showError('No camera found');
        return;
      }

      // Use the back camera
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      _showError('Failed to initialize camera: $e');
    }
  }

  Future<void> _captureAndDetect() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showError('Camera not ready');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Capture the image
      final XFile photo = await _cameraController!.takePicture();
      final File imageFile = File(photo.path);

      setState(() {
        _capturedImage = imageFile;
      });

      // Send to API for detection and fetch shelf items in parallel
      final results = await Future.wait([
        FoodDetectionService.detectFromFile(imageFile),
        _fetchShelfItems(),
      ]);

      final result = results[0] as FoodDetectionResult;

      // Match detected foods with shelf items
      _matchDetectedWithShelf(result);

      setState(() {
        _detectionResult = result;
        _isLoading = false;
      });

      if (result.hasError) {
        _showError(result.error!);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Capture failed: $e');
    }
  }

  Future<void> _fetchShelfItems() async {
    try {
      final items = await ApiService.getFoodItems();
      _shelfItems = items.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching shelf items: $e');
      _shelfItems = [];
    }
  }

  void _matchDetectedWithShelf(FoodDetectionResult result) {
    _matchedShelfItems.clear();

    for (final food in result.foods) {
      final foodName = food.name.toLowerCase().trim();

      // Find matching shelf item (exact match, case-insensitive)
      for (final item in _shelfItems) {
        final itemName = (item['name'] as String?)?.toLowerCase().trim() ?? '';
        // Exact match only
        if (itemName == foodName) {
          _matchedShelfItems[food.name] = item;
          break;
        }
      }
    }
  }

  void _showAddToShelfSheet(DetectedFood food) {
    final nameCtrl = TextEditingController(text: food.displayName);
    final qtyCtrl = TextEditingController(text: food.count.toString());
    final unitCtrl = TextEditingController(text: 'pcs');
    final notesCtrl = TextEditingController();
    DateTime expiryDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  24 + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(food.emoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        const Text(
                          'Add to Shelf',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _sheetTextField(nameCtrl, 'Item name', Icons.label_rounded),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _sheetTextField(
                            qtyCtrl,
                            'Qty',
                            Icons.numbers_rounded,
                            isNumber: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _sheetTextField(
                            unitCtrl,
                            'Unit',
                            Icons.straighten_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: expiryDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 730),
                          ),
                          builder: (ctx, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: accentGreen,
                                  surface: surfaceColor,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setModalState(() => expiryDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              color: Colors.white54,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Expires: ${_formatDate(expiryDate)}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.edit_rounded,
                              color: Colors.white24,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _sheetTextField(
                      notesCtrl,
                      'Notes (optional)',
                      Icons.notes_rounded,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameCtrl.text.trim().isEmpty) return;

                          Navigator.pop(context);
                          setState(() => _isAddingToShelf = true);

                          try {
                            final foodData = {
                              'name': nameCtrl.text.trim(),
                              'category': 'General',
                              'quantity':
                                  int.tryParse(qtyCtrl.text.trim()) ?? 1,
                              'unit': unitCtrl.text.trim().isEmpty
                                  ? 'pcs'
                                  : unitCtrl.text.trim(),
                              'expiryDate': expiryDate.toIso8601String(),
                              if (notesCtrl.text.trim().isNotEmpty)
                                'notes': notesCtrl.text.trim(),
                            };

                            final createdItem = await ApiService.createFoodItem(
                              foodData,
                            );

                            _matchedShelfItems[food.name] = createdItem;
                            _shelfItems.add(createdItem);

                            setState(() => _isAddingToShelf = false);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${nameCtrl.text.trim()} added to shelf!',
                                  ),
                                  backgroundColor: accentGreen,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() => _isAddingToShelf = false);
                            _showError('Failed to add: $e');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Save to Shelf',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sheetTextField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        filled: true,
        fillColor: Colors.black26,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _resetScan() {
    setState(() {
      _capturedImage = null;
      _detectionResult = null;
      _matchedShelfItems.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("AI Scanner"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- THE CAMERA VIEWPORT ---
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: _buildViewportContent(),
                    ),
                  ),
                  if (_capturedImage == null && _isCameraInitialized)
                    const _ScannerOverlay(),
                  if (_isLoading) _buildLoadingOverlay(),
                ],
              ),
            ),
          ),

          // --- DETECTION RESULTS ---
          if (_detectionResult != null) _buildResultsSection(),

          // --- CAPTURE CONTROLS ---
          if (_detectionResult == null)
            Expanded(flex: 1, child: _buildCaptureControls()),

          if (_detectionResult != null) _buildRetakeControls(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildViewportContent() {
    // Show captured image
    if (_capturedImage != null) {
      return Image.file(
        _capturedImage!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    // Show camera preview
    if (_isCameraInitialized && _cameraController != null) {
      return CameraPreview(_cameraController!);
    }

    // Show permission request
    if (!_hasPermission) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.camera_alt_outlined,
            color: Colors.white10,
            size: 50,
          ),
          const SizedBox(height: 15),
          const Text(
            "Permissions Required",
            style: TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: _requestPermission,
            child: const Text(
              "Enable Camera",
              style: TextStyle(color: accentGreen),
            ),
          ),
        ],
      );
    }

    // Loading camera
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: accentGreen),
        SizedBox(height: 10),
        Text(
          "Initializing Camera...",
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: accentGreen),
          SizedBox(height: 20),
          Text(
            "Detecting Food...",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            "AI is analyzing your image",
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    final result = _detectionResult!;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: result.hasFood
              ? accentGreen.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                result.hasFood ? Icons.check_circle : Icons.info_outline,
                color: result.hasFood ? accentGreen : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                result.hasFood
                    ? "Detected ${result.foods.length} Item${result.foods.length > 1 ? 's' : ''}"
                    : "No Food Detected",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          // Food items if detected
          if (result.hasFood) ...[
            const SizedBox(height: 12),
            Column(
              children: result.foods
                  .map((food) => _buildFoodCard(food))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFoodCard(DetectedFood food) {
    final shelfItem = _matchedShelfItems[food.name];
    final isInShelf = shelfItem != null;

    // Parse expiry date if in shelf
    DateTime? expiryDate;
    int? daysLeft;
    Color statusColor = accentGreen;
    String statusText = '';

    if (isInShelf && shelfItem['expiryDate'] != null) {
      expiryDate = DateTime.parse(shelfItem['expiryDate']);
      daysLeft = expiryDate.difference(DateTime.now()).inDays;

      if (daysLeft < 0) {
        statusColor = const Color(0xFFE74C3C); // Red
        statusText = '${daysLeft.abs()}d overdue';
      } else if (daysLeft == 0) {
        statusColor = const Color(0xFFF39C12); // Orange
        statusText = 'Expires today';
      } else if (daysLeft <= 3) {
        statusColor = const Color(0xFFF39C12); // Orange
        statusText = '$daysLeft days left';
      } else {
        statusColor = accentGreen;
        statusText = '$daysLeft days left';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isInShelf
            ? statusColor.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isInShelf
              ? statusColor.withOpacity(0.4)
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Food emoji
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isInShelf ? statusColor : accentGreen).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(food.emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),

          // Food info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      food.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accentGreen.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        food.confidencePercent,
                        style: const TextStyle(
                          color: accentGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (isInShelf) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_rounded,
                        size: 12,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'In Shelf',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    'Not in your shelf',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action button
          if (!isInShelf)
            GestureDetector(
              onTap: _isAddingToShelf ? null : () => _showAddToShelfSheet(food),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: accentGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isAddingToShelf
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: Colors.black87,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Add',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

          if (isInShelf)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                daysLeft != null && daysLeft < 0
                    ? Icons.warning_rounded
                    : daysLeft != null && daysLeft <= 3
                    ? Icons.schedule_rounded
                    : Icons.check_circle_rounded,
                size: 20,
                color: statusColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFoodChip(DetectedFood food) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accentGreen.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentGreen.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(food.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            food.displayName,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: accentGreen.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              food.confidencePercent,
              style: const TextStyle(
                color: accentGreen,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureControls() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _isCameraInitialized ? _captureAndDetect : _requestPermission,
          child: Container(
            height: 65,
            width: 65,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accentGreen.withOpacity(0.5), width: 3),
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Icon(
                Icons.camera_rounded,
                color: Colors.black,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isCameraInitialized ? "TAP TO SCAN" : "ENABLE CAMERA",
          style: const TextStyle(
            color: Colors.white24,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }

  Widget _buildRetakeControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: Center(
        child: _buildActionButton(
          icon: Icons.refresh,
          label: "Retake",
          onTap: _resetScan,
          isPrimary: true,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? accentGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isPrimary ? accentGreen : Colors.white24,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.black : Colors.white54,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.black : Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.all(
          50,
        ), // Tightened the corners to look cleaner
        child: CustomPaint(
          painter: ScannerPainter(),
          child: const SizedBox(
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
}

class ScannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2ECC71)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0; // Slightly thinner lines for a modern look

    const cornerLength = 25.0;
    const radius = 20.0;

    // Top Left
    canvas.drawArc(
      Rect.fromLTWH(0, 0, radius * 2, radius * 2),
      3.14,
      1.57,
      false,
      paint,
    );
    canvas.drawLine(
      const Offset(radius, 0),
      const Offset(radius + cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      const Offset(0, radius),
      const Offset(0, radius + cornerLength),
      paint,
    );

    // Top Right
    canvas.drawArc(
      Rect.fromLTWH(size.width - radius * 2, 0, radius * 2, radius * 2),
      4.71,
      1.57,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(size.width - radius, 0),
      Offset(size.width - radius - cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, radius),
      Offset(size.width, radius + cornerLength),
      paint,
    );

    // Bottom Left
    canvas.drawArc(
      Rect.fromLTWH(0, size.height - radius * 2, radius * 2, radius * 2),
      1.57,
      1.57,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(radius, size.height),
      Offset(radius + cornerLength, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height - radius),
      Offset(0, size.height - radius - cornerLength),
      paint,
    );

    // Bottom Right
    canvas.drawArc(
      Rect.fromLTWH(
        size.width - radius * 2,
        size.height - radius * 2,
        radius * 2,
        radius * 2,
      ),
      0,
      1.57,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(size.width - radius, size.height),
      Offset(size.width - radius - cornerLength, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - radius),
      Offset(size.width, size.height - radius - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Camera preview widget that fills the container
class CameraPreview extends StatelessWidget {
  final CameraController controller;

  const CameraPreview(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width:
                  controller.value.previewSize?.height ?? constraints.maxWidth,
              height:
                  controller.value.previewSize?.width ?? constraints.maxHeight,
              child: CameraPreviewWidget(controller: controller),
            ),
          ),
        );
      },
    );
  }
}

class CameraPreviewWidget extends StatelessWidget {
  final CameraController controller;

  const CameraPreviewWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return controller.buildPreview();
  }
}
