import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../services/session_store.dart';

class MyRecordsPage extends StatefulWidget {
  const MyRecordsPage({super.key});

  @override
  State<MyRecordsPage> createState() => _MyRecordsPageState();
}

class _MyRecordsPageState extends State<MyRecordsPage> {
  String _filter = 'All';
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecords() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();
      final response = await http.get(
        Uri.parse('http://172.30.161.140:5000/session/my-sessions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List sessions = data['data'] ?? [];
        _records = List<Map<String, dynamic>>.from(sessions);
        setState(() {
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _error = 'Failed to fetch records ({response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Error: $e';
      });
    }
  }

  List<Map<String, dynamic>> get _filteredRecords {
    var records = _records.toList();

    // Apply status filter
    if (_filter == 'Active') {
      records = records.where((r) => (r['status'] ?? '') == 'active').toList();
    } else if (_filter == 'Completed') {
      records = records
          .where((r) => (r['status'] ?? '') == 'completed')
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      records = records
          .where(
            (r) =>
                (r['crop_name'] ?? '').toString().toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (r['batch_name'] ?? '').toString().toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    // Sort: Active first, then by date (latest first)
    records.sort((a, b) {
      // First, sort by status (active status = 0, completed status = 1)
      final statusA = (a['status'] ?? '') == 'active' ? 0 : 1;
      final statusB = (b['status'] ?? '') == 'active' ? 0 : 1;

      if (statusA != statusB) {
        return statusA.compareTo(statusB);
      }

      // Then sort by date (latest first) - use end_date for completed, start_date for active
      final dateFieldA = (a['status'] == 'active')
          ? (a['start_date'] ?? a['start_time'])
          : (a['end_date'] ?? a['end_time']);
      final dateFieldB = (b['status'] == 'active')
          ? (b['start_date'] ?? b['start_time'])
          : (b['end_date'] ?? b['end_time']);

      final dateA =
          DateTime.tryParse(dateFieldA?.toString() ?? '') ?? DateTime(2000);
      final dateB =
          DateTime.tryParse(dateFieldB?.toString() ?? '') ?? DateTime(2000);

      return dateB.compareTo(dateA); // Descending order (latest first)
    });

    return records;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = context.watch<SessionStore>();

    final records = _filteredRecords;
    final totalBatches = _records.length;
    final activeBatches = _records
        .where((r) => (r['status'] ?? '') == 'active')
        .length;
    final completedBatches = _records
        .where((r) => (r['status'] ?? '') == 'completed')
        .length;
    final totalDried = _records.fold<double>(
      0,
      (sum, r) =>
          sum +
          ((r['weight_kg'] ?? 0) is num
              ? (r['weight_kg'] ?? 0).toDouble()
              : 0.0),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Records'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRecords,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : Column(
              children: [
                // Purple gradient header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 12,
                    left: 20,
                    right: 20,
                    bottom: 20,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF6B21A8)],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'My Records',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'View all drying batches',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Stats row
                      Row(
                        children: [
                          _buildStatCard('Total Batches', '$totalBatches'),
                          const SizedBox(width: 12),
                          _buildStatCard('Active', '$activeBatches'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatCard('Completed', '$completedBatches'),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            'Total Dried',
                            '${totalDried.toStringAsFixed(1)}kg',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Search
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search by crop or batch name...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                // Filter tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: ['All', 'Active', 'Completed'].map((tab) {
                      final isActive = _filter == tab;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _filter = tab),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isActive
                                      ? (isDark
                                            ? const Color(0xFF00D4AA)
                                            : const Color(0xFF1976D2))
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              tab,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isActive
                                    ? (isDark
                                          ? const Color(0xFFE6F1FF)
                                          : const Color(0xFF1A2D4D))
                                    : (isDark
                                          ? const Color(0xFF8892B0)
                                          : const Color(0xFF64748B)),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Records list
                Expanded(
                  child: records.isEmpty
                      ? Center(
                          child: Text(
                            'No batches found',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark
                                  ? const Color(0xFF8892B0)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: records.length,
                          itemBuilder: (ctx, i) =>
                              _buildRecordItem(records[i], isDark, session),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordItem(Map<String, dynamic> record, bool isDark, SessionStore session) {
    final isActive = (record['status'] ?? '') == 'active';

    // Helper to format date/time
    String formatDateTime(String? raw) {
      if (raw == null || raw.isEmpty) return '';
      DateTime? parsed;
      try {
        parsed = DateTime.tryParse(raw)?.toLocal();
      } catch (_) {
        parsed = null;
      }
      if (parsed != null) {
        return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year} at '
            '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
      }
      return raw;
    }

    final rawStart = record['start_date'] ?? record['start_time'] ?? '';
    final rawEnd = record['end_date'] ?? record['end_time'] ?? '';
    final startDisplay = formatDateTime(rawStart);
    final endDisplay = formatDateTime(rawEnd);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF112240) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE0E6ED),
        ),
      ),
      child: Row(
        children: [
          Text(
            (record['crop_emoji'] ?? '🌾').toString(),
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (record['batch_name'] ?? record['crop_name'] ?? 'Unknown')
                      .toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${record['weight_kg'] ?? 0}kg  •  ${record['trays'] ?? 0} trays  •  ${
                    record['target_temperature'] == null
                        ? '0°C'
                        : session.useCelsius
                            ? '${record['target_temperature']}°C'
                            : '${((record['target_temperature'] is num ? record['target_temperature'].toDouble() : double.tryParse(record['target_temperature'].toString()) ?? 0.0) * 9 / 5 + 32).round()}°F'
                  }',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF8892B0)
                        : const Color(0xFF64748B),
                  ),
                ),
                if (startDisplay.isNotEmpty)
                  Text(
                    'Started: $startDisplay',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF8892B0)
                          : const Color(0xFF64748B),
                    ),
                  ),
                if (!isActive && endDisplay.isNotEmpty)
                  Text(
                    'Ended: $endDisplay',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFFB088F9)
                          : const Color(0xFF6B21A8),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF4CAF50).withOpacity(0.15)
                  : const Color(0xFF42A5F5).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isActive ? 'Active' : 'Done',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF42A5F5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
