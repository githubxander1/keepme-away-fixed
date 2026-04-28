import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../utils/prefs.dart';
import '../l10n/app_localizations.dart';
import 'calibration_screen.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with WidgetsBindingObserver {
  bool _cameraPermissionGranted = false;
  bool _overlayPermissionGranted = false;
  bool _isCheckingPermissions = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkInitialState() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (PrefsHelper.getIsCalibrated()) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
          return;
        }
      }
      
      await _checkPermissions();
    });
  }

  Future<void> _checkPermissions() async {
    setState(() => _isCheckingPermissions = true);

    final cameraStatus = await Permission.camera.status;
    _cameraPermissionGranted = cameraStatus.isGranted;

    if (Platform.isAndroid) {
      _overlayPermissionGranted = await _checkOverlayPermission();
    } else {
      _overlayPermissionGranted = true;
    }

    setState(() => _isCheckingPermissions = false);
  }

  Future<bool> _checkOverlayPermission() async {
    try {
      const platform = MethodChannel('protection_service');
      final result = await platform.invokeMethod('checkOverlayPermission');
      return result == true;
    } catch (e) {
      if (kDebugMode) print('Error checking overlay permission: $e');
      return false;
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _cameraPermissionGranted = status.isGranted;
    });
  }

  Future<void> _requestOverlayPermission() async {
    try {
      const platform = MethodChannel('protection_service');
      await platform.invokeMethod('requestOverlayPermission');
      await Future.delayed(const Duration(seconds: 1));
      _overlayPermissionGranted = await _checkOverlayPermission();
      setState(() {});
    } catch (e) {
      if (kDebugMode) print('Error requesting overlay permission: $e');
    }
  }

  Future<void> _requestBatteryOptimization() async {
    if (!Platform.isAndroid) return;
    
    try {
      const platform = MethodChannel('protection_service');
      await platform.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (e) {
      if (kDebugMode) print('Error requesting battery optimization: $e');
    }
  }

  void _navigateToCalibration() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const CalibrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    if (_isCheckingPermissions) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('appTitleSetup') ?? 'KeepMe Away Setup'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc?.translate('welcome') ?? 'Welcome to KeepMe Away',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              loc?.translate('welcomeDescription') ?? '',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 32),
            Text(
              loc?.translate('requiredPermissions') ?? 'Required Permissions:',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            _buildPermissionTile(
              title: loc?.translate('cameraPermission') ?? 'Camera',
              description: loc?.translate('cameraPermissionDescription') ?? '',
              isGranted: _cameraPermissionGranted,
              onRequest: _requestCameraPermission,
              grantText: loc?.translate('grantPermission') ?? 'Grant',
            ),
            
            if (Platform.isAndroid)
              _buildPermissionTile(
                title: loc?.translate('overlayPermission') ?? 'Overlay',
                description: loc?.translate('overlayPermissionDescription') ?? '',
                isGranted: _overlayPermissionGranted,
                onRequest: _requestOverlayPermission,
                grantText: loc?.translate('grantPermission') ?? 'Grant',
              ),
            
            const SizedBox(height: 32),
            
            if (Platform.isAndroid) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.battery_saver),
                  title: Text(loc?.translate('batteryOptimization') ?? 'Battery Optimization'),
                  subtitle: Text(loc?.translate('batteryOptimizationDescription') ?? ''),
                  trailing: ElevatedButton(
                    onPressed: _requestBatteryOptimization,
                    child: Text(loc?.translate('settingsButton') ?? 'Settings'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canContinue() ? _navigateToCalibration : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  loc?.translate('continueCalibration') ?? 'Continue to Calibration',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onRequest,
    required String grantText,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(
          isGranted ? Icons.check_circle : Icons.warning,
          color: isGranted ? Colors.green : Colors.orange,
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: isGranted
            ? const Icon(Icons.done, color: Colors.green)
            : ElevatedButton(
                onPressed: onRequest,
                child: Text(grantText),
              ),
      ),
    );
  }

  bool _canContinue() {
    if (Platform.isAndroid) {
      return _cameraPermissionGranted && _overlayPermissionGranted;
    } else {
      return _cameraPermissionGranted;
    }
  }
}
