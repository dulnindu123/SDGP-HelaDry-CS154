import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/session_store.dart';
import '../../../app/routes.dart';
import '../../../app/mock_data.dart';
import '../../../widgets/app_card.dart';
import '../../../backend/services/live_data_service.dart';
import '../../../backend/services/batch_service.dart';
import 'dart:async';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final LiveDataService _liveDataService = LiveDataService();

  double _temperature = 0.0;
  double _humidity = 0.0;
  int _airflow = 0;
  bool _isLoadingLive = true;

  final BatchService _batchService = BatchService();
  Map<String, dynamic>? _activeBatch;
  bool _isLoadingBatch = true;

  static const String _deviceId = 'device-001';

  @override
  void initState() {
    super.initState();
    try {
      _liveDataService.listenToLiveData(_deviceId).listen((data) {
        if (mounted) {
          setState(() {
            _temperature = data['temperature'] ?? 0.0;
            _humidity = data['humidity'] ?? 0.0;
            _airflow = data['airflow'] ?? 0;
            _isLoadingLive = false;
          });
        }
      });

      _batchService.listenToActiveBatch().listen((batch) {
        if (mounted) {
          setState(() {
            _activeBatch = batch;
            _isLoadingBatch = false;
          });
        }
      });
    } catch (e) {
      debugPrint('Error in initState: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = context.watch<SessionStore>();
    final metrics = MockData.liveMetrics;
    final subtextColor = isDark
        ? const Color(0xFF8892B0)
        : const Color(0xFF64748B);

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
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () {},
                          ),
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
                      color: Colors.white.withOpacity(0.15),
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
                              MockData.lastSyncDate,
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
                child: Column(
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
                    if (_isLoadingBatch)
                      const CircularProgressIndicator()
                    else if (_activeBatch != null) ...[
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 13,
                              color: const Color(0xFF4CAF50),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Crop',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: subtextColor,
                                    ),
                                  ),
                                  Text(
                                    '${_activeBatch!['crop']}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? const Color(0xFFE6F1FF)
                                          : const Color(0xFF1A2D4D),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Weight',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: subtextColor,
                                    ),
                                  ),
                                  Text(
                                    '${_activeBatch!['weight']} kg',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? const Color(0xFFE6F1FF)
                                          : const Color(0xFF1A2D4D),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await _batchService.stopBatch(
                                _activeBatch!['sessionId'],
                              );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Batch stopped successfully! ✅',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Color(0xFF4CAF50),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to stop batch: $e'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
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
                            'Stop Batch',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ] else ...[
                      Icon(
                        Icons.wb_sunny_outlined,
                        size: 48,
                        color: subtextColor.withOpacity(0.5),
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
                          color: subtextColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
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
                    ],
                  ],
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
                          _isLoadingLive
                              ? '--'
                              : '${_temperature.toStringAsFixed(1)}°C',
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
                          _isLoadingLive
                              ? '--'
                              : '${_humidity.toStringAsFixed(1)}%',
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
                          Icons.air,
                          'Airflow',
                          _isLoadingLive ? '--' : '$_airflow',
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
            color: color.withOpacity(isDark ? 0.1 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: color.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: color.withOpacity(0.2),
          highlightColor: color.withOpacity(0.1),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withOpacity(isDark ? 0.4 : 0.2),
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
                        color: color.withOpacity(isDark ? 0.3 : 0.15),
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

class _ActiveBatchTimerCard extends StatefulWidget {
  final Map<String, dynamic> batch;
  final bool isDark;
  final Color subtextColor;
  const _ActiveBatchTimerCard({
    required this.batch;
    required this.isDark,
    required this.subtextColor
  });
@override
  State<_ActiveBatchTimerCard> createState() => _ActiveBatchTimerCardState();
}

class _ActiveBatchTimerCardState extends State<_ActiveBatchTimerCard> {
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
    final durationHours = (widget.batch['durationEstimate'] is int)
        ? widget.batch['durationEstimate'] as int
        : int.tryParse(widget.batch['durationEstimate'].toString()) ?? 0;
    final startTime = widget.batch['startTime'] as int;
    final start = DateTime.fromMillisecondsSinceEpoch(startTime);
    _endTime = start.add(Duration(hours: durationHours));
    _remaining = _endTime.difference(DateTime.now());
    if (_remaining.isNegative) _remaining = Duration.zero;
  }

  void _onTick() {
    setState(() {
      _remaining = _endTime.difference(DateTime.now());
      if (_remaining.isNegative) _remaining = Duration.zero;
    });
  }
  



}
