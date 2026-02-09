import 'package:flutter/material.dart';
import 'package:rotnot/services/api_service.dart';

/// Widget to test backend connection
/// Add this to any screen to verify backend connectivity
class BackendConnectionTest extends StatefulWidget {
  const BackendConnectionTest({super.key});

  @override
  State<BackendConnectionTest> createState() => _BackendConnectionTestState();
}

class _BackendConnectionTestState extends State<BackendConnectionTest> {
  final _apiService = ApiService();
  String _status = 'Not tested';
  Color _statusColor = Colors.grey;
  bool _isLoading = false;

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing...';
      _statusColor = Colors.orange;
    });

    try {
      final response = await _apiService.checkHealth();
      setState(() {
        _status = 'Connected! ${response['message'] ?? 'Backend is healthy'}';
        _statusColor = Colors.green;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Connection failed: $e';
        _statusColor = Colors.red;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backend Connection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'URL: ${ApiService.baseUrl}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(_status, style: TextStyle(color: _statusColor)),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testConnection,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Test'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Example: Add to your home screen or settings screen
///
/// Usage:
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return Scaffold(
///     body: Column(
///       children: [
///         BackendConnectionTest(),
///         // ... rest of your widgets
///       ],
///     ),
///   );
/// }
/// ```
