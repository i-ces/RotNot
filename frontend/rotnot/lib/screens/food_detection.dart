import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/food_detection_service.dart';

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

      // Send to API for detection
      final result = await FoodDetectionService.detectFromFile(imageFile);

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
        actions: [
          if (_capturedImage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetScan,
              tooltip: 'New Scan',
            ),
        ],
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

          // --- DETECTION RESULTS (JSON Output) ---
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
          const SizedBox(height: 12),

          // JSON Output
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "JSON Output:",
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Text(
                  const JsonEncoder.withIndent('  ').convert(result.toJson()),
                  style: const TextStyle(
                    color: accentGreen,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          // Food chips if detected
          if (result.hasFood) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.foods
                  .map((food) => _buildFoodChip(food))
                  .toList(),
            ),
          ],
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.refresh,
            label: "Retake",
            onTap: _resetScan,
          ),
          _buildActionButton(
            icon: Icons.camera_alt,
            label: "Scan Again",
            onTap: () {
              _resetScan();
              Future.delayed(
                const Duration(milliseconds: 100),
                _captureAndDetect,
              );
            },
            isPrimary: true,
          ),
        ],
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
