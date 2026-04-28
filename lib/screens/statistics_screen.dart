import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../services/statistics_service.dart';
import '../l10n/app_localizations.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  DailyStats? _todayStats;
  TotalStats? _totalStats;
  List<DailyStats>? _weekHistory;
  int _safeDistanceScore = 100;
  bool _isLoading = true;
  
  final _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    try {
      final service = await StatisticsService.getInstance();
      final today = await service.getTodayStats();
      final total = service.getTotalStats();
      final history = await service.getWeekHistory();
      final score = await service.getSafeDistanceScore();
      
      setState(() {
        _todayStats = today;
        _totalStats = total;
        _weekHistory = history;
        _safeDistanceScore = score;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _shareStats() async {
    final loc = AppLocalizations.of(context);
    
    try {
      final Uint8List? image = await _screenshotController.capture();
      if (image == null) return;
      
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/keepme_away_stats.png';
      final File imageFile = File(imagePath);
      await imageFile.writeAsBytes(image);
      
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: 'My KeepMe Away Stats - Safe Distance Score: $_safeDistanceScore 📱👀',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc?.translate('failedToShare', params: {'error': '$e'}) ?? 'Failed to share: $e')),
        );
      }
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    if (score >= 20) return Colors.deepOrange;
    return Colors.red;
  }

  String _getScoreEmoji(int score) {
    if (score >= 80) return '🌟';
    if (score >= 60) return '👍';
    if (score >= 40) return '⚠️';
    if (score >= 20) return '😟';
    return '🚨';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('statistics') ?? 'Statistics'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: loc?.translate('shareStats') ?? 'Share Stats',
            onPressed: _shareStats,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Screenshot(
              controller: _screenshotController,
              child: RefreshIndicator(
                onRefresh: _loadStats,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                  Card(
                    elevation: 4,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            _getScoreColor(_safeDistanceScore).withValues(alpha: 0.1),
                            _getScoreColor(_safeDistanceScore).withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _getScoreEmoji(_safeDistanceScore),
                            style: const TextStyle(fontSize: 48),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_safeDistanceScore',
                            style: TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: _getScoreColor(_safeDistanceScore),
                            ),
                          ),
                          Text(
                            loc?.translate('safeDistanceScore') ?? 'Safe Distance Score',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            loc?.translate('safeDistanceScoreDescription') ?? 'Based on warnings per session time',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.today, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                loc?.translate('todayActivity') ?? "Today's Activity",
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _StatBox(
                                  value: '${_todayStats?.warnings ?? 0}',
                                  label: loc?.translate('warnings') ?? 'Warnings',
                                  icon: Icons.warning_amber,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatBox(
                                  value: '${_todayStats?.blocks ?? 0}',
                                  label: loc?.translate('blocks') ?? 'Blocks',
                                  icon: Icons.block,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatBox(
                                  value: '${_todayStats?.sessionMinutes ?? 0}m',
                                  label: loc?.translate('protected') ?? 'Protected',
                                  icon: Icons.shield,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  if (_weekHistory != null && _weekHistory!.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.bar_chart, color: Colors.purple),
                                const SizedBox(width: 8),
                                Text(
                                  loc?.translate('last7Days') ?? 'Last 7 Days',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 120,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: _weekHistory!.map((day) {
                                  final maxWarnings = _weekHistory!
                                      .map((d) => d.warnings)
                                      .reduce((a, b) => a > b ? a : b);
                                  final heightRatio = maxWarnings > 0 
                                      ? day.warnings / maxWarnings 
                                      : 0.0;
                                  
                                  return Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${day.warnings}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          height: 80 * heightRatio + 10,
                                          width: 24,
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withValues(alpha: 0.7),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          day.date.substring(5),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.history, color: Colors.teal),
                              const SizedBox(width: 8),
                              Text(
                                loc?.translate('allTime') ?? 'All Time',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _AllTimeStatRow(
                            icon: Icons.warning_amber,
                            label: loc?.translate('totalWarnings') ?? 'Total Warnings',
                            value: '${_totalStats?.totalWarnings ?? 0}',
                          ),
                          const Divider(),
                          _AllTimeStatRow(
                            icon: Icons.block,
                            label: loc?.translate('totalBlocks') ?? 'Total Blocks',
                            value: '${_totalStats?.totalBlocks ?? 0}',
                          ),
                          const Divider(),
                          _AllTimeStatRow(
                            icon: Icons.timer,
                            label: loc?.translate('totalProtectedTime') ?? 'Total Protected Time',
                            value: _totalStats?.totalSessionTimeFormatted ?? '0h 0m',
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc?.translate('tipsForBetterScore') ?? '💡 Tips for a better score',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loc?.translate('tipsContent') ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _AllTimeStatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AllTimeStatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(label),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
