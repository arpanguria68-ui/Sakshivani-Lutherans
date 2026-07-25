import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../features/auth/domain/auth_state.dart';
import '../../../services/church_courtesy_service.dart';
import '../../../services/tts_service.dart';
import '../../../shared/widgets/app_backdrop.dart';
import '../../../shared/widgets/glass_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _churchModeEnabled = true;
  double _courtesyVolume = 0.20;
  bool _reminderEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 6, minute: 30);
  List<TtsEngineInfo> _ttsEngines = <TtsEngineInfo>[];
  String? _ttsEngine; // null = auto

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = ref.read(localStorageServiceProvider);
    final bool enabled = await storage.getChurchModeEnabled();
    final double volume = await storage.getCourtesyVolumeLevel();
    final bool remEnabled = await storage.getReminderEnabled();
    final (int h, int m) = await storage.getReminderTime();
    if (!mounted) {
      return;
    }
    final String? ttsEngine = await storage.getTtsEngine();
    if (mounted) {
      setState(() {
        _churchModeEnabled = enabled;
        _courtesyVolume = volume;
        _reminderEnabled = remEnabled;
        _reminderTime = TimeOfDay(hour: h, minute: m);
        _ttsEngine = ttsEngine;
      });
    }
    // Engine discovery can take a moment; load it after the basics.
    final List<TtsEngineInfo> engines =
        await ref.read(ttsServiceProvider).availableEngines();
    if (mounted) setState(() => _ttsEngines = engines);
  }

  Future<void> _selectTtsEngine(String? engine) async {
    setState(() => _ttsEngine = engine);
    await ref.read(ttsServiceProvider).setPreferredEngine(engine);
    await ref.read(localStorageServiceProvider).setTtsEngine(engine);
  }

  Future<void> _applyReminder() async {
    final storage = ref.read(localStorageServiceProvider);
    final notifications = ref.read(notificationServiceProvider);
    await storage.setReminderEnabled(_reminderEnabled);
    await storage.setReminderTime(_reminderTime.hour, _reminderTime.minute);
    if (_reminderEnabled) {
      await notifications.scheduleDailyVerseReminderAt(
          hour: _reminderTime.hour, minute: _reminderTime.minute);
    } else {
      await notifications.cancelDailyVerseReminder();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    final AuthState auth = ref.watch(authControllerProvider);
    final themeController = ref.read(themeModeControllerProvider.notifier);
    final ChurchCourtesyService courtesy = ref.read(churchCourtesyServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AppBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: <Widget>[
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    SegmentedButton<ThemeMode>(
                      segments: const <ButtonSegment<ThemeMode>>[
                        ButtonSegment<ThemeMode>(value: ThemeMode.system, label: Text('System')),
                        ButtonSegment<ThemeMode>(value: ThemeMode.light, label: Text('Light')),
                        ButtonSegment<ThemeMode>(value: ThemeMode.dark, label: Text('Dark')),
                      ],
                      selected: <ThemeMode>{mode},
                      onSelectionChanged: (Set<ThemeMode> value) {
                        themeController.setThemeMode(value.first);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Church Courtesy Mode', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable courtesy prompts'),
                      subtitle: const Text('Suggest silent/low-volume during worship time.'),
                      value: _churchModeEnabled,
                      onChanged: (bool enabled) async {
                        setState(() {
                          _churchModeEnabled = enabled;
                        });
                        await ref.read(localStorageServiceProvider).setChurchModeEnabled(enabled);
                      },
                    ),
                    const SizedBox(height: 8),
                    Text('Courtesy volume level ${(100 * _courtesyVolume).round()}%'),
                    Slider(
                      value: _courtesyVolume,
                      onChanged: (double v) {
                        setState(() {
                          _courtesyVolume = v;
                        });
                      },
                      onChangeEnd: (double v) async {
                        await ref.read(localStorageServiceProvider).setCourtesyVolumeLevel(v);
                      },
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        OutlinedButton.icon(
                          onPressed: () => courtesy.lowerVolumeForService(),
                          icon: const Icon(Icons.volume_down),
                          label: const Text('Lower now'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => courtesy.restoreVolume(),
                          icon: const Icon(Icons.volume_up),
                          label: const Text('Restore'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => courtesy.openDoNotDisturbSettings(),
                          icon: const Icon(Icons.notifications_off),
                          label: const Text('DND settings'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Daily Reminder', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Daily verse & reading reminder'),
                      subtitle: const Text('A gentle nudge to open the app each day.'),
                      value: _reminderEnabled,
                      onChanged: (bool v) async {
                        setState(() => _reminderEnabled = v);
                        await _applyReminder();
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.schedule),
                      title: const Text('Reminder time'),
                      trailing: Text(_reminderTime.format(context)),
                      enabled: _reminderEnabled,
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: _reminderTime,
                        );
                        if (picked != null) {
                          setState(() => _reminderTime = picked);
                          await _applyReminder();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Read-aloud voice (TTS)', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Choose the speech engine. “Auto” uses the best installed '
                      'engine per language and falls back to Google TTS for '
                      'languages your default engine can’t speak (e.g. Hindi).',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    RadioListTile<String?>(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Auto (recommended)'),
                      subtitle: const Text('Best engine per language'),
                      value: null,
                      groupValue: _ttsEngine,
                      onChanged: _selectTtsEngine,
                    ),
                    if (_ttsEngines.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Detecting installed engines…'),
                      )
                    else
                      ..._ttsEngines.map((TtsEngineInfo e) => RadioListTile<String?>(
                            contentPadding: EdgeInsets.zero,
                            title: Row(
                              children: <Widget>[
                                Flexible(child: Text(e.label, overflow: TextOverflow.ellipsis)),
                                if (e.isDefault)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 6),
                                    child: Text('· default', style: TextStyle(fontSize: 12)),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              'Hindi ${e.supportsHindi ? "✓" : "✗"}  ·  '
                              'English ${e.supportsEnglish ? "✓" : "✗"}  ·  '
                              '${e.languageCount} languages',
                            ),
                            value: e.id,
                            groupValue: _ttsEngine,
                            onChanged: _selectTtsEngine,
                          )),
                    if (_ttsEngines.isNotEmpty &&
                        !_ttsEngines.any((TtsEngineInfo e) => e.supportsHindi))
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'No installed engine has a Hindi voice. Install it in '
                          'Settings → General management → Text-to-speech (Google TTS).',
                          style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Account', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(_authLabel(auth)),
                    const SizedBox(height: 8),
                    if (!auth.isAuthenticated)
                      FilledButton.icon(
                        onPressed: () => context.push('/auth'),
                        icon: const Icon(Icons.login),
                        label: const Text('Sign in for sync'),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign out'),
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

  String _authLabel(AuthState state) {
    switch (state.status) {
      case AuthStatus.authenticated:
        return 'Signed in as ${state.user?.email ?? state.user?.uid ?? ''}';
      case AuthStatus.anonymous:
        return 'Anonymous user (cloud temporary)';
      case AuthStatus.localGuest:
        return 'Local guest mode (offline first)';
      case AuthStatus.loading:
        return 'Loading account...';
      case AuthStatus.error:
        return state.errorMessage ?? 'Authentication error';
    }
  }
}
