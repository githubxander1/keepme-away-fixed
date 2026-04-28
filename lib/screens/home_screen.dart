import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import '../services/protection_service.dart';
import '../utils/prefs.dart';
import '../utils/page_transitions.dart';
import '../l10n/app_localizations.dart';
import 'calibration_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isProtectionActive = false;
  bool _isLoading = false;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _checkProtectionStatus();
    _startStatusUpdates();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _startStatusUpdates() {
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkProtectionStatus();
    });
  }

  Future<void> _checkProtectionStatus() async {
    if (Platform.isAndroid) {
      final isRunning = await ProtectionService.isRunning();
      if (mounted) {
        setState(() {
          _isProtectionActive = isRunning;
        });
        
        PrefsHelper.setIsProtectionActive(isRunning);
      }
    }
  }

  Future<void> _toggleProtection() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    final loc = AppLocalizations.of(context);

    try {
      if (_isProtectionActive) {
        final success = await ProtectionService.stop();
        if (success) {
          await PrefsHelper.setIsProtectionActive(false);
          setState(() => _isProtectionActive = false);
          _showSnackBar(loc?.translate('protectionStopped') ?? 'Protection stopped');
        } else {
          _showSnackBar(loc?.translate('failedToStopProtection') ?? 'Failed to stop protection');
        }
      } else {
        final success = await ProtectionService.start(
          baselineArea: PrefsHelper.getBaselineArea(),
          thresholdFactor: PrefsHelper.getThresholdFactor(),
          hysteresisGap: PrefsHelper.getHysteresisGap(),
          warningTime: PrefsHelper.getWarningTime(),
          detectionThreshold: PrefsHelper.getDetectionThreshold(),
        );
        
        if (success) {
          await PrefsHelper.setIsProtectionActive(true);
          setState(() => _isProtectionActive = true);
          _showSnackBar(loc?.translate('protectionStarted') ?? 'Protection started');
        } else {
          _showSnackBar(loc?.translate('failedToStartProtection') ?? 'Failed to start protection');
        }
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _navigateToCalibration() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CalibrationScreen()),
    );
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      PageTransitions.slideFromRight(const SettingsScreen()),
    );
  }

  void _navigateToStatistics() {
    Navigator.of(context).push(
      PageTransitions.fadeScale(const StatisticsScreen()),
    );
  }

  Future<void> _resetCalibration() async {
    final loc = AppLocalizations.of(context);
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc?.translate('resetConfirmation') ?? 'Reset Calibration'),
        content: Text(loc?.translate('resetMessage') ?? 'This will clear your current calibration and stop protection. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc?.translate('cancel') ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc?.translate('reset') ?? 'Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ProtectionService.stop();
      await PrefsHelper.clearCalibration();
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const CalibrationScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final baseline = PrefsHelper.getBaselineArea();
    final isCalibrated = PrefsHelper.getIsCalibrated();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('appTitle') ?? 'KeepMe Away'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _navigateToStatistics,
            icon: const Icon(Icons.bar_chart),
            tooltip: loc?.translate('statistics') ?? 'Statistics',
          ),
          IconButton(
            onPressed: _navigateToSettings,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isProtectionActive ? Icons.shield : Icons.shield_outlined,
                          color: _isProtectionActive ? Colors.green : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc?.translate('protectionStatus') ?? 'Protection Status',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              _isProtectionActive 
                                  ? (loc?.translate('active') ?? 'Active') 
                                  : (loc?.translate('inactive') ?? 'Inactive'),
                              style: TextStyle(
                                color: _isProtectionActive ? Colors.green : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    if (_isProtectionActive) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          loc?.translate('protectionActiveMessage') ?? 'Your screen is being protected. You can minimize the app.',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc?.translate('calibrationInfo') ?? 'Calibration Info',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('${loc?.translate('calibrated') ?? 'Calibrated'}: ${isCalibrated ? (loc?.translate('yes') ?? 'Yes') : (loc?.translate('no') ?? 'No')}'),
                    if (isCalibrated) ...[
                      Text('${loc?.translate('baselineArea') ?? 'Baseline Area'}: ${baseline.toStringAsFixed(4)}'),
                      Text('${loc?.translate('thresholdFactor') ?? 'Threshold Factor'}: ${PrefsHelper.getThresholdFactor()}'),
                      Text('${loc?.translate('warningTime') ?? 'Warning Time'}: ${PrefsHelper.getWarningTime()}s'),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _toggleProtection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isProtectionActive ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _isProtectionActive 
                            ? (loc?.translate('stopProtection') ?? 'Stop Protection') 
                            : (loc?.translate('startProtection') ?? 'Start Protection'),
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _navigateToCalibration,
                    child: Text(loc?.translate('recalibrate') ?? 'Recalibrate'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetCalibration,
                    child: Text(loc?.translate('reset') ?? 'Reset'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc?.translate('howItWorks') ?? 'How it works:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc?.translate('howItWorksContent') ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (Platform.isAndroid) ...[
                    const SizedBox(height: 8),
                    Text(
                      loc?.translate('protectionRunningNote') ?? '',
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
