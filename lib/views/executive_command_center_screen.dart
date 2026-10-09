import 'package:flutter/material.dart';
import '../services/executive_command_center_service.dart';
import '../core/design_system/design_system.dart';

class ExecutiveCommandCenterScreen extends StatefulWidget {
  final ExecutiveCockpitMetrics? metrics;
  final String? enterpriseId;
  final VoidCallback? onRefresh;

  const ExecutiveCommandCenterScreen({
    super.key,
    this.metrics,
    this.enterpriseId,
    this.onRefresh,
  });

  @override
  State<ExecutiveCommandCenterScreen> createState() => _ExecutiveCommandCenterScreenState();
}

class _ExecutiveCommandCenterScreenState extends State<ExecutiveCommandCenterScreen> {
  ExecutiveCockpitMetrics? _currentMetrics;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentMetrics = widget.metrics;
    if (_currentMetrics == null || widget.enterpriseId != null) {
      _fetchLiveMetrics();
    }
  }

  Future<void> _fetchLiveMetrics() async {
    final entId = widget.enterpriseId ?? _currentMetrics?.enterpriseId;
    if (entId == null || entId.isEmpty) return;

    if (mounted) setState(() => _isLoading = true);
    try {
      final live = await ExecutiveCommandCenterService().fetchLiveMetrics(entId);
      if (mounted) {
        setState(() {
          _currentMetrics = live;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching live cockpit metrics: $e');
      if (mounted) setState(() => _isLoading = false);
    }
    widget.onRefresh?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final entId = widget.enterpriseId ?? _currentMetrics?.enterpriseId ?? 'Enterprise';

    if (_isLoading && _currentMetrics == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Executive Cockpit: $entId',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final metrics = _currentMetrics ?? ExecutiveCommandCenterService().synthesizeMetrics(
      enterpriseId: entId,
      totalTerminals: 0,
      onlineTerminals: 0,
      totalEmployees: 0,
      onSiteEmployees: 0,
      punchesLastHour: 0,
      pendingRegularizations: 0,
      tamperAlerts: 0,
    );

    final isHealthy = metrics.isFleetHealthy;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Executive Cockpit: ${metrics.enterpriseId}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: IconButton(
              icon: _isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded),
              onPressed: _isLoading ? null : _fetchLiveMetrics,
              tooltip: 'Refresh Cockpit',
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchLiveMetrics,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Top Status Hero Banner
              Card(
                elevation: 0,
                color: isHealthy
                    ? Colors.green.withValues(alpha: 0.1)
                    : colors.error.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isHealthy ? Colors.green.shade400 : colors.error,
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        isHealthy ? Icons.shield_rounded : Icons.warning_rounded,
                        color: isHealthy ? Colors.green.shade700 : colors.error,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isHealthy ? 'Fleet Fully Operational' : 'Fleet Attention Required',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isHealthy ? Colors.green.shade900 : colors.error,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Uptime: ${metrics.fleetUptimePercentage.toStringAsFixed(1)}% • ${metrics.onlineTerminals}/${metrics.totalTerminals} Terminals Online',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 4 KPI Summary Metric Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 600;
                  final crossAxisCount = isWide ? 4 : 2;

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.5,
                    children: [
                      _buildKpiTile(
                        context,
                        title: 'On-Site Staff',
                        value: '${metrics.currentlyOnSiteCount}',
                        subtitle: 'of ${metrics.totalEnrolledEmployees} staff',
                        icon: Icons.people_alt_rounded,
                        accentColor: Colors.blueAccent,
                      ),
                      _buildKpiTile(
                        context,
                        title: 'Punch Velocity',
                        value: '${metrics.activePunchesLastHour}',
                        subtitle: 'punches in last hr',
                        icon: Icons.speed_rounded,
                        accentColor: Colors.teal,
                      ),
                      _buildKpiTile(
                        context,
                        title: 'Pending Approvals',
                        value: '${metrics.pendingRegularizations}',
                        subtitle: 'requires admin action',
                        icon: Icons.assignment_late_rounded,
                        accentColor: metrics.pendingRegularizations > 0 ? Colors.orange : Colors.grey,
                      ),
                      _buildKpiTile(
                        context,
                        title: 'Tamper Alerts',
                        value: '${metrics.activeTamperAlerts}',
                        subtitle: 'hardware anomalies',
                        icon: Icons.warning_amber_rounded,
                        accentColor: metrics.activeTamperAlerts > 0 ? colors.error : Colors.green,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),

              // Detailed Biometric Confidence Metric
              Card(
                elevation: 0,
                color: colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.6)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.face_retouching_natural_rounded, size: 18, color: colors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Average Recognition Confidence',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: colors.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(metrics.averageRecognitionConfidence * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: metrics.averageRecognitionConfidence,
                        backgroundColor: colors.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 6,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Telemetry Aggregation Timestamp
              Center(
                child: Text(
                  'Last Live Refresh: ${metrics.aggregatedAt.toLocal().toString().split('.').first}',
                  style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiTile(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    final colors = context.colors;

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: accentColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: colors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
