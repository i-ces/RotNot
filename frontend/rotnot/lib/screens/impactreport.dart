import 'package:flutter/material.dart';

class ImpactReportPage extends StatelessWidget {
  const ImpactReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Impact Report")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Your Journey", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            // Mock Graph Placeholder
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: const Center(child: Text("Monthly Savings Graph", style: TextStyle(color: Colors.white24))),
            ),
            const SizedBox(height: 30),
            _buildDetailRow("Total CO2 Avoided", "18.4 kg"),
            _buildDetailRow("Money Saved (NPR)", "रू 1,420"),
            _buildDetailRow("Items Consumed", "42"),
            _buildDetailRow("Waste Reduction Rate", "92%"),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white60)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2ECC71))),
        ],
      ),
    );
  }
}