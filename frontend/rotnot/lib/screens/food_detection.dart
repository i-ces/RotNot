import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class FoodDetectionScreen extends StatefulWidget {
  const FoodDetectionScreen({super.key});

  @override
  State<FoodDetectionScreen> createState() => _FoodDetectionScreenState();
}

class _FoodDetectionScreenState extends State<FoodDetectionScreen> {
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color surfaceColor = Color(0xFF1E1E1E);
  
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    setState(() {
      _hasPermission = status.isGranted;
    });
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasPermission = status.isGranted;
    });
    
    if (status.isGranted) {
      _openCamera();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  void _openCamera() {
    debugPrint("Camera Engine Starting...");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Initializing Camera Hardware..."),
        duration: Duration(seconds: 1),
      ),
    );
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
            flex: 5, // Takes up more space
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
                    child: _hasPermission 
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam_rounded, color: accentGreen, size: 40),
                            SizedBox(height: 10),
                            Text("Camera Ready", style: TextStyle(color: Colors.white38, fontSize: 12)),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt_outlined, color: Colors.white10, size: 50),
                            const SizedBox(height: 15),
                            const Text(
                              "Permissions Required",
                              style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
                            ),
                            TextButton(
                              onPressed: _requestPermission,
                              child: const Text("Enable Camera", style: TextStyle(color: accentGreen)),
                            ),
                          ],
                        ),
                  ),
                  const _ScannerOverlay(),
                ],
              ),
            ),
          ),

          // --- MINIMIZED & PUSHED UP TRIGGER ---
          Expanded(
            flex: 1, // Compact bottom section
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _hasPermission ? _openCamera : _requestPermission,
                  child: Container(
                    height: 65, // Reduced from 80
                    width: 65,  // Reduced from 80
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
                      child: const Icon(Icons.camera_rounded, color: Colors.black, size: 28),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "TAP TO SCAN",
                  style: TextStyle(
                    color: Colors.white24, 
                    fontSize: 10, 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 20), // Bottom breathing room
        ],
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
        padding: const EdgeInsets.all(50), // Tightened the corners to look cleaner
        child: CustomPaint(
          painter: ScannerPainter(),
          child: const SizedBox(width: double.infinity, height: double.infinity),
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
    canvas.drawArc(Rect.fromLTWH(0, 0, radius * 2, radius * 2), 3.14, 1.57, false, paint);
    canvas.drawLine(const Offset(radius, 0), const Offset(radius + cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, radius), const Offset(0, radius + cornerLength), paint);

    // Top Right
    canvas.drawArc(Rect.fromLTWH(size.width - radius * 2, 0, radius * 2, radius * 2), 4.71, 1.57, false, paint);
    canvas.drawLine(Offset(size.width - radius, 0), Offset(size.width - radius - cornerLength, 0), paint);
    canvas.drawLine(Offset(size.width, radius), Offset(size.width, radius + cornerLength), paint);

    // Bottom Left
    canvas.drawArc(Rect.fromLTWH(0, size.height - radius * 2, radius * 2, radius * 2), 1.57, 1.57, false, paint);
    canvas.drawLine(Offset(radius, size.height), Offset(radius + cornerLength, size.height), paint);
    canvas.drawLine(Offset(0, size.height - radius), Offset(0, size.height - radius - cornerLength), paint);

    // Bottom Right
    canvas.drawArc(Rect.fromLTWH(size.width - radius * 2, size.height - radius * 2, radius * 2, radius * 2), 0, 1.57, false, paint);
    canvas.drawLine(Offset(size.width - radius, size.height), Offset(size.width - radius - cornerLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - radius), Offset(size.width, size.height - radius - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}