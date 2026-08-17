// lib/widgets/force_update_dialog.dart
//
// A branded, non-dismissible dialog that forces the user to update the app
// when a newer version is required. When `forceUpdate` is true, the dialog
// cannot be dismissed (no close button, back button blocked, barrier locked).

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/version_check_service.dart';

/// Shows the force-update dialog over the current context.
///
/// When [result.forceUpdate] is true the dialog is non-dismissible and the
/// user must tap "Update Now" (which opens the store) to proceed.
Future<void> showForceUpdateDialog(
  BuildContext context,
  VersionCheckResult result,
) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: !result.forceUpdate,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (dialogContext) => ForceUpdateDialog(result: result),
  );
}

class ForceUpdateDialog extends StatelessWidget {
  const ForceUpdateDialog({super.key, required this.result});

  final VersionCheckResult result;

  Future<void> _openStore() async {
    final url = result.playStoreUrl;
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        print('⚠️ Could not open store URL: $url');
      }
    } catch (e) {
      print('⚠️ Error opening store URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      // Block the system back button when the update is forced.
      canPop: !result.forceUpdate,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667EEA), // Deep periwinkle
                Color(0xFF764BA2), // Rich purple
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.system_update_alt_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  'Update Available',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                // Message
                Text(
                  result.updateMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                if (result.latestVersion.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      'New version: v${result.latestVersion}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // Update Now button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _openStore,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1B365D), // Navy
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 20),
                    label: const Text('Update Now'),
                  ),
                ),
                // Optional "Later" button (only when not forced)
                if (!result.forceUpdate) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withValues(alpha: 0.85),
                    ),
                    child: const Text('Later'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
