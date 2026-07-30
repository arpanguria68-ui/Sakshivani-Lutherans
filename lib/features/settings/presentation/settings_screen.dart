import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers.dart';
import '../../../features/auth/domain/auth_state.dart';
import '../../bible/presentation/bible_tab.dart' show bibleHistoryProvider, bibleLastReadProvider;
import '../../home/domain/verse_background_settings.dart';
import '../../home/presentation/home_tab.dart' show progressStatsProvider;
import '../../planner/presentation/planner_screen.dart'
    show activePlanProvider, activityDatesProvider, completedDaysProvider;
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
  bool _adFree = false;
  bool _purchasePending = false;

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

    await _refreshAdFree();
  }

  Future<void> _refreshAdFree() async {
    final bool adFree = await ref.read(localStorageServiceProvider).getAdFree();
    if (mounted) setState(() => _adFree = adFree);
  }

  Future<void> _buyRemoveAds() async {
    setState(() => _purchasePending = true);
    await ref.read(purchaseServiceProvider).buyRemoveAds();
    await _refreshAdFree();
    if (mounted) setState(() => _purchasePending = false);
  }

  Future<void> _restorePurchases() async {
    setState(() => _purchasePending = true);
    await ref.read(purchaseServiceProvider).restorePurchases();
    await _refreshAdFree();
    if (mounted) setState(() => _purchasePending = false);
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

  /// Wipes local content, the local-guest identity, and onboarding state,
  /// then refreshes auth state — shared tail for both reset and delete.
  ///
  /// Order matters: resetting onboarding flips the router redirect and can
  /// dispose this screen mid-sequence, so it runs last, and every step is
  /// guarded with `mounted` — `ref` throws once that happens. The redirect
  /// alone isn't trusted to fire promptly on this provider-driven router
  /// (recreating the GoRouter instance doesn't reliably re-run redirect
  /// against the live navigation stack), so this also navigates explicitly.
  Future<void> _wipeLocalStateAndRefresh() async {
    await ref.read(databaseProvider).wipeUserData();
    if (!mounted) return;
    await ref.read(localStorageServiceProvider).clearBibleReadingState();
    if (!mounted) return;
    await ref.read(localStorageServiceProvider).clearLocalGuestUid();
    if (!mounted) return;
    await ref.read(authControllerProvider.notifier).initialize();
    if (!mounted) return;

    ref.invalidate(activePlanProvider);
    ref.invalidate(completedDaysProvider);
    ref.invalidate(activityDatesProvider);
    ref.invalidate(progressStatsProvider);
    ref.invalidate(bibleLastReadProvider);
    ref.invalidate(bibleHistoryProvider);

    await ref.read(onboardingControllerProvider.notifier).reset();
    if (!mounted) return;
    context.go('/onboarding');
  }

  Future<void> _openPrivacyPolicy() async {
    if (!mounted) return;
    context.push('/legal/privacy');
  }

  Future<void> _openTerms() async {
    if (!mounted) return;
    context.push('/legal/terms');
  }

  Future<void> _resetApp() async {
    final bool signedIn = ref.read(authControllerProvider).isAuthenticated;

    // Anonymous/local-guest data lives only on this device — nothing backs
    // it up, so "Reset" here is genuinely irreversible. Signed-in users have
    // a cloud copy, so the softer message (and no detour to sign-in) is fine.
    if (!signedIn) {
      final String? choice = await showDialog<String>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: const Text('Reset app?'),
          content: const Text(
            'You\'re not signed in, so your prayer streak, favorites, and '
            'reflections exist only on this device. Resetting deletes them '
            'permanently — there is no cloud backup to recover from.',
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, 'sign_in'), child: const Text('Sign in first')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
              onPressed: () => Navigator.pop(ctx, 'reset'),
              child: const Text('Reset anyway'),
            ),
          ],
        ),
      );
      if (choice == 'sign_in') {
        if (mounted) context.push('/auth');
        return;
      }
      if (choice != 'reset') {
        return;
      }
      await ref.read(authControllerProvider.notifier).signOut();
      if (!mounted) return;
      await _wipeLocalStateAndRefresh();
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Reset app?'),
        content: const Text(
          'Signs out and clears reflections, favorites, and progress on '
          'this device, then shows onboarding again. If you\'re signed in, '
          'your cloud data is not touched — sign back in to get it back.',
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    await ref.read(authControllerProvider.notifier).signOut();
    if (!mounted) return;
    await _wipeLocalStateAndRefresh();
  }

  Future<void> _deleteAccount() async {
    final AuthState auth = ref.read(authControllerProvider);
    final TextEditingController password = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'This permanently deletes your reflections, favorites, and '
              'progress — on this device and in the cloud. This cannot be undone.',
            ),
            if (auth.isAuthenticated) ...<Widget>[
              const SizedBox(height: 12),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password (only if you signed in with email)',
                ),
              ),
            ],
          ],
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    final bool ok = await ref.read(authControllerProvider.notifier).deleteAccount(
          password: password.text.isEmpty ? null : password.text,
        );
    if (!mounted) {
      return;
    }
    if (!ok) {
      final String? err = ref.read(authControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Could not delete account.')),
      );
      return;
    }

    await _wipeLocalStateAndRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    final AuthState auth = ref.watch(authControllerProvider);
    final themeController = ref.read(themeModeControllerProvider.notifier);
    final ChurchCourtesyService courtesy = ref.read(churchCourtesyServiceProvider);
    final VerseBackgroundSettings bgSettings = ref.watch(verseBackgroundControllerProvider);
    final bgController = ref.read(verseBackgroundControllerProvider.notifier);

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
                    Text('Verse Background', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'The photo behind today\'s verse. Auto rotates through your '
                      'arranged order like a screensaver; Manual keeps one fixed photo.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<VerseBackgroundMode>(
                      segments: const <ButtonSegment<VerseBackgroundMode>>[
                        ButtonSegment<VerseBackgroundMode>(
                            value: VerseBackgroundMode.auto, label: Text('Auto')),
                        ButtonSegment<VerseBackgroundMode>(
                            value: VerseBackgroundMode.manual, label: Text('Manual')),
                      ],
                      selected: <VerseBackgroundMode>{bgSettings.mode},
                      onSelectionChanged: (Set<VerseBackgroundMode> value) {
                        bgController.setMode(value.first);
                      },
                    ),
                    const SizedBox(height: 14),
                    if (bgSettings.mode == VerseBackgroundMode.auto) ...<Widget>[
                      Text('Changes every ${bgSettings.rotateHours}h'),
                      Slider(
                        value: bgSettings.rotateHours.toDouble(),
                        min: 1,
                        max: 72,
                        divisions: 71,
                        label: '${bgSettings.rotateHours}h',
                        onChanged: (double v) => bgController.setRotateHours(v.round()),
                      ),
                      const SizedBox(height: 6),
                      Text('Drag to arrange rotation order',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 8),
                      _BackgroundReorderRow(
                        order: bgSettings.order,
                        onReorder: bgController.setOrder,
                      ),
                    ] else
                      _BackgroundPickerGrid(
                        order: bgSettings.order,
                        selected: bgSettings.manualImage,
                        onSelected: bgController.setManualImage,
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
              _RemoveAdsCard(
                adFree: _adFree,
                pending: _purchasePending,
                product: ref.watch(purchaseServiceProvider).removeAdsProduct,
                onBuy: _buyRemoveAds,
                onRestore: _restorePurchases,
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
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text('Legal', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Privacy policy'),
                      subtitle: const Text('EN / हिंदी · US · EU · India data rights'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openPrivacyPolicy,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.gavel_outlined),
                      title: const Text('Terms & Conditions'),
                      subtitle: const Text('EN / हिंदी · App use & regional terms'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openTerms,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(Icons.open_in_new, size: 20),
                      title: const Text('Open website'),
                      subtitle: const Text('Privacy & terms on GitHub Pages'),
                      onTap: () async {
                        final Uri uri = Uri.parse(AppConstants.siteBaseUrl);
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                    ),
                    const SizedBox(height: 8),
                    Text('Danger zone', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Reset clears this device only. Delete removes your account '
                      'and all data everywhere — permanently.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        OutlinedButton.icon(
                          onPressed: _resetApp,
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('Reset app'),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.error,
                            side: BorderSide(color: Theme.of(context).colorScheme.error),
                          ),
                          onPressed: _deleteAccount,
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Delete account'),
                        ),
                      ],
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

class _RemoveAdsCard extends StatelessWidget {
  const _RemoveAdsCard({
    required this.adFree,
    required this.pending,
    required this.product,
    required this.onBuy,
    required this.onRestore,
  });

  final bool adFree;
  final bool pending;
  final ProductDetails? product;
  final VoidCallback onBuy;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Remove Ads / Supporter', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (adFree)
            const Text('Ads are off on this device. Thank you for supporting Sakshi Vani!')
          else ...<Widget>[
            const Text(
              'Turn off banner and quiz-completion ads, and support ongoing '
              'development of Sakshi Vani.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: pending || product == null ? null : onBuy,
                  icon: const Icon(Icons.favorite_outline),
                  label: Text(product == null
                      ? 'Loading…'
                      : 'Remove Ads (${product!.price})'),
                ),
                OutlinedButton.icon(
                  onPressed: pending ? null : onRestore,
                  icon: const Icon(Icons.restore),
                  label: const Text('Restore purchases'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

String _backgroundLabel(String assetPath) {
  final String fileName = assetPath.split('/').last.replaceAll(RegExp(r'\.(png|webp)$'), '');
  final List<String> words = fileName.split('_');
  return words.map((String w) => w[0].toUpperCase() + w.substring(1)).join(' ');
}

/// Horizontal drag-to-reorder strip defining the auto-rotation playlist order.
class _BackgroundReorderRow extends StatelessWidget {
  const _BackgroundReorderRow({required this.order, required this.onReorder});

  final List<String> order;
  final ValueChanged<List<String>> onReorder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: order.length,
        onReorder: (int oldIndex, int newIndex) {
          final List<String> next = List<String>.of(order);
          if (newIndex > oldIndex) newIndex -= 1;
          final String moved = next.removeAt(oldIndex);
          next.insert(newIndex, moved);
          onReorder(next);
        },
        itemBuilder: (BuildContext context, int index) {
          final String path = order[index];
          return Padding(
            key: ValueKey<String>(path),
            padding: const EdgeInsets.only(right: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  // Source photos are 2880×2880 (multi-MB); decoding a dozen of
                  // them full-res for a 64px thumbnail exhausts decode memory
                  // and Skia throws "Could not decompress image" — cap the
                  // decode size instead of just the display size.
                  child: Image.asset(path, width: 64, height: 64, fit: BoxFit.cover, cacheWidth: 128),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 64,
                  child: Text(
                    '${index + 1}. ${_backgroundLabel(path)}',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Tap-to-select grid for the fixed Manual background.
class _BackgroundPickerGrid extends StatelessWidget {
  const _BackgroundPickerGrid({
    required this.order,
    required this.selected,
    required this.onSelected,
  });

  final List<String> order;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: order.map((String path) {
        final bool isSelected = path == selected;
        return GestureDetector(
          onTap: () => onSelected(path),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? colors.primary : Colors.transparent,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  // Source photos are 2880×2880 (multi-MB); decoding a dozen of
                  // them full-res for a 64px thumbnail exhausts decode memory
                  // and Skia throws "Could not decompress image" — cap the
                  // decode size instead of just the display size.
                  child: Image.asset(path, width: 64, height: 64, fit: BoxFit.cover, cacheWidth: 128),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 70,
                child: Text(
                  _backgroundLabel(path),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected ? colors.primary : null,
                        fontWeight: isSelected ? FontWeight.w700 : null,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      }).toList(growable: false),
    );
  }
}
