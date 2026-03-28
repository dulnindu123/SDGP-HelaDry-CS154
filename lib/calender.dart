import 'package:flutter/material.dart';

// COMMIT MESSAGE: feat: add CalendarPage stateful widget scaffold

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

  final List<BatchEvent> _events = [];

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