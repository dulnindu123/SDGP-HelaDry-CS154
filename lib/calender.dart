import 'package:flutter/material.dart';

// COMMIT MESSAGE: feat: add status colour helper for batch states

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

  List<BatchEvent> _eventsForDay(DateTime day) {
    return _events.where((e) {
      final start = DateTime(e.start.year, e.start.month, e.start.day);
      final end = DateTime(e.end.year, e.end.month, e.end.day);
      final d = DateTime(day.year, day.month, day.day);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }

  bool _hasEvent(DateTime day) => _eventsForDay(day).isNotEmpty;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _formatDuration(Duration d) {
    if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return '${d.inMinutes}m';
  }

  Color _accent(bool isDark) =>
      isDark ? const Color(0xFF22D3EE) : const Color(0xFF0EA5E9);
  Color _surface(bool isDark) =>
      isDark ? const Color(0xFF111827) : const Color(0xFFFFFFFF);
  Color _surface2(bool isDark) =>
      isDark ? const Color(0xFF162033) : const Color(0xFFF6F8FC);
  Color _border(bool isDark) =>
      isDark ? const Color(0xFF22304A) : const Color(0xFFD8E2F0);
  Color _subtext(bool isDark) =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
  Color _text(bool isDark) =>
      isDark ? Colors.white : const Color(0xFF0F172A);

  Color _statusColor(String status) {
    switch (status) {
      case 'Active':    return const Color(0xFF34D399);
      case 'Scheduled': return const Color(0xFF22D3EE);
      default:          return const Color(0xFF94A3B8);
    }
  }

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