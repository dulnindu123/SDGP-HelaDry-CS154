import 'drying_guide_screen.dart';
import 'package:flutter/material.dart';
import 'start_batch_screen.dart';
import 'drying_report_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
            decoration: const BoxDecoration(color: Color(0xFF13B546)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Welcome,", style: TextStyle(color: Colors.white, fontSize: 16)),
                    Text("Farmer!", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("☀️ Solar Dehydrator Dashboard", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.calendar_today, color: Colors.white), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: () {}),
                  ],
                )
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const DashboardCard(
                  color: Color(0xFFF0F9FF),
                  borderColor: Colors.blueAccent,
                  icon: Icons.wb_cloudy_outlined,
                  iconColor: Colors.orangeAccent,
                  title: "No active drying batch",
                  subtitle: "Start a new batch to begin tracking",
                  textColor: Colors.blueAccent,
                ),
                const SizedBox(height: 16),
                // THE ACTIVE BATCH currently shows at all times not when drying active
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7F0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text("Active Drying Batch", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text("Tomato", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown)),
                      const Text("Day 1 of drying", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500)),
                      const Text("Started: 11/17/2025", style: TextStyle(fontSize: 12, color: Colors.black45)),
                      const SizedBox(height: 12), 
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DryingReportScreen())),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF8A00),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("View Drying Report", style: TextStyle(color: Colors.white)),
                        ),
                      )
                    ],
                  ),
                ),

                // 1. Start New Batch Link
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StartBatchScreen())),
                  child: const DashboardCard(color: Color(0xFF13B546), icon: Icons.add, title: "Start New Batch", subtitle: "Log a new drying batch"),
                ),
                const SizedBox(height: 16),

                // 2. Drying Guide Link
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DryingGuideScreen())),
                  child: const DashboardCard(
                      color: Color(0xFF2979FF),
                      icon: Icons.book,
                      title: "Drying Guide",
                      subtitle: "Crop preparation & schedules"
                  ),
                ),
                // 3. My Records Link (Future Page)
                GestureDetector(
                  onTap: () => _showPlaceholder(context, "My Records", const Color(0xFFAA33FF)),
                  child: const DashboardCard(color: Color(0xFFAA33FF), icon: Icons.description, title: "My Records", subtitle: "View past batches & reports"),
                ),
                const SizedBox(height: 16),

                // 4. Build Dehydrator Link (Future Page)
                GestureDetector(
                  onTap: () => _showPlaceholder(context, "Build Dehydrator", const Color(0xFFFF6D00)),
                  child: const DashboardCard(color: Color(0xFFFF6D00), icon: Icons.build, title: "Build Dehydrator", subtitle: "Construction instructions"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //placeholder for other pages
  void _showPlaceholder(BuildContext context, String title, Color color) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: color),
      body: Center(child: Text("$title test")),
    )));
  }
}

class DashboardCard extends StatelessWidget {
  final Color color;
  final Color? borderColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color textColor;
  final Color iconColor;

  const DashboardCard({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.borderColor,
    this.textColor = Colors.white,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: borderColor != null ? Border.all(color: borderColor!.withOpacity(0.5)) : null,
      ),
      child: Column(
        children: [
          CircleAvatar(backgroundColor: Colors.white.withOpacity(0.2), radius: 25, child: Icon(icon, color: iconColor)),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(subtitle, style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 13)),
        ],
      ),
    );
  }
}