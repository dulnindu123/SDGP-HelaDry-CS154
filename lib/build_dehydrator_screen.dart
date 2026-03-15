import 'package:flutter/material.dart';

class BuildDehydratorScreen extends StatefulWidget {
  const BuildDehydratorScreen({super.key});

  @override
  State<BuildDehydratorScreen> createState() => _BuildDehydratorScreenState();
}

class _BuildDehydratorScreenState extends State<BuildDehydratorScreen> {
  final List<_ChecklistSection> sections = [
    _ChecklistSection(
      title: 'Frame Structure',
      items: [
        _ChecklistItem(label: 'Wooden planks (2" × 1") 12 feet'),
        _ChecklistItem(label: 'Wooden planks (1" × 1") 20 feet'),
        _ChecklistItem(label: 'Wood screws (2") 50 pieces'),
        _ChecklistItem(label: 'Wood screws (1") 30 pieces'),
        _ChecklistItem(label: 'L-brackets 8 pieces'),
      ],
    ),
    _ChecklistSection(
      title: 'Cover & Protection',
      items: [
        _ChecklistItem(label: 'Hinges (for door) 2 pieces'),
        _ChecklistItem(label: 'Wire mesh (for ventilation) 2 × 2 feet'),
      ],
    ),
    _ChecklistSection(
      title: 'Drying Trays',
      items: [
        _ChecklistItem(label: 'Food-grade mesh/screen 12 sq feet'),
        _ChecklistItem(label: 'Thin wooden strips (½" × 16½") 16 feet'),
        _ChecklistItem(label: 'Small nails or staples 100 pieces'),
      ],
    ),
    _ChecklistSection(
      title: 'Tools & Accessories',
      items: [
        _ChecklistItem(label: 'Thermometer 1 piece'),
        _ChecklistItem(label: 'Glue or sealant 1 tube'),
        _ChecklistItem(label: 'Brush/paint (optional)'),
      ],
    ),
  ];

  int get totalItems => sections.fold(0, (sum, section) => sum + section.items.length);
  int get completedItems => sections.fold(0, (sum, section) => sum + section.items.where((i) => i.checked).length);

  @override
  Widget build(BuildContext context) {
    final completion = totalItems == 0 ? 0.0 : completedItems / totalItems;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6D00),
        title: const Text('Build Your Dehydrator'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text('Step-by-step construction guide', style: TextStyle(color: Colors.white.withOpacity(0.9))),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: 'Materials Checklist', progress: completion),
          const SizedBox(height: 12),
          ...sections.map((section) => _ChecklistSectionWidget(
                section: section,
                onToggle: () => setState(() {}),
              )),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Construction Steps', progress: completion),
          const SizedBox(height: 12),
          const Text(
            '1. Build the main frame using the wooden planks and screws.\n'
            '2. Attach the mesh and cover securely for ventilation.\n'
            '3. Add trays and make sure air can circulate.\n'
            '4. Install a thermometer and test the airflow.\n',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final double progress;

  const _SectionHeader({required this.title, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
          ),
          child: Text('${(progress * 100).round()}% Complete', style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}

class _ChecklistSectionWidget extends StatelessWidget {
  final _ChecklistSection section;
  final VoidCallback onToggle;

  const _ChecklistSectionWidget({required this.section, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final completed = section.items.where((item) => item.checked).length;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(section.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('$completed/${section.items.length}', style: const TextStyle(color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 8),
          ...section.items.map((item) => CheckboxListTile(
                value: item.checked,
                onChanged: (v) {
                  item.checked = v ?? false;
                  onToggle();
                },
                contentPadding: EdgeInsets.zero,
                title: Text(item.label),
                dense: true,
              )),
        ],
      ),
    );
  }
}

class _ChecklistSection {
  final String title;
  final List<_ChecklistItem> items;

  _ChecklistSection({required this.title, required this.items});
}

class _ChecklistItem {
  final String label;
  bool checked;

  _ChecklistItem({required this.label, this.checked = false});
}
