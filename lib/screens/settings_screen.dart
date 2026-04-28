import 'package:flutter/material.dart';
import '../utils/prefs.dart';
import '../utils/language_provider.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _thresholdFactor;
  late double _hysteresisGap;
  late int _warningTime;
  late double _detectionThreshold;
  
  late bool _scheduledEnabled;
  late int _scheduleStartHour;
  late int _scheduleEndHour;
  
  late bool _hapticsEnabled;
  late bool _soundEnabled;
  late bool _breakReminderEnabled;
  late int _breakReminderInterval;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _thresholdFactor = PrefsHelper.getThresholdFactor();
    _hysteresisGap = PrefsHelper.getHysteresisGap();
    _warningTime = PrefsHelper.getWarningTime();
    _detectionThreshold = PrefsHelper.getDetectionThreshold();
    _scheduledEnabled = PrefsHelper.getScheduledEnabled();
    _scheduleStartHour = PrefsHelper.getScheduleStartHour();
    _scheduleEndHour = PrefsHelper.getScheduleEndHour();
    _hapticsEnabled = PrefsHelper.getHapticsEnabled();
    _soundEnabled = PrefsHelper.getSoundEnabled();
    _breakReminderEnabled = PrefsHelper.getBreakReminderEnabled();
    _breakReminderInterval = PrefsHelper.getBreakReminderInterval();
  }

  Future<void> _saveSettings() async {
    await PrefsHelper.setThresholdFactor(_thresholdFactor);
    await PrefsHelper.setHysteresisGap(_hysteresisGap);
    await PrefsHelper.setWarningTime(_warningTime);
    await PrefsHelper.setDetectionThreshold(_detectionThreshold);
    await PrefsHelper.setScheduledEnabled(_scheduledEnabled);
    await PrefsHelper.setScheduleStartHour(_scheduleStartHour);
    await PrefsHelper.setScheduleEndHour(_scheduleEndHour);
    await PrefsHelper.setHapticsEnabled(_hapticsEnabled);
    await PrefsHelper.setSoundEnabled(_soundEnabled);
    await PrefsHelper.setBreakReminderEnabled(_breakReminderEnabled);
    await PrefsHelper.setBreakReminderInterval(_breakReminderInterval);
    
    final loc = AppLocalizations.of(context);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc?.translate('settingsSaved') ?? 'Settings saved')),
      );
    }
  }

  void _resetToDefaults() {
    setState(() {
      _thresholdFactor = 1.6;
      _hysteresisGap = 0.15;
      _warningTime = 3;
      _detectionThreshold = 0.5;
      _scheduledEnabled = false;
      _scheduleStartHour = 9;
      _scheduleEndHour = 21;
    });
  }

  String _formatHour(int hour) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final ampm = hour < 12 ? 'AM' : 'PM';
    return '$h:00 $ampm';
  }

  void _changeLanguage(Locale? locale) async {
    if (locale != null) {
      ScreenProtectorApp.setLocale(context, locale);
      setState(() {});
    } else {
      await LanguageProvider.clearLocale();
      ScreenProtectorApp.setLocale(context, const Locale('en'));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('settings') ?? 'Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(loc?.translate('save') ?? 'Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        loc?.translate('appearance') ?? 'Appearance',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      ScreenProtectorApp.getThemeMode(context) == ThemeMode.dark
                          ? Icons.dark_mode
                          : ScreenProtectorApp.getThemeMode(context) == ThemeMode.light
                              ? Icons.light_mode
                              : Icons.brightness_auto,
                    ),
                    title: Text(loc?.translate('theme') ?? 'Theme'),
                    subtitle: Text(loc?.translate('chooseAppearance') ?? 'Choose your preferred appearance'),
                    trailing: DropdownButton<ThemeMode>(
                      value: ScreenProtectorApp.getThemeMode(context),
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(value: ThemeMode.system, child: Text(loc?.translate('system') ?? 'System')),
                        DropdownMenuItem(value: ThemeMode.light, child: Text(loc?.translate('light') ?? 'Light')),
                        DropdownMenuItem(value: ThemeMode.dark, child: Text(loc?.translate('dark') ?? 'Dark')),
                      ],
                      onChanged: (mode) {
                        if (mode != null) {
                          ScreenProtectorApp.setThemeMode(context, mode);
                          setState(() {});
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.language),
                    title: Text(loc?.translate('language') ?? 'Language'),
                    subtitle: Text(loc?.translate('chooseAppearance') ?? 'Choose your preferred language'),
                    trailing: DropdownButton<String>(
                      value: ScreenProtectorApp.getLocale(context)?.languageCode ?? 'system',
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(value: 'system', child: Text(loc?.translate('systemLanguage') ?? 'System Language')),
                        DropdownMenuItem(value: 'en', child: Text(loc?.translate('english') ?? 'English')),
                        DropdownMenuItem(value: 'zh', child: Text(loc?.translate('chinese') ?? '中文')),
                      ],
                      onChanged: (code) {
                        if (code != null) {
                          if (code == 'system') {
                            _changeLanguage(null);
                          } else {
                            _changeLanguage(Locale(code));
                          }
                        }
                      },
                    ),
                  ),
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
                    loc?.translate('detectionSettings') ?? 'Detection Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    '${loc?.translate('thresholdFactor') ?? 'Threshold Factor'}: ${_thresholdFactor.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    loc?.translate('thresholdFactorDescription') ?? 'Higher values = need to be closer to trigger (less sensitive)',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Slider(
                    value: _thresholdFactor,
                    min: 1.2,
                    max: 2.5,
                    divisions: 26,
                    onChanged: (value) {
                      setState(() => _thresholdFactor = value);
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    '${loc?.translate('hysteresisGap') ?? 'Hysteresis Gap'}: ${_hysteresisGap.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    loc?.translate('hysteresisGapDescription') ?? 'Prevents flickering between warning states',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Slider(
                    value: _hysteresisGap,
                    min: 0.05,
                    max: 0.3,
                    divisions: 25,
                    onChanged: (value) {
                      setState(() => _hysteresisGap = value);
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    '${loc?.translate('detectionThreshold') ?? 'Detection Threshold'}: ${_detectionThreshold.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    loc?.translate('detectionThresholdDescription') ?? 'Minimum confidence for face detection',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Slider(
                    value: _detectionThreshold,
                    min: 0.3,
                    max: 0.8,
                    divisions: 25,
                    onChanged: (value) {
                      setState(() => _detectionThreshold = value);
                    },
                  ),
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
                    loc?.translate('timingSettings') ?? 'Timing Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    '${loc?.translate('warningTime') ?? 'Warning Time'}: $_warningTime ${loc?.translate('minutes') ?? 'seconds'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    loc?.translate('warningTimeDescription') ?? 'How long to show warning before blocking screen',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Slider(
                    value: _warningTime.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (value) {
                      setState(() => _warningTime = value.round());
                    },
                  ),
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
                    loc?.translate('currentCalibration') ?? 'Current Calibration',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('${loc?.translate('baselineArea') ?? 'Baseline Area'}: ${PrefsHelper.getBaselineArea().toStringAsFixed(4)}'),
                  Text('${loc?.translate('calibrated') ?? 'Calibrated'}: ${PrefsHelper.getIsCalibrated() ? (loc?.translate('yes') ?? 'Yes') : (loc?.translate('no') ?? 'No')}'),
                  const SizedBox(height: 12),
                  Text(
                    loc?.translate('currentCalibration') ?? 'Current thresholds (calculated):',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${loc?.translate('enterThreshold') ?? 'Enter threshold'}: ${(PrefsHelper.getBaselineArea() * _thresholdFactor).toStringAsFixed(4)}'),
                  Text('${loc?.translate('exitThreshold') ?? 'Exit threshold'}: ${(PrefsHelper.getBaselineArea() * (_thresholdFactor - _hysteresisGap).clamp(0.8, double.infinity)).toStringAsFixed(4)}'),
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
                  Row(
                    children: [
                      const Icon(Icons.schedule, color: Colors.purple),
                      const SizedBox(width: 8),
                      Text(
                        loc?.translate('scheduledProtection') ?? 'Scheduled Protection',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc?.translate('scheduledProtectionDescription') ?? 'Automatically enable protection during set hours',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: Text(loc?.translate('enableSchedule') ?? 'Enable Schedule'),
                    subtitle: Text(
                      _scheduledEnabled 
                          ? 'Protection auto-starts ${_formatHour(_scheduleStartHour)} - ${_formatHour(_scheduleEndHour)}'
                          : loc?.translate('manualControlOnly') ?? 'Manual control only',
                    ),
                    value: _scheduledEnabled,
                    onChanged: (value) {
                      setState(() => _scheduledEnabled = value);
                    },
                  ),
                  
                  if (_scheduledEnabled) ...[
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(loc?.translate('startTime') ?? 'Start Time', style: const TextStyle(fontWeight: FontWeight.bold)),
                              DropdownButton<int>(
                                value: _scheduleStartHour,
                                isExpanded: true,
                                items: List.generate(24, (i) => DropdownMenuItem(
                                  value: i,
                                  child: Text(_formatHour(i)),
                                )),
                                onChanged: (v) => setState(() => _scheduleStartHour = v!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(loc?.translate('endTime') ?? 'End Time', style: const TextStyle(fontWeight: FontWeight.bold)),
                              DropdownButton<int>(
                                value: _scheduleEndHour,
                                isExpanded: true,
                                items: List.generate(24, (i) => DropdownMenuItem(
                                  value: i,
                                  child: Text(_formatHour(i)),
                                )),
                                onChanged: (v) => setState(() => _scheduleEndHour = v!),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                  Row(
                    children: [
                      Icon(Icons.notifications_active, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        loc?.translate('feedbackAlerts') ?? 'Feedback & Alerts',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: Text(loc?.translate('hapticFeedback') ?? 'Haptic Feedback'),
                    subtitle: Text(loc?.translate('hapticFeedbackDescription') ?? 'Vibrate on warnings'),
                    secondary: const Icon(Icons.vibration),
                    value: _hapticsEnabled,
                    onChanged: (value) {
                      setState(() => _hapticsEnabled = value);
                    },
                  ),
                  
                  SwitchListTile(
                    title: Text(loc?.translate('soundAlerts') ?? 'Sound Alerts'),
                    subtitle: Text(loc?.translate('soundAlertsDescription') ?? 'Play sound on warnings'),
                    secondary: const Icon(Icons.volume_up),
                    value: _soundEnabled,
                    onChanged: (value) {
                      setState(() => _soundEnabled = value);
                    },
                  ),
                  
                  const Divider(),
                  
                  SwitchListTile(
                    title: Text(loc?.translate('breakReminders') ?? 'Break Reminders'),
                    subtitle: Text(
                      _breakReminderEnabled
                          ? loc?.translate('remindEvery', params: {'interval': '$_breakReminderInterval'}) ?? 'Remind every $_breakReminderInterval minutes'
                          : loc?.translate('manualControlOnly') ?? 'Disabled',
                    ),
                    secondary: const Icon(Icons.timer),
                    value: _breakReminderEnabled,
                    onChanged: (value) {
                      setState(() => _breakReminderEnabled = value);
                    },
                  ),
                  
                  if (_breakReminderEnabled) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${loc?.translate('reminderInterval') ?? 'Reminder interval'}: $_breakReminderInterval ${loc?.translate('minutes') ?? 'minutes'}'),
                          Slider(
                            value: _breakReminderInterval.toDouble(),
                            min: 10,
                            max: 60,
                            divisions: 10,
                            label: '$_breakReminderInterval min',
                            onChanged: (value) {
                              setState(() => _breakReminderInterval = value.toInt());
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetToDefaults,
                  child: Text(loc?.translate('resetToDefaults') ?? 'Reset to Defaults'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  child: Text(loc?.translate('saveSettings') ?? 'Save Settings'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        loc?.translate('about') ?? 'About',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.apps),
                    title: Text(loc?.translate('appTitle') ?? 'KeepMe Away'),
                    subtitle: Text('${loc?.translate('version') ?? 'Version'} 1.0.0'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.gavel),
                    title: Text(loc?.translate('license') ?? 'License'),
                    subtitle: const Text('MIT License'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.code),
                    title: Text(loc?.translate('sourceCode') ?? 'Source Code'),
                    subtitle: const Text('github.com/Priyanshu-5257/keepme-away'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.psychology),
                    title: Text(loc?.translate('faceDetection') ?? 'Face Detection'),
                    subtitle: const Text('MediaPipe BlazeFace (Apache 2.0)'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc?.translate('settingsHelp') ?? 'Settings Help:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  loc?.translate('settingsHelpContent') ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
