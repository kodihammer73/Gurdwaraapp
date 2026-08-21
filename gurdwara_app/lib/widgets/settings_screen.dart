// lib/widgets/settings_screen.dart
//
// Settings / More screen with app preferences like notification toggle
// and theme mode selection. Uses SharedPreferences for persistence.

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {

  const SettingsScreen({super.key, this.onThemeModeChanged});

  /// Called when the user changes the theme mode, so the app can
  /// rebuild immediately with the new theme.
  final ValueChanged<String>? onThemeModeChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _themeMode = 'system'; // 'system' | 'light' | 'dark'
  String? _versionText;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadVersion();
  }

  Future<void> _loadPreferences() async {

    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _themeMode = prefs.getString('theme_mode') ?? 'system';
      });
    } catch (_) {
      // Keep defaults.
    }
  }


  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version.trim();
      final build = info.buildNumber.trim();
      setState(() {
        _versionText = build.isEmpty ? version : '$version ($build)';
      });
    } catch (_) {
      _versionText = null;
    }
  }

  Future<void> _setNotificationsEnabled(bool value) async {
    setState(() => _notificationsEnabled = value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', value);
    } catch (_) {
      // Best effort.
    }
  }

  Future<void> _setThemeMode(String mode) async {
    setState(() => _themeMode = mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', mode);
    } catch (_) {
      // Best effort.
    }
    // Notify the app to rebuild with the new theme immediately.
    widget.onThemeModeChanged?.call(mode);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            title: Text(
              'Settings',
              style: theme.textTheme.headlineMedium,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  // Notifications section
                  Text(
                    'Preferences',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    margin: EdgeInsets.zero,
                    child: SwitchListTile(
                      secondary: const Icon(Icons.notifications_active_outlined),
                      title: const Text('Push Notifications'),
                      subtitle: const Text(
                        'Receive event reminders and announcements',
                      ),
                      value: _notificationsEnabled,
                      onChanged: _setNotificationsEnabled,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Theme section
                  Text(
                    'Appearance',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.brightness_auto_outlined),
                          title: const Text('System Default'),
                          trailing: Icon(
                            _themeMode == 'system'
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: _themeMode == 'system'
                                ? theme.colorScheme.primary
                                : null,
                          ),
                          onTap: () => _setThemeMode('system'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.light_mode_outlined),
                          title: const Text('Light'),
                          trailing: Icon(
                            _themeMode == 'light'
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: _themeMode == 'light'
                                ? theme.colorScheme.primary
                                : null,
                          ),
                          onTap: () => _setThemeMode('light'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.dark_mode_outlined),
                          title: const Text('Dark'),
                          trailing: Icon(
                            _themeMode == 'dark'
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: _themeMode == 'dark'
                                ? theme.colorScheme.primary
                                : null,
                          ),
                          onTap: () => _setThemeMode('dark'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // About section

                  Text(
                    'About',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 12),
                  Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8A838).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          'web/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.temple_buddhist,
                              color: theme.colorScheme.primary,
                            );
                          },
                        ),
                      ),
                      title: const Text('Gurdwara Sahib Melaka'),
                      subtitle: Text(
                        _versionText != null
                            ? 'Developed for Gurdwara Sahib Melaka v$_versionText'
                            : 'Developed for Gurdwara Sahib Melaka',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      '© Gurdwara Sahib Melaka. All rights reserved.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}