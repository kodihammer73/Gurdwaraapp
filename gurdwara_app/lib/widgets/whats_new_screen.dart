// lib/widgets/whats_new_screen.dart
//
// A one-time "What's New" sheet shown to existing users after an app update.
// Displays the latest feature highlights and is dismissed with a "Got it"
// button. Persists a flag in SharedPreferences so it only appears once per
// version.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shows the "What's New" sheet if the user hasn't seen it for the current
/// app version. Call this after the splash/onboarding flow.
Future<void> maybeShowWhatsNew(BuildContext context) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final seenVersion = prefs.getString('whats_new_seen_version');
    const currentVersion = '1.0.4'; // Bump this when you add notable features.
    if (seenVersion == currentVersion) return;

    await prefs.setString('whats_new_seen_version', currentVersion);

    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _WhatsNewSheet(),
    );
  } catch (_) {
    // Best-effort; never block the app.
  }
}

class _WhatsNewSheet extends StatelessWidget {
  const _WhatsNewSheet();

  static const List<_WhatsNewItem> _items = [
    _WhatsNewItem(
      icon: Icons.image_rounded,
      color: Color(0xFFE8A838),
      title: 'New Home Hero Banner',
      description:
          'A beautiful photo of the Gurdwara now greets you on the home screen.',
    ),
    _WhatsNewItem(
      icon: Icons.swipe_rounded,
      color: Color(0xFF667EEA),
      title: 'Swipe Through Gallery Photos',
      description:
          'Open any photo and swipe left or right to browse the whole set.',
    ),
    _WhatsNewItem(
      icon: Icons.language_rounded,
      color: Color(0xFF43E97B),
      title: 'Language Options',
      description:
          'Choose English, Bahasa Melayu or Punjabi from the Settings screen.',
    ),
    _WhatsNewItem(
      icon: Icons.quick_contacts_dialer_rounded,
      color: Color(0xFFF093FB),
      title: 'Quick Actions',
      description:
          'Call, get directions or open WhatsApp right from the home screen.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8A838).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFFE8A838),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "What's New",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final item in _items) ...[
              _WhatsNewTile(item: item),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE8A838),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatsNewTile extends StatelessWidget {
  const _WhatsNewTile({required this.item});

  final _WhatsNewItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.icon, color: item.color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WhatsNewItem {
  const _WhatsNewItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
}
