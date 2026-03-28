import 'package:flutter/material.dart';

// COMMIT MESSAGE: feat: register calendar route and wire dashboard button

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
    BatchEvent(id: 'BATCH-001', crop: 'Mango', emoji: '🥭', start: DateTime.now().subtract(const Duration(days: 14)), end: DateTime.now().subtract(const Duration(days: 12)), status: 'Completed', trays: 4, weight: 5.0, targetTemp: 60),
    BatchEvent(id: 'BATCH-002', crop: 'Tomato', emoji: '🍅', start: DateTime.now().subtract(const Duration(days: 8)), end: DateTime.now().subtract(const Duration(days: 7)), status: 'Completed', trays: 3, weight: 3.5, targetTemp: 55),
    BatchEvent(id: 'BATCH-003', crop: 'Banana', emoji: '🍌', start: DateTime.now().subtract(const Duration(days: 4)), end: DateTime.now().subtract(const Duration(days: 3)), status: 'Completed', trays: 5, weight: 4.2, targetTemp: 58),
    BatchEvent(id: 'BATCH-004', crop: 'Chili', emoji: '🌶️', start: DateTime.now().subtract(const Duration(days: 1)), end: DateTime.now().add(const Duration(hours: 10)), status: 'Active', trays: 2, weight: 1.8, targetTemp: 50),
    BatchEvent(id: 'BATCH-005', crop: 'Jackfruit', emoji: '🍈', start: DateTime.now().add(const Duration(days: 2)), end: DateTime.now().add(const Duration(days: 4)), status: 'Scheduled', trays: 6, weight: 7.0, targetTemp: 55),
  ];


  List<BatchEvent> _eventsForDay(DateTime day) {
    return _events.where((e) {
      final s  = DateTime(e.start.year, e.start.month, e.start.day);
      final en = DateTime(e.end.year,   e.end.month,   e.end.day);
      final d  = DateTime(day.year,     day.month,     day.day);
      return !d.isBefore(s) && !d.isAfter(en);
    }).toList();
  }

  bool _hasEvent(DateTime day) => _eventsForDay(day).isNotEmpty;
  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  String _formatDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '\${d.day} \${m[d.month - 1]} \${d.year}';
  }
  String _formatDuration(Duration d) => d.inHours >= 1 ? '\${d.inHours}h \${d.inMinutes.remainder(60)}m' : '\${d.inMinutes}m';

  int get _monthBatchCount => _events.where((e) =>
  (e.start.month == _focusedMonth.month && e.start.year == _focusedMonth.year) ||
      (e.end.month   == _focusedMonth.month && e.end.year   == _focusedMonth.year)
  ).length;

  void _prevMonth() => setState(() { _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1); _selectedDay = null; });
  void _nextMonth() => setState(() { _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1); _selectedDay = null; });

  List<BatchEvent> get _selectedEvents {
    if (_selectedDay == null) return [];
    final dayEvents = _eventsForDay(_selectedDay!);
    if (_filterStatus == 'All') return dayEvents;
    return dayEvents.where((e) => e.status == _filterStatus).toList();
  }


  Color _accent(bool isDark)   => isDark ? const Color(0xFF22D3EE) : const Color(0xFF0EA5E9);
  Color _surface(bool isDark)  => isDark ? const Color(0xFF111827) : const Color(0xFFFFFFFF);
  Color _surface2(bool isDark) => isDark ? const Color(0xFF162033) : const Color(0xFFF6F8FC);
  Color _border(bool isDark)   => isDark ? const Color(0xFF22304A) : const Color(0xFFD8E2F0);
  Color _subtext(bool isDark)  => isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
  Color _text(bool isDark)     => isDark ? Colors.white            : const Color(0xFF0F172A);
  Color _statusColor(String s) {
    if (s == 'Active')    return const Color(0xFF34D399);
    if (s == 'Scheduled') return const Color(0xFF22D3EE);
    return const Color(0xFF94A3B8);
  }


  AppBar _buildAppBar(bool isDark) => AppBar(
    backgroundColor: Colors.transparent, elevation: 0,
    leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
    title: const Text('Batch Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
    actions: [IconButton(icon: const Icon(Icons.today_rounded), tooltip: 'Go to today',
        onPressed: () => setState(() { _focusedMonth = DateTime.now(); _selectedDay = DateTime.now(); }))],
  );


  Widget _buildMonthHeader(bool isDark) {
    const names = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(icon: Icon(Icons.chevron_left, color: _accent(isDark)), onPressed: _prevMonth),
          Expanded(
            child: Column(children: [
              Text('\${names[_focusedMonth.month - 1]} \${_focusedMonth.year}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _text(isDark))),
              const SizedBox(height: 2),
              Text('\$_monthBatchCount batch\${_monthBatchCount == 1 ? \"\" : \"es\"} this month',
                  style: TextStyle(fontSize: 12, color: _subtext(isDark))),
            ]),
          ),
          IconButton(icon: Icon(Icons.chevron_right, color: _accent(isDark)), onPressed: _nextMonth),
        ],
      ),
    );
  }


  Widget _buildWeekdayLabels(bool isDark) {
    const days = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: days.map((d) => Expanded(
          child: Center(child: Text(d, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _subtext(isDark)))),
        )).toList(),
      ),
    );
  }


  Widget _buildCalendarGrid(bool isDark) {
    final firstDay    = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startOffset = firstDay.weekday % 7;
    final rows = ((startOffset + daysInMonth) / 7).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: List.generate(rows, (row) => Row(
          children: List.generate(7, (col) {
            final dayNum = row * 7 + col - startOffset + 1;
            if (dayNum < 1 || dayNum > daysInMonth) return const Expanded(child: SizedBox(height: 44));
            final day        = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
            final isToday    = _isSameDay(day, DateTime.now());
            final isSelected = _selectedDay != null && _isSameDay(day, _selectedDay!);
            final dayEvents  = _eventsForDay(day);
            final hasEvent   = dayEvents.isNotEmpty;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedDay = day),
                child: Container(
                  height: 44, margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected ? _accent(isDark) : isToday ? _accent(isDark).withOpacity(0.18) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: isToday && !isSelected ? Border.all(color: _accent(isDark), width: 1.5) : null,
                  ),
                  child: Stack(alignment: Alignment.center, children: [
                    Text('\$dayNum', style: TextStyle(
                      fontSize: 14,
                      fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? (isDark ? const Color(0xFF0B1120) : Colors.white) : _text(isDark),
                    )),
                    if (hasEvent && !isSelected)
                      Positioned(
                        bottom: 5,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: dayEvents.take(2).map((e) => Container(
                            width: 5, height: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(color: _statusColor(e.status), shape: BoxShape.circle),
                          )).toList(),
                        ),
                      ),
                  ]),
                ),
              ),
            );
          }),
        )),
      ),
    );
  }

  Widget _buildFilterRow(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: _filterOptions.map((f) {
          final isSelected = _filterStatus == f;
          return GestureDetector(
            onTap: () => setState(() => _filterStatus = f),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? _accent(isDark) : _surface2(isDark),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? _accent(isDark) : _border(isDark)),
              ),
              child: Text(f, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: isSelected ? (isDark ? const Color(0xFF0B1120) : Colors.white) : _subtext(isDark),
              )),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEventList(bool isDark) {
    if (_selectedDay == null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.touch_app_rounded, size: 40, color: _subtext(isDark).withOpacity(0.4)),
        const SizedBox(height: 12),
        Text('Tap a day to see batches', style: TextStyle(color: _subtext(isDark), fontSize: 14)),
      ]));
    }
    if (_selectedEvents.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.event_busy_rounded, size: 40, color: _subtext(isDark).withOpacity(0.4)),
        const SizedBox(height: 12),
        Text('No batches on this day', style: TextStyle(color: _subtext(isDark), fontSize: 14)),
      ]));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(_formatDate(_selectedDay!), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _subtext(isDark))),
        ),
        ..._selectedEvents.map((e) => _buildEventCard(e, isDark)),
      ],
    );
  }

  Widget _buildEventCard(BatchEvent e, bool isDark) {
    final statusColor = _statusColor(e.status);
    final isActive    = e.status == 'Active';
    final remaining   = e.end.difference(DateTime.now());
    final total       = e.end.difference(e.start).inMinutes;
    final elapsed     = DateTime.now().difference(e.start).inMinutes;
    final progress    = isActive ? (elapsed / total).clamp(0.0, 1.0) : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border(isDark)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(e.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('\${e.crop}  •  \${e.id}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _text(isDark))),
            Text('\${e.trays} trays  •  \${e.weight}kg  •  \${e.targetTemp}°C', style: TextStyle(fontSize: 12, color: _subtext(isDark))),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(e.status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
        if (isActive) ...[
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Progress', style: TextStyle(fontSize: 12, color: _subtext(isDark))),
            Text('\${(progress * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, color: _accent(isDark), fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: _border(isDark), valueColor: AlwaysStoppedAnimation<Color>(_accent(isDark))),
          ),
          const SizedBox(height: 6),
          Text(
            remaining.isNegative ? 'Overdue — check device' : 'Ends in \${_formatDuration(remaining)}',
            style: TextStyle(fontSize: 12, color: remaining.isNegative ? const Color(0xFFEF4444) : _accent(isDark), fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Icon(Icons.play_arrow_rounded, size: 14, color: _subtext(isDark)),
          const SizedBox(width: 4),
          Text(_formatDate(e.start), style: TextStyle(fontSize: 12, color: _subtext(isDark))),
          const SizedBox(width: 12),
          Icon(Icons.stop_rounded, size: 14, color: _subtext(isDark)),
          const SizedBox(width: 4),
          Text(_formatDate(e.end), style: TextStyle(fontSize: 12, color: _subtext(isDark))),
        ]),
      ]),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF6F8FC),
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          _buildMonthHeader(isDark),
          _buildWeekdayLabels(isDark),
          _buildCalendarGrid(isDark),
          Divider(height: 1, color: _border(isDark)),
          _buildFilterRow(isDark),
          Expanded(child: _buildEventList(isDark)),
        ],
      ),
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
  const BatchEvent({required this.id, required this.crop, required this.emoji, required this.start, required this.end, required this.status, required this.trays, required this.weight, required this.targetTemp});
}