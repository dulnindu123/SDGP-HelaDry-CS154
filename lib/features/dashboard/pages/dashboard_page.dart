import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../services/session_store.dart';
import '../../../app/routes.dart';
import '../../../app/mock_data.dart';
import '../../../widgets/app_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/api_service.dart';
import '../../../app/app_config.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _checkedActive = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only check once per widget lifecycle
    if (!_checkedActive) {
      _checkedActive = true;
      _checkAndSetActiveBatch();
      
      // Also ensure we are listening to metrics if a device is paired
      final session = context.read<SessionStore>();
      if (session.pairedDeviceId.isNotEmpty) {
        session.startListeningToMetrics(session.pairedDeviceId);
      }
    }
  }

  Future<void> _checkAndSetActiveBatch() async {
    final session = context.read<SessionStore>();
    if (session.activeBatch != null) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();
      if (!mounted) return;
      final api = context.read<ApiService>();
      final baseUrl = api.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/session/my-sessions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List sessions = data['data'] ?? [];
        final active = sessions.firstWhere(
          (s) => (s['status'] ?? '') == 'active',
          orElse: () => null,
        );
        if (active != null) {
          session.setActiveBatch(Map<String, dynamic>.from(active));
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = context.watch<SessionStore>();
    final metrics = session.liveMetrics;
    final subtextColor = isDark
        ? const Color(0xFF8892B0)
        : const Color(0xFF64748B);
    final now = DateTime.now();
    final hour = now.hour == 0 ? 12 : (now.hour > 12 ? now.hour - 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final amPm = now.hour >= 12 ? 'PM' : 'AM';
    final syncDateStr = '${now.month}/${now.day}/${now.year} $hour:$minute $amPm';

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Green gradient header
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          const Color(0xFF2D5016),
                          const Color(0xFF1A3A0A),
                          const Color(0xFF0A1628),
                        ]
                      : [
                          const Color(0xFF5B8C2E),
                          const Color(0xFF3D7A1C),
                          const Color(0xFF2D6A12),
                        ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${session.userName}!',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '☀ Solar Dehydrator Dashboard',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.settings,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.settings);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Device status bar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              session.pairedDeviceId.isNotEmpty
                                  ? session.pairedDeviceId
                                  : MockData.defaultDeviceId,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Last sync',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              syncDateStr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        session.connectionMode == 'online'
                            ? 'Online'
                            : 'Offline',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Active Drying Batch
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AppCard(
                padding: const EdgeInsets.all(20),
                child: session.activeBatch == null
                    ? Column(
                        children: [
                          Text(
                            'Active Drying Batch',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFE6F1FF)
                                  : const Color(0xFF1A2D4D),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Icon(
                            Icons.wb_sunny_outlined,
                            size: 48,
                            color: subtextColor.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No active drying batch',
                            style: TextStyle(fontSize: 16, color: subtextColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Start a new batch to begin tracking',
                            style: TextStyle(
                              fontSize: 13,
                              color: subtextColor.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.cropGuide);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark
                                    ? const Color(0xFF1A3A0A)
                                    : const Color(0xFF5B8C2E),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Drying Guide',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.startNewBatch);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark
                                    ? const Color(0xFF1A2D4D)
                                    : const Color(0xFF1976D2),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Start New Batch',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      )
                    : _ActiveBatchTimerCard(
                        batch: session.activeBatch!,
                        isDark: isDark,
                        subtextColor: subtextColor,
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Live Metrics
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Live Metrics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xFFE6F1FF)
                      : const Color(0xFF1A2D4D),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Metrics grid (2 columns)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          Icons.thermostat,
                          'Temperature',
                          session.useCelsius 
                              ? '${(metrics['temperature'] as double).toStringAsFixed(0)}°C'
                              : '${((metrics['temperature'] as double) * 9 / 5 + 32).toStringAsFixed(0)}°F',
                          const Color(0xFFEF5350),
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          Icons.water_drop,
                          'Humidity',
                          '${(metrics['humidity'] as double).toStringAsFixed(0)}%',
                          const Color(0xFF42A5F5),
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          Icons.toys,
                          'Fan Speed',
                          '${metrics['fanSpeed']}%',
                          const Color(0xFF66BB6A),
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          Icons.local_fire_department,
                          'Heater',
                          '${metrics['heaterStatus']}',
                          const Color(0xFFFFA726),
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          Icons.battery_charging_full,
                          'Battery',
                          '${metrics['battery']}V',
                          const Color(0xFF4CAF50),
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          Icons.wb_sunny,
                          'Solar',
                          '${metrics['solarStatus']}',
                          const Color(0xFFFFD54F),
                          isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xFFE6F1FF)
                      : const Color(0xFF1A2D4D),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          context,
                          Icons.play_arrow,
                          'Start New\nBatch',
                          'Begin drying',
                          const Color(0xFF4CAF50),
                          isDark,
                          () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.startNewBatch),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickAction(
                          context,
                          Icons.auto_stories,
                          'Drying Guide',
                          'Crop guidelines',
                          const Color(0xFF1976D2),
                          isDark,
                          () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.cropGuide),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          context,
                          Icons.description,
                          'My Records',
                          'View history',
                          const Color(0xFFFF6B35),
                          isDark,
                          () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.myRecords),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickAction(
                          context,
                          Icons.settings,
                          'Device\nControls',
                          'Manual control',
                          const Color(0xFF7C4DFF),
                          isDark,
                          () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.manualControls),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color iconColor,
    bool isDark,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFF8892B0)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFE6F1FF) : const Color(0xFF1A2D4D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    IconData icon,
    String label,
    String subtitle,
    Color color,
    bool isDark,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.1 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: color.withValues(alpha: 0.2),
          highlightColor: color.withValues(alpha: 0.1),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withValues(alpha: isDark ? 0.4 : 0.2),
                width: 1.5,
              ),
            ),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: isDark ? 0.3 : 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 26),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        height: 1.2,
                        color: isDark
                            ? const Color(0xFFE6F1FF)
                            : const Color(0xFF1A2D4D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF8892B0)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Timer widget for active batch ---

class _ActiveBatchTimerCard extends StatefulWidget {
  final Map<String, dynamic> batch;
  final bool isDark;
  final Color subtextColor;
  const _ActiveBatchTimerCard({required this.batch, required this.isDark, required this.subtextColor});

  @override
  State<_ActiveBatchTimerCard> createState() => _ActiveBatchTimerCardState();
}


class _ActiveBatchTimerCardState extends State<_ActiveBatchTimerCard> {
  late int _durationHours;
  late DateTime _startTime;
  late DateTime _endTime;
  Duration _remaining = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _initTimer() {
    _durationHours = (widget.batch["duration"] is int)
        ? widget.batch["duration"] as int
        : int.tryParse(widget.batch["duration"].toString()) ?? 0;
    // Use start_date or start_time, fallback to now if missing
    final rawStart = widget.batch["start_date"] ?? widget.batch["start_time"] ?? "";
    _startTime = DateTime.tryParse(rawStart) ?? DateTime.now();
    _endTime = _startTime.add(Duration(hours: _durationHours));
    _remaining = _endTime.difference(DateTime.now());
    if (_remaining.isNegative) _remaining = Duration.zero;
  }

  void _onTick() {
    setState(() {
      _remaining = _endTime.difference(DateTime.now());
      if (_remaining.isNegative) _remaining = Duration.zero;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}' ;
  }

  @override
  Widget build(BuildContext context) {
    final batch = widget.batch;
    final isDark = widget.isDark;
    final subtextColor = widget.subtextColor;
    final session = context.watch<SessionStore>();

    return Column(
      children: [
        Text(
          'Active Drying Batch',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFE6F1FF) : const Color(0xFF1A2D4D),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${batch["crop_emoji"] ?? ""}  ${batch["batch_name"] ?? batch["crop_name"] ?? ""}',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFE6F1FF) : const Color(0xFF1A2D4D),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.scale, size: 18, color: subtextColor),
            const SizedBox(width: 4),
            Text(
              '${batch["weight_kg"] ?? "-"} kg',
              style: TextStyle(fontSize: 15, color: subtextColor),
            ),
            const SizedBox(width: 16),
            Icon(Icons.layers, size: 18, color: subtextColor),
            const SizedBox(width: 4),
            Text(
              '${batch["trays"] ?? "-"} trays',
              style: TextStyle(fontSize: 15, color: subtextColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.thermostat, size: 18, color: subtextColor),
            const SizedBox(width: 4),
            Text(
              batch["temperature"] == null 
                  ? "-"
                  : session.useCelsius
                      ? '${batch["temperature"]}°C'
                      : '${((batch["temperature"] is num ? batch["temperature"].toDouble() : double.tryParse(batch["temperature"].toString()) ?? 0.0) * 9 / 5 + 32).round()}°F',
              style: TextStyle(fontSize: 15, color: subtextColor),
            ),
            const SizedBox(width: 16),
            Icon(Icons.timer, size: 18, color: subtextColor),
            const SizedBox(width: 4),
            Text(
              '${batch["duration"] ?? "-"} h',
              style: TextStyle(fontSize: 15, color: subtextColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Started: ${batch["start_date"] != null ? (batch["start_date"] as String).split('T')[0] : '-'}',
          style: TextStyle(fontSize: 13, color: subtextColor.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_bottom, color: Colors.amber, size: 22),
            const SizedBox(width: 6),
            Text(
              _remaining > Duration.zero ? 'Time Left: ${_formatDuration(_remaining)}' : 'Batch Complete!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _remaining > Duration.zero ? Colors.amber : Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF1A2D4D) : const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _remaining > Duration.zero ? 'Batch Running' : 'Batch Complete',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _remaining > Duration.zero ? _handleStopBatch : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Stop',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleStopBatch() async {
    final session = Provider.of<SessionStore>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();
      final deviceId = widget.batch["device_id"];
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/device/stop'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"device_id": deviceId}),
      );
      if (!mounted) return;
      Navigator.pop(context); // Close loader
      if (response.statusCode == 200) {
        session.setActiveBatch(null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Drying Stopped'),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else {
        throw Exception("Failed to stop device");
      }
    } catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stop Error: ${e.toString()}')),
      );
    }
  }
}