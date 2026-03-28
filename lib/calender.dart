import 'package:flutter/material.dart';

// dummy data

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;
  String _filterStatus = 'All';

  final List<String> _filterOptions = ['All', 'Active', 'Completed', 'Scheduled'];

  final List<BatchEvent> _events = [
    BatchEvent(
      id: 'BATCH-001',
      crop: 'Mango',
      emoji: '🥭',
      start: DateTime.now().subtract(const Duration(days: 14)),
      end: DateTime.now().subtract(const Duration(days: 12)),
      status: 'Completed',
      trays: 4,
      weight: 5.0,
      targetTemp: 60,
    ),
    BatchEvent(
      id: 'BATCH-002',
      crop: 'Tomato',
      emoji: '🍅',
      start: DateTime.now().subtract(const Duration(days: 8)),
      end: DateTime.now().subtract(const Duration(days: 7)),
      status: 'Completed',
      trays: 3,
      weight: 3.5,
      targetTemp: 55,
    ),
    BatchEvent(
      id: 'BATCH-003',
      crop: 'Banana',
      emoji: '🍌',
      start: DateTime.now().subtract(const Duration(days: 4)),
      end: DateTime.now().subtract(const Duration(days: 3)),
      status: 'Completed',
      trays: 5,
      weight: 4.2,
      targetTemp: 58,
    ),
    BatchEvent(
      id: 'BATCH-004',
      crop: 'Chili',
      emoji: '🌶️',
      start: DateTime.now().subtract(const Duration(days: 1)),
      end: DateTime.now().add(const Duration(hours: 10)),
      status: 'Active',
      trays: 2,
      weight: 1.8,
      targetTemp: 50,
    ),
    BatchEvent(
      id: 'BATCH-005',
      crop: 'Jackfruit',
      emoji: '🍈',
      start: DateTime.now().add(const Duration(days: 2)),
      end: DateTime.now().add(const Duration(days: 4)),
      status: 'Scheduled',
      trays: 6,
      weight: 7.0,
      targetTemp: 55,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Calendar')),
    );
  }
}

class BatchEvent {
  final String id;
  final String crop;
  final String emoji;
  final DateTime start;
  final DateTime end;
  final String status;
  final int trays;
  final double weight;
  final int targetTemp;

  const BatchEvent({
    required this.id,
    required this.crop,
    required this.emoji,
    required this.start,
    required this.end,
    required this.status,
    required this.trays,
    required this.weight,
    required this.targetTemp,
  });
}