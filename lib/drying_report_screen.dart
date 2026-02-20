import 'package:flutter/material.dart';

class DryingReportScreen extends StatelessWidget {
  const DryingReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8A00),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text("Tomato Batch Report", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
            child: const Center(child: Text("Active", style: TextStyle(color: Colors.white, fontSize: 12))),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: const [
                ReportStatCard(icon: Icons.calendar_month, label: "Days Elapsed", value: "1"),
                ReportStatCard(icon: Icons.shopping_bag_outlined, label: "Start Weight", value: "2 kg"),
                ReportStatCard(icon: Icons.thermostat, label: "Target Temp", value: "52°C", color: Colors.red),
                ReportStatCard(icon: Icons.access_time, label: "Est. Time", value: "12-24h", color: Colors.purple),
              ],
            ),
            const SizedBox(height: 20),

            // Graph Placeholder
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Temperature & Humidity Over Time", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 100, child: Center(child: Icon(Icons.show_chart, size: 80, color: Colors.blueAccent))), // Dummy Graph
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legend(Colors.blue, "Humidity (%)"),
                      const SizedBox(width: 20),
                      _legend(Colors.red, "Temperature (°C)"),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Completion Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withValues(alpha: 0.5))),
              child: Column(
                children: [
                  const Row(children: [Icon(Icons.check_circle_outline, color: Colors.green), SizedBox(width: 8), Text("Complete This Batch")]),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: const Text("Mark as Complete", style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String text) => Row(children: [Icon(Icons.horizontal_rule, color: color), Text(text, style: const TextStyle(fontSize: 10))]);
}

class ReportStatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const ReportStatCard({super.key, required this.icon, required this.label, required this.value, this.color = Colors.blue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}