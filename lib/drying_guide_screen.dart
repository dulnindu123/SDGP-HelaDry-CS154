import 'package:flutter/material.dart';

class DryingGuideScreen extends StatefulWidget {
  const DryingGuideScreen({super.key});

  @override
  State<DryingGuideScreen> createState() => _DryingGuideScreenState();
}

class _DryingGuideScreenState extends State<DryingGuideScreen> {
  // 1. Current selected fruit rn its mango
  String selectedFruit = "Mango";

  // 2. place holder data for fruits
  final Map<String, Map<String, dynamic>> cropData = {
    "Mango": {
      "emoji": "🥭",
      "temp": "55-60°C",
      "time": "12-18 hours",
      "steps": ["Select firm, ripe mangos", "Peel and slice into 5mm strips", "Arrange on trays without overlapping"],
      "tips": "Avoid fibrous varieties for best results."
    },
    "Jackfruit": {
      "emoji": "🍈",
      "temp": "60°C",
      "time": "18-24 hours",
      "steps": ["Remove seeds and rags", "Slice bulbs into halves", "Place skin-side down on trays"],
      "tips": "Very sticky! Lightly oil trays first."
    },
    "Tomato": {
      "emoji": "🍅",
      "temp": "55°C",
      "time": "12-24 hours",
      "steps": ["Select firm, red tomatoes", "Cut into 6-8mm thick slices", "Remove excess seeds if desired", "Optional: Sprinkle with salt"],
      "tips": "Rotate trays every 4-6 hours."
    },
    "Banana": {
      "emoji": "🍌",
      "temp": "55°C",
      "time": "10-14 hours",
      "steps": ["Use yellow bananas with brown spots", "Slice into round coins", "Dip in lemon water to prevent browning"],
      "tips": "Check for 'leathery' texture."
    },
    "Papaya": {
      "emoji": "🍈",
      "temp": "55-60°C",
      "time": "14-20 hours",
      "steps": ["Peel and remove seeds", "Slice into uniform long strips", "Ensure slices are not too thick"],
      "tips": "Store in airtight containers immediately."
    },
    "Chili Pepper": {
      "emoji": "🌶️",
      "temp": "50°C",
      "time": "12-24 hours",
      "steps": ["Wash and dry peppers", "Slit long peppers down the middle", "Place on trays in a single layer"],
      "tips": "Wear gloves when handling hot peppers!"
    },
  };

  @override
  Widget build(BuildContext context) {
    var data = cropData[selectedFruit]!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2979FF),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text("Crop Drying Guide", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // crop select buttons
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1,
              ),
              itemCount: cropData.keys.length,
              itemBuilder: (context, index) {
                String name = cropData.keys.elementAt(index);
                bool isSelected = selectedFruit == name;
                return GestureDetector(
                  onTap: () => setState(() => selectedFruit = name),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? const Color(0xFF2979FF) : Colors.black12, width: 2),
                      boxShadow: isSelected ? [BoxShadow(color: Colors.blue.withValues(alpha: 0.1), blurRadius: 4)] : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(cropData[name]!['emoji'], style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 25),

            // the info for drying
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(data['emoji'], style: const TextStyle(fontSize: 50)),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(selectedFruit, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.thermostat, size: 16, color: Colors.blueGrey),
                          Text(" ${data['temp']}", style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 15),
                          const Icon(Icons.access_time, size: 16, color: Colors.blueGrey),
                          Text(" ${data['time']}", style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),
            const Text("Preparation Steps", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // steps for dryin
            ...data['steps'].asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(radius: 12, backgroundColor: const Color(0xFF2979FF), child: Text("${entry.key + 1}", style: const TextStyle(color: Colors.white, fontSize: 12))),
                    const SizedBox(width: 12),
                    Expanded(child: Text(entry.value, style: const TextStyle(fontSize: 14, height: 1.4))),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            // tip section for dryin
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFFFFBE6), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFFE58F))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [Icon(Icons.lightbulb_outline, color: Colors.orange, size: 18), SizedBox(width: 8), Text("Quick Tip", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown))],
                  ),
                  const SizedBox(height: 8),
                  Text(data['tips'], style: const TextStyle(fontSize: 13, color: Colors.brown)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}