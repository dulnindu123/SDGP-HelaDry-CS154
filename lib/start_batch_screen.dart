import 'package:flutter/material.dart';

class StartBatchScreen extends StatefulWidget {
  const StartBatchScreen({super.key});

  @override
  State<StartBatchScreen> createState() => _StartBatchScreenState();
}

class _StartBatchScreenState extends State<StartBatchScreen> {
  // made testvariables to test if selection works  remove if needed
  String? selectedCrop;
  final TextEditingController varietyController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController trayController = TextEditingController();
  final TextEditingController tempController = TextEditingController();
  final TextEditingController humidityController = TextEditingController();

  // Dummy Data for Fruits
  final List<Map<String, String>> crops = [
    {"name": "Mango", "emoji": "🥭"},
    {"name": "Jackfruit", "emoji": "🍈"},
    {"name": "Tomato", "emoji": "🍅"},
    {"name": "Banana", "emoji": "🍌"},
    {"name": "Grape", "emoji": "🍇"},
    {"name": "Chili Pepper", "emoji": "🌶️"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF13B546),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Start New Batch",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Batch Information",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              const Text("Select Crop *", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),

              // SELECTION GRID
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.5,
                ),
                itemCount: crops.length,
                itemBuilder: (context, index) {
                  final crop = crops[index];
                  final isSelected = selectedCrop == crop['name'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCrop = crop['name'];
                        // Dummy Logic: Auto-fill variety based on selection
                        varietyController.text = "${crop['name']} Type A";
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF13B546) : Colors.black12,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(crop['emoji']!, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(crop['name']!,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? const Color(0xFF13B546) : Colors.black87,
                              )),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 25),

              // INPUT FIELDS WITH CONTROLLERS
              CustomTextField(label: "Variety (Optional)", hint: "e.g. Alphonso", controller: varietyController),
              CustomTextField(label: "Starting Weight (kg) *", hint: "0.0", controller: weightController, keyboard: TextInputType.number),
              CustomTextField(label: "Number of Trays *", hint: "0", controller: trayController, keyboard: TextInputType.number),
              CustomTextField(label: "Initial Temp (°C)", hint: "Optional", controller: tempController, keyboard: TextInputType.number),
              CustomTextField(label: "Initial Humidity (%)", hint: "Optional", controller: humidityController, keyboard: TextInputType.number),

              const SizedBox(height: 20),

              // START BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: selectedCrop == null ? null : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Batch started for $selectedCrop! ✅"),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                    // Return to Dashboard after starting the batch
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF13B546),
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Start Drying Batch",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable Input Widget with Controller Support
class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboard;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboard = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboard,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: const Color(0xFFF1F3F4),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}