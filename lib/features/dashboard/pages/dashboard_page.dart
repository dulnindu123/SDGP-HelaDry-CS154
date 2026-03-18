import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/session_store.dart';
import '../../../app/routes.dart';
import '../../../app/mock_data.dart';
import '../../../widgets/app_card.dart';
import '../../../backend/services/device_link_service.dart';
import '../../../backend/services/batch_service.dart';

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
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.3 : 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDark
                    ? const Color(0xFFE6F1FF)
                    : const Color(0xFF1A2D4D),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
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
    );
  }
}
