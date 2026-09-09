// lib/main.dart - Add these at the VERY TOP of the file, before any other code

import 'dart:convert';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:gurdwara_app/widgets/seva_booking_screen.dart';
import 'package:gurdwara_app/widgets/prayer_reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'config/theme.dart';
import 'services/cache_service.dart';
import 'services/firebase_options.dart';
import 'services/localization_service.dart';
import 'services/notification_service.dart';
import 'services/version_check_service.dart';
import 'widgets/branded_splash_screen.dart';
import 'widgets/force_update_dialog.dart';
import 'widgets/immersive_category_grid.dart';
import 'widgets/onboarding_screen.dart';
import 'widgets/settings_screen.dart';
import 'widgets/whats_new_screen.dart';



// ⭐ ADD THESE GLOBAL CONSTANTS (they were missing)
const String _siteBaseUrl = 'https://www.gurdwarasahibmelaka.com';
const String _siteLogoAsset = 'web/logo.png';
const String _eventsUrl = '$_siteBaseUrl/events.txt';

// ⭐ ADD THIS GLOBAL DIO INSTANCE (it was missing)
final Dio _dio = Dio(
  BaseOptions(
    responseType: ResponseType.plain,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    followRedirects: true,
  ),
);

// ⭐ MAKE SURE you only have ONE main() function
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Clean initialization check using Firebase.apps (never throws StateError)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized via options');
    }
  } catch (e, stack) {
    print('⚠️ Firebase init failed: $e\n$stack');
  }

  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    print('✅ Notification Service initialized');
  } catch (e, stack) {
    print('⚠️ Notification Service init failed: $e\n$stack');
  }
  
  runApp(const ProviderScope(child: GurdwaraApp()));
}

class GurdwaraApp extends ConsumerStatefulWidget {
  const GurdwaraApp({super.key});

  @override
  ConsumerState<GurdwaraApp> createState() => _GurdwaraAppState();
}

class _GurdwaraAppState extends ConsumerState<GurdwaraApp> {
  final VersionCheckService _versionCheckService = VersionCheckService();
  bool _showSplash = true;
  bool _showOnboarding = false;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _bootSequence();
    _loadThemeMode();
    _checkOnboarding();
    LocalizationService.instance.load();
  }


  /// Checks whether the user has seen the onboarding screen before.
  /// If not, shows it after the splash.
  Future<void> _checkOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool('onboarding_seen') ?? false;
      if (!seen && mounted) {
        setState(() => _showOnboarding = true);
      }
    } catch (_) {
      // If we can't read the flag, default to not showing onboarding.
    }
  }

  /// Marks onboarding as seen and transitions to the main app.
  Future<void> _finishOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_seen', true);
    } catch (_) {
      // Ignore persistence errors.
    }
    if (mounted) {
      setState(() => _showOnboarding = false);
    }
    // Show the one-time "What's New" sheet after onboarding completes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) maybeShowWhatsNew(context);
    });
  }


  /// Loads the user's theme preference from SharedPreferences.
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mode = prefs.getString('theme_mode') ?? 'system';
      _applyThemeMode(mode);
    } catch (_) {
      // Keep system default.
    }
  }

  /// Applies the given theme mode string ('system' | 'light' | 'dark').
  void _applyThemeMode(String mode) {
    final themeMode = switch (mode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    if (mounted) {
      setState(() => _themeMode = themeMode);
    }
  }

  /// Shows the branded splash screen with a minimum display duration,
  /// then fades into the main app.
  Future<void> _bootSequence() async {
    // Run version check and splash timer in parallel.
    final results = await Future.wait([
      _versionCheckService.checkForUpdate(),
      Future.delayed(const Duration(milliseconds: 1800)),
    ]);

    if (!mounted) return;

    setState(() => _showSplash = false);

    final result = results[0] as VersionCheckResult;
    if (!result.updateRequired) return;

    // Show the force-update dialog after the splash fades out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showForceUpdateDialog(context, result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gurdwara Sahib Melaka',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _showSplash
            ? const BrandedSplashScreen()
            : _showOnboarding
                ? OnboardingScreen(onFinished: _finishOnboarding)
                : HomeScreen(
                    onThemeModeChanged: _applyThemeMode,
                  ),
      ),
    );
  }
}



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onThemeModeChanged});

  /// Called when the user changes the theme mode in Settings.
  final ValueChanged<String>? onThemeModeChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Register the deep-link handler so tapping a push notification
    // navigates to the relevant tab (e.g. Calendar for event reminders).
    NotificationService.onNotificationTap = _handleNotificationTap;
  }

  @override
  void dispose() {
    NotificationService.onNotificationTap = null;
    super.dispose();
  }


  /// Maps a notification screen name to a bottom-nav tab index.
  void _handleNotificationTap(String screen) {
    final index = switch (screen) {
      'home' => 0,
      'calendar' => 1,
      'gallery' => 2,
      'about' => 3,
      'settings' => 4,
      _ => 1, // Default to Calendar for event notifications.
    };
    _selectTab(index);
  }

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return HomeScreenContent(
          onCalendarSelected: () => _selectTab(1),
          onBookingSelected: () => _selectTab(2),
          onGallerySelected: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => GalleryScreen()),
          ),
          onAboutSelected: () => _selectTab(3),
          onSettingsSelected: () => _selectTab(4),
        );
      case 1:
        return const CalendarScreen();
      case 2:
        return const SevaBookingScreen();
      case 3:
        return const AboutScreen();
      case 4:
        return SettingsScreen(
          onThemeModeChanged: widget.onThemeModeChanged,
        );
      default:
        return HomeScreenContent(
          onCalendarSelected: () => _selectTab(1),
          onBookingSelected: () => _selectTab(2),
          onGallerySelected: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => GalleryScreen()),
          ),
          onAboutSelected: () => _selectTab(3),
          onSettingsSelected: () => _selectTab(4),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.03, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: _buildScreen(_selectedIndex),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.volunteer_activism_outlined),
            selectedIcon: Icon(Icons.volunteer_activism),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'About',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({
    super.key,
    required this.onCalendarSelected,
    required this.onBookingSelected,
    required this.onGallerySelected,
    required this.onAboutSelected,
    this.onSettingsSelected,
  });

  final VoidCallback onCalendarSelected;
  final VoidCallback onBookingSelected;
  final VoidCallback onGallerySelected;
  final VoidCallback onAboutSelected;
  final VoidCallback? onSettingsSelected;

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  late Future<List<HomepageEvent>> _future;
  DateTime? _lastUpdated;

  /// The Gurdwara contact number from contact_data.json (footerContact.phone),
  /// used by the Call/WhatsApp quick actions. Falls back to empty string.
  String _contactNumber = '';

  @override
  void initState() {
    super.initState();
    _future = _fetchUpcomingEvents();
    _loadContactNumber();
  }

  /// Fetches the contact number from the website's contact_data.json
  /// (footerContact.phone) for the Call/WhatsApp quick actions.
  Future<void> _loadContactNumber() async {
    String number = '';
    try {
      final response = await _dio.get<String>('$_siteBaseUrl/contact_data.json');
      final raw = response.data ?? '';
      if (raw.isNotEmpty) {
        final json = jsonDecode(raw);
        final footerContact = json['footerContact'] as Map<String, dynamic>?;
        number = (footerContact?['phone'] as String? ?? '').trim();
      }
    } catch (_) {
      // Leave the number empty on failure; the quick actions will be hidden.
    }
    if (mounted && number.isNotEmpty) {
      setState(() => _contactNumber = number);
    }
  }


  Future<void> _refresh() async {
    setState(() {
      _future = _fetchUpcomingEvents();
    });
    await _future;
    if (mounted) {
      setState(() => _lastUpdated = DateTime.now());
    }
  }


  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<HomepageEvent>>(
        future: _future,
        builder: (context, snapshot) {
          final slivers = <Widget>[
            SliverAppBar(
              pinned: true,
              elevation: 0,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Splash-style glass tile with the saffron-filled logo
                  Container(
                    width: 34,
                    height: 34,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE8A838).withValues(alpha: 0.45),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.matrix(<double>[
                            0, 0, 0, 0, 0xE8,
                            0, 0, 0, 0, 0xA8,
                            0, 0, 0, 0, 0x38,
                            0, 0, 0, 1, 0,
                          ]),
                          child: Image.asset(
                            'web/translogo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.temple_buddhist,
                                size: 18,
                                color: const Color(0xFFE8A838),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'GURDWARA SAHIB MELAKA',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontFamily: 'Georgia',
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                  ),
                ],
              ),
              centerTitle: false,
            ),
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _SplashLoading(),
              )
            else if (snapshot.hasError)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _ErrorState(
                  title: 'Unable to load homepage',
                  message:
                      'Pull down to refresh the latest data from the website.',
                  onRetry: _refresh,
                ),
              )
            else if (snapshot.hasData)
              _buildHomeContent(context, snapshot.data!),
          ];

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: slivers,
          );
        },
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, List<HomepageEvent> events) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero banner with the Gurdwara building image + gradient overlay
            SizedBox(
              width: double.infinity,
              height: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gurdwara building image (falls back to gradient on error)
                    // The ?v=2 cache-buster forces CachedNetworkImage to treat this
                    // as a fresh URL, clearing any previously cached load error.
                    CachedNetworkImage(
                      imageUrl:
                          '$_siteBaseUrl/images/gurdwara/gurdwarafront.jpeg?v=2',
                      fit: BoxFit.cover,
                      memCacheWidth: 1200,
                      memCacheHeight: 800,

                      placeholder: (context, url) => const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFE8A838),
                              Color(0xFFC5851E),
                            ],
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFE8A838),
                              Color(0xFFC5851E),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Saffron→navy gradient overlay for text legibility
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color(0xCC1B365D),
                          ],
                          stops: [0.35, 1.0],
                        ),
                      ),
                    ),
                    // Foreground content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Waheguru Ji Ka Khalsa Waheguru Ji Ki Fateh',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Today's date badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 0.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      color: Colors.white,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      DateFormat('EEEE, d MMMM yyyy')
                                          .format(DateTime.now()),
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.95),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Quick actions: Call, WhatsApp (hidden until the contact number loads)
            if (_contactNumber.isNotEmpty)
              _QuickActionsRow(phoneNumber: _contactNumber),
            const SizedBox(height: 12),

            // Nitnem & Prayer Reader quick launcher card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: const Color(0xFFE8A838),
              child: ListTile(
                leading: const Icon(Icons.menu_book, color: Colors.white, size: 30),
                title: const Text(
                  'Nitnem & Prayer Reader',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: const Text(
                  'Read Daily Nitnem with Gurmukhi & English Translation',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrayerReaderScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // "Track My Request" banner — surfaces the request-tracking feature
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: const Color(0xFF1B365D),
              child: ListTile(
                leading: const Icon(Icons.manage_search_rounded, color: Color(0xFFE8A838), size: 30),
                title: const Text(
                  'Track My Request',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: const Text(
                  'Check the live status of your Langar, Hall Booking or Ardas request',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFFE8A838), size: 16),
                onTap: widget.onBookingSelected,
              ),
            ),
            const SizedBox(height: 12),

            // "Last updated" hint (shown after a pull-to-refresh)
            if (_lastUpdated != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.sync_rounded,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${LocalizationService.instance.t('last_updated')} '
                      '${DateFormat('h:mm a').format(_lastUpdated!.toLocal())}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),

                  ],
                ),
              ),
            // Upcoming Events card with immersive gradient style (brand navy)
            SizedBox(
              width: double.infinity,
              child: _ImmersiveInfoCard(
                gradientColors: const [
                  Color(0xFF1B365D), // Navy
                  Color(0xFF2A4B7C), // Navy Light
                ],
                child: UpcomingEventsCard(events: events),
              ),
            ),
            const SizedBox(height: 12),

            // Section header
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                'Explore',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
              ),
            ),
            const SizedBox(height: 4),
            // Immersive Apple App Store-style category grid
            ImmersiveCategoryGrid(
              categories: [
                ImmersiveCategory(
                  title: 'Calendar',
                  subtitle: 'View events & schedules',
                  icon: Icons.calendar_month_rounded,
                  gradientColors: const [
                    Color(0xFF667EEA), // Deep periwinkle
                    Color(0xFF764BA2), // Rich purple
                  ],
                  onTap: widget.onCalendarSelected,
                ),
                ImmersiveCategory(
                  title: 'Gallery',
                  subtitle: 'Photos & memories',
                  icon: Icons.photo_library_rounded,
                  gradientColors: const [
                    Color(0xFFF093FB), // Hot pink
                    Color(0xFFF5576C), // Coral red
                  ],
                  onTap: widget.onGallerySelected,
                ),
                ImmersiveCategory(
                  title: 'Barsi',
                  subtitle: 'Annual remembrance',
                  icon: Icons.auto_awesome_rounded,
                  gradientColors: const [
                    Color(0xFF4FACFE), // Sky blue
                    Color(0xFF00F2FE), // Cyan
                  ],
                  onTap: () {},
                  fullContentBuilder: (context, parallax) =>
                      _BarsiFullContent(parallax: parallax),
                ),
                ImmersiveCategory(
                  title: 'About',
                  subtitle: 'Our community',
                  icon: Icons.info_rounded,
                  gradientColors: const [
                    Color(0xFFFA709A), // Rose
                    Color(0xFFFEE140), // Yellow
                  ],
                  onTap: widget.onAboutSelected,
                ),
                ImmersiveCategory(
                  title: 'Booking',
                  subtitle: 'Seva, Hall Booking & Tracking',
                  icon: Icons.volunteer_activism_rounded,
                  gradientColors: const [
                    Color(0xFFFF9A9E), // Warm Peach
                    Color(0xFFFECFEF), // Soft Rose
                  ],
                  onTap: widget.onBookingSelected,
                ),
                ImmersiveCategory(
                  title: 'Settings',
                  subtitle: 'Preferences & theme',
                  icon: Icons.settings_rounded,
                  gradientColors: const [
                    Color(0xFF43E97B), // Emerald
                    Color(0xFF38F9D7), // Mint
                  ],
                  onTap: widget.onSettingsSelected ?? () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TextTheme themeText(BuildContext context) => Theme.of(context).textTheme;
}

/// A row of quick-action chips (Call, WhatsApp) shown under the hero banner on
/// the Home screen. Uses url_launcher to open the relevant app. The contact
/// number comes from the website's contact_data.json (footerContact.phone).
class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.phoneNumber});

  /// The Gurdwara contact number (e.g. "+6016-666 5513") from contact_data.json.
  final String phoneNumber;

  /// Strips everything except digits, for use in wa.me links.
  String get _digitsOnly => phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

  Future<void> _launch(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }

  Future<void> _launchWhatsApp(BuildContext context) async {
    final phone = Uri.encodeQueryComponent(_digitsOnly);
    final whatsappUri = Uri.parse('whatsapp://send?phone=$phone');
    final openedWhatsApp = await launchUrl(
      whatsappUri,
      mode: LaunchMode.externalApplication,
    );
    if (openedWhatsApp || !context.mounted) return;

    final fallbackUri = Uri.parse('https://wa.me/$_digitsOnly');
    final openedFallback = await launchUrl(
      fallbackUri,
      mode: LaunchMode.externalApplication,
    );
    if (!openedFallback && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.call_rounded,
        label: LocalizationService.instance.t('call'),
        color: const Color(0xFF43E97B),
        onTap: () => _launch(context, 'tel:$phoneNumber'),
      ),
      _QuickAction(
        icon: Icons.chat_rounded,
        label: LocalizationService.instance.t('whatsapp'),
        color: const Color(0xFF25D366),
        onTap: () => _launchWhatsApp(context),
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          Expanded(child: actions[i]),
          if (i != actions.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}


class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A reusable card with immersive gradient styling (matching the category grid aesthetic).

/// Wraps any child widget with a vibrant gradient background, soft shadows,
/// and decorative geometric shapes.
class _ImmersiveInfoCard extends StatelessWidget {
  const _ImmersiveInfoCard({
    required this.gradientColors,
    required this.child,
  });

  final List<Color> gradientColors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                ),
              ),
            ),
            // Decorative shapes
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: gradientColors.length > 1
                      ? gradientColors[1].withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(60),
                ),
              ),
            ),
            Positioned(
              left: -10,
              bottom: 30,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            Positioned(
              right: 10,
              bottom: 40,
              child: Transform.rotate(
                angle: 30 * 3.14159 / 180,
                child: Container(
                  width: 80,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            // Content (not Positioned.fill - let it size naturally)
            Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared barsi fetch logic — single source of truth used by _BarsiFullContent
// ---------------------------------------------------------------------------

/// Fetches and parses the next upcoming Barsi event from the website's
/// barsidates.txt. Shared by all Barsi UI widgets to avoid duplicate requests.
Future<_BarsiEvent> _fetchNextBarsi() async {
  const barsidatesUrl = '$_siteBaseUrl/barsidates.txt';
  final response = await _dio.get<String>(barsidatesUrl);
  final text = response.data ?? '';
  final lines = text.trim().split('\n');
  final now = DateTime.now();
  _BarsiEvent? targetEvent;

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    final parts = trimmed.split('|');
    if (parts.length < 4) continue;

    final year = int.tryParse(parts[0].trim());
    final startDay = int.tryParse(parts[1].trim());
    final endDay = int.tryParse(parts[2].trim());
    final ordinal = parts[3].trim();
    // Optional month field (5th token); defaults to May (5) if absent
    final month = parts.length > 4 ? (int.tryParse(parts[4].trim()) ?? 5) : 5;

    if (year == null || startDay == null || endDay == null) continue;

    final startDate = DateTime(year, month, startDay);
    final endDate = DateTime(year, month, endDay + 1);

    if (now.isBefore(endDate)) {
      targetEvent = _BarsiEvent(
        ordinal: ordinal,
        startDay: startDay,
        endDay: endDay,
        year: year,
        month: month,
        startDate: startDate,
        endDate: endDate,
      );
      break;
    }
  }

  // If all events have passed, fall back to the last entry
  if (targetEvent == null && lines.isNotEmpty) {
    for (final line in lines.reversed) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final parts = trimmed.split('|');
      if (parts.length < 4) continue;
      final year = int.tryParse(parts[0].trim());
      final startDay = int.tryParse(parts[1].trim());
      final endDay = int.tryParse(parts[2].trim());
      final ordinal = parts[3].trim();
      final month = parts.length > 4 ? (int.tryParse(parts[4].trim()) ?? 5) : 5;
      if (year == null || startDay == null || endDay == null) continue;
      targetEvent = _BarsiEvent(
        ordinal: ordinal,
        startDay: startDay,
        endDay: endDay,
        year: year,
        month: month,
        startDate: DateTime(year, month, startDay),
        endDate: DateTime(year, month, endDay + 1),
      );
      break;
    }
  }

  if (targetEvent == null) {
    throw Exception('No barsi dates available.');
  }

  return targetEvent;
}

/// Full-content widget for the Barsi immersive card.
/// Replaces the entire foreground (icon, title, subtitle) with
/// ordinal, date range, and countdown fetched from barsidates.txt.
class _BarsiFullContent extends StatefulWidget {
  const _BarsiFullContent({required this.parallax});

  final Animation<Offset> parallax;

  @override
  State<_BarsiFullContent> createState() => _BarsiFullContentState();
}

class _BarsiFullContentState extends State<_BarsiFullContent> {
  late Future<_BarsiEvent> _future;


  @override
  void initState() {
    super.initState();
    _future = _fetchNextBarsi();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BarsiEvent>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white54,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final event = snapshot.data!;
        final now = DateTime.now();
        final isActive = now.isAfter(event.startDate) && now.isBefore(event.endDate);
        final isPassed = now.isAfter(event.endDate);

        String countdownText;
        if (isActive) {
          countdownText = 'Ongoing now!';
        } else if (isPassed) {
          countdownText = 'See you next year!';
        } else {
          final diff = event.startDate.difference(now);
          final days = diff.inDays;
          final hours = diff.inHours % 24;
          if (days == 0 && hours == 0) {
            countdownText = 'Today!';
          } else if (days == 0) {
            countdownText = 'Today, ${hours}h left';
          } else if (days == 1) {
            countdownText = '1 day, ${hours}h left';
          } else {
            countdownText = '$days days, ${hours}h left';
          }
        }

        final monthNames = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Ordinal
            AnimatedBuilder(
              animation: widget.parallax,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -widget.parallax.value.dy * 0.5),
                  child: child,
                );
              },
              child: Text(
                '${event.ordinal} Barsi',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            // Date range — uses event.month (not hardcoded index 4)
            AnimatedBuilder(
              animation: widget.parallax,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -widget.parallax.value.dy * 0.3),
                  child: child,
                );
              },
              child: Text(
                '${event.startDay} - ${event.endDay} ${monthNames[event.month - 1]} ${event.year}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
            // Countdown badge with glassmorphism
            AnimatedBuilder(
              animation: widget.parallax,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -widget.parallax.value.dy * 0.2),
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Text(
                      countdownText,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BarsiEvent {
  const _BarsiEvent({
    required this.ordinal,
    required this.startDay,
    required this.endDay,
    required this.year,
    required this.month,
    required this.startDate,
    required this.endDate,
  });

  final String ordinal;
  final int startDay;
  final int endDay;
  final int year;
  /// Calendar month (1–12). Defaults to 5 (May) when not specified in data.
  final int month;
  final DateTime startDate;
  final DateTime endDate;
}

class UpcomingEventsCard extends StatefulWidget {
  const UpcomingEventsCard({super.key, required this.events});

  final List<HomepageEvent> events;

  @override
  State<UpcomingEventsCard> createState() => _UpcomingEventsCardState();
}

class _UpcomingEventsCardState extends State<UpcomingEventsCard> {
  List<HomepageEvent> get _filteredEvents {
    final today = dateOnly(DateTime.now());
    // Show a rolling window from today (three-day minimum), expanding to the
    // next Sunday on non-weekend days. Saturday shows through Monday and
    // Sunday shows through Tuesday. Started Akhand Path runs are expanded to
    // include all their remaining days.
    return filterUpcomingWindow(widget.events, today);
  }

  @override
  Widget build(BuildContext context) {
    final events = _filteredEvents;
    final theme = Theme.of(context);

    // Group the week's events into runs so a multi-day event (e.g. Akhand
    // Path) renders as a single card listing its remaining days.
    final runs = <String, List<HomepageEvent>>{};
    var selfKey = 0;
    for (final event in events) {
      final key = event.runId.isEmpty ? '_self${selfKey++}' : event.runId;
      runs.putIfAbsent(key, () => []).add(event);
    }
    // Sort runs so that live entries float to the top, then by start time (so
    // two same-day events at 9am and 4pm appear by time), then by date. A run
    // with any currently-live day is promoted to the top.
    final runList = runs.values.toList()
      ..sort((a, b) => compareEntriesLiveNow(a, b, DateTime.now()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Events',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        if (events.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Column(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  size: 40,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 10),
                Text(
                  'No events this week',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Check the calendar for upcoming events.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < runList.length; i++) ...[
                if (runList[i].length > 1)
                  _EventRunCard(days: runList[i])
                else
                  _HomepageEventTile(event: runList[i].first),
                if (i != runList.length - 1) const SizedBox(height: 6),
              ],
            ],
          ),
      ],
    );
  }
}

class _SplashLoading extends StatefulWidget {
  const _SplashLoading();

  @override
  State<_SplashLoading> createState() => _SplashLoadingState();
}

class _SplashLoadingState extends State<_SplashLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 128,
        height: 128,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Branded gradient ring around the logo with a gentle pulse
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                return Container(
                  width: 88,
                  height: 88,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFE8A838), // Saffron
                        Color(0xFF1B365D), // Navy
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE8A838)
                            .withValues(alpha: 0.25 + 0.25 * _pulse.value),
                        blurRadius: 18 + 10 * _pulse.value,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      _siteLogoAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.temple_buddhist,
                          size: 40,
                          color: Theme.of(context).colorScheme.primary,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



/// A card that collapses a consecutive-day run (e.g. a 3-day Akhand Path)
/// into a single entry, listing each remaining day inline with its
/// Start / Continue / End label and a red "live" dot on the active day.
class _EventRunCard extends StatelessWidget {
  const _EventRunCard({required this.days});

  final List<HomepageEvent> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = dateOnly(now);

    final sorted = [...days]..sort((a, b) => a.date.compareTo(b.date));
    final first = sorted.first;
    final last = sorted.last;
    final firstDayOffset = dateOnly(first.date).difference(today).inDays;
    final palette = _eventPalette(theme, firstDayOffset, firstDayOffset == 0);

    String dateRange;
    if (first.date.year == last.date.year &&
        first.date.month == last.date.month) {
      dateRange = '${DateFormat('d').format(first.date)} – '
          '${DateFormat('d MMM yyyy').format(last.date)}';
    } else {
      dateRange = '${DateFormat('d MMM').format(first.date)} – '
          '${DateFormat('d MMM yyyy').format(last.date)}';
    }

    return Card(
      margin: EdgeInsets.zero,
      color: palette.background,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: palette.border),
        borderRadius: BorderRadius.circular(12),
      ),
      shadowColor: palette.border.withValues(alpha: 0.16),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    first.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.foreground,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dateRange,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: palette.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (first.details.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                first.details,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.foreground,
                ),
              ),
            ],
            const SizedBox(height: 6),
            for (final day in sorted)
              // Each day's red indicator is lit independently: day 1 from its
              // start time to 23:59, middle days 00:00-23:59, and the last day
              // from 00:00 to its start time + 4 hours.
              _dayLine(theme, palette, day, today, now),
          ],
        ),
      ),
    );
  }

  Widget _dayLine(
    ThemeData theme,
    _EventPalette palette,
    HomepageEvent day,
    DateTime today,
    DateTime now,
  ) {
    final isToday = dateOnly(day.date) == today;
    final isLive =
        day.isAkhandPath ? isAkhandDayLive(day, now) : isNowLive(day, now);
    final showLiveDot = isToday && isLive;

    final String label;
    if (isToday && isLive) {
      label = day.status == 'single'
          ? 'TODAY'
          : 'TODAY · ${_statusLabel(day).toUpperCase()}';
    } else {
      label = _statusLabel(day);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            showLiveDot ? Icons.circle : Icons.circle_outlined,
            size: 10,
            color: showLiveDot
                ? const Color(0xFFD32F2F)
                : palette.foreground.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 6),
          Text(
            DateFormat('d MMM').format(day.date),
            style: theme.textTheme.labelMedium?.copyWith(
              color: palette.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: theme.textTheme.labelMedium?.copyWith(
                color: palette.foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomepageEventTile extends StatelessWidget {
  const _HomepageEventTile({required this.event});

  final HomepageEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = dateOnly(DateTime.now()); // ⭐ Changed from _dateOnly
    final eventDate = dateOnly(event.date); // ⭐ Changed from _dateOnly
    final isToday = eventDate == today;
    final dayOffset = eventDate.difference(today).inDays;
    final palette = _eventPalette(theme, dayOffset, isToday);

    return Card(
      margin: EdgeInsets.zero,
      color: palette.background,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: palette.border),
        borderRadius: BorderRadius.circular(12),
      ),
      shadowColor: palette.border.withValues(alpha: 0.16),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.foreground,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('d MMM yyyy').format(event.date),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: palette.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (event.details.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                event.details,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.foreground,
                ),
              ),
            ],
            if (isToday &&
                (event.isAkhandPath
                    ? isAkhandDayLive(event, DateTime.now())
                    : isNowLive(event, DateTime.now()))) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      event.status == 'single'
                          ? 'TODAY'
                          : 'TODAY · ${_statusLabel(event).toUpperCase()}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: palette.foreground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: palette.foreground,
                ),
                icon: const Icon(Icons.calendar_today, size: 13),
                label: const Text('Add to Calendar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  final calendarEvent = Event(
                    title: event.title,
                    description: event.details,
                    location: 'Gurdwara Sahib Melaka',
                    startDate: event.date,
                    endDate: event.date.add(const Duration(hours: 2)),
                  );
                  Add2Calendar.addEvent2Cal(calendarEvent);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventPalette {
  const _EventPalette({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}

_EventPalette _eventPalette(ThemeData theme, int dayOffset, bool isToday) {
  if (isToday) {
    return _EventPalette(
      background: const Color(0xFF2E7D32),
      border: const Color(0xFF1B5E20),
      foreground: Colors.white,
    );
  }

  switch (dayOffset) {
    case 1:
      return _EventPalette(
        background: const Color(0xFF1565C0),
        border: const Color(0xFF0D47A1),
        foreground: Colors.white,
      );
    case 2:
      return _EventPalette(
        background: const Color(0xFFF2C94C),
        border: const Color(0xFFB58B1F),
        foreground: const Color(0xFF1D1A17),
      );
    default:
      return _EventPalette(
        background: const Color(0xFFC94B4B),
        border: const Color(0xFF8E2D2D),
        foreground: Colors.white,
      );
  }
}

class HomepageEvent {
  HomepageEvent({
    required this.title,
    required this.date,
    required this.details,
    required this.imagePath,
    this.host = '',
    this.startAt,
    this.status = 'single',
    this.runId = '',
  });

  final String title;
  final DateTime date;
  final String details;
  final String imagePath;

  /// Host extracted from the description (e.g. "Jagraj Singh (Sg)").
  final String host;

  /// The parsed start datetime (event date + "@9am" time), or null if none.
  final DateTime? startAt;

  /// Run position within a consecutive-day group:
  /// 'single' | 'start' | 'cont' | 'end'.
  String status;

  /// ID shared by all events belonging to the same consecutive-day run.
  String runId;

  String? get imageUrl => imagePath.isEmpty ? null : imagePath;

  bool get isAkhandPath => title.toLowerCase().contains('akhand path');

  bool get isAsaDiVaar => title.trim().toLowerCase() == 'asa di vaar';
}

// lib/main.dart

const String _eventsCacheKey = 'events';

/// Fetches the events list, with offline caching:
/// 1. First tries the network (with a 10s timeout via _dio)
/// 2. On success, caches the raw response text
/// 3. On network failure, falls back to the cached copy (if any)
Future<List<HomepageEvent>> _fetchUpcomingEvents() async {
  final events = await _fetchEventsWithCache();
  if (events.isEmpty) {
    throw Exception('No upcoming events found.');
  }

  final today = dateOnly(DateTime.now());
  final upcoming = events.where((event) {
    final eventDate = dateOnly(event.date);
    return !eventDate.isBefore(today);
  }).toList();

  return upcoming.isNotEmpty ? upcoming : events;
}

Future<List<HomepageEvent>> _fetchAllEvents() async {
  final events = await _fetchEventsWithCache();
  if (events.isEmpty) {
    throw Exception('No events found.');
  }
  return events;
}

/// Shared cache-aware fetcher for the events file.
Future<List<HomepageEvent>> _fetchEventsWithCache() async {
  try {
    final response = await _dio.get<String>(_eventsUrl);
    final text = response.data ?? '';
    final events = parseHomepageEvents(text);

    if (events.isNotEmpty) {
      // Cache the raw text for offline use.
      await CacheService.instance.putWithTimestamp(_eventsCacheKey, text);
    }

    return events;
  } on Exception {
    // Network failure — try cached copy (if any).
    final cached = await CacheService.instance.get(
      _eventsCacheKey,
      maxAge: const Duration(days: 7),
    );
    if (cached != null && cached.isNotEmpty) {
      return parseHomepageEvents(cached);
    }
    rethrow;
  }
}

Map<DateTime, List<HomepageEvent>> _groupEventsByDate(List<HomepageEvent> events) {
  final grouped = <DateTime, List<HomepageEvent>>{};

  for (final event in events) {
    final key = dateOnly(event.date); // ⭐ Changed from _dateOnly
    grouped.putIfAbsent(key, () => <HomepageEvent>[]).add(event);
  }

  return grouped;
}

/// Host extracted from a description, mirroring the website's `extractHost`.
String _extractHost(String description) {
  final m = RegExp(r'by\s+([^@\n]+)', caseSensitive: false).firstMatch(description);
  if (m == null) return '';
  final host = m.group(1)!.trim().replaceAll(RegExp(r'\s+'), ' ');
  return host.isEmpty ? '' : host;
}

/// Parses an "@9am" / "@6.30am" / "@3.30pm" style time from a description and
/// returns the full DateTime on the given event date, or null if no time found.
DateTime? parseStartAt(String details, DateTime date) {
  final m = RegExp(r'@\s*(\d{1,2}(?:\.\d{1,2})?)\s*([ap])m',
          caseSensitive: false)
      .firstMatch(details);
  if (m == null) return null;

  final timePart = m.group(1)!;
  final isPm = m.group(2)!.toLowerCase() == 'p';

  int hour;
  int minute = 0;
  if (timePart.contains('.')) {
    final parts = timePart.split('.');
    hour = int.parse(parts[0]);
    minute = int.parse(parts[1]);
  } else {
    hour = int.parse(timePart);
  }

  if (isPm && hour != 12) hour += 12;
  if (!isPm && hour == 12) hour = 0;

  return DateTime(date.year, date.month, date.day, hour, minute);
}

/// Group key used to chain consecutive-day events (title + host parity with
/// the website's `getGroupKey`).
String _groupKeyFor(HomepageEvent e) {
  final title = e.title.toLowerCase().trim();
  final host = e.host.toLowerCase().trim();
  return host.isEmpty ? title : '$title|$host';
}

bool _isConsecutiveDay(DateTime a, DateTime b) {
  return dateOnly(b).difference(dateOnly(a)).inDays == 1;
}

/// Groups events by title+host, sorts each group by date, and assigns each
/// event a [status] ('single'/'start'/'cont'/'end') and a shared [runId].
void _assignRunMetadata(List<HomepageEvent> events) {
  final groups = <String, List<HomepageEvent>>{};
  for (final event in events) {
    groups.putIfAbsent(_groupKeyFor(event), () => []).add(event);
  }

  var runCounter = 0;
  for (final group in groups.values) {
    if (group.isEmpty) continue;
    group.sort((a, b) => a.date.compareTo(b.date));

    final runId = 'run${runCounter++}';
    for (var i = 0; i < group.length; i++) {
      final curr = group[i];
      final prev = i > 0 ? group[i - 1] : null;
      final next = i < group.length - 1 ? group[i + 1] : null;

      final isStart = prev == null || !_isConsecutiveDay(prev.date, curr.date);
      final isEnd = next == null || !_isConsecutiveDay(curr.date, next.date);

      String status;
      if (isStart && !isEnd) {
        status = 'start';
      } else if (!isStart && !isEnd) {
        status = 'cont';
      } else if (!isStart && isEnd) {
        status = 'end';
      } else {
        status = 'single';
      }

      curr.status = status;
      // Only Akhand Path is a genuine continuous multi-day programme — assign
      // a shared runId so it collapses into one card. Other events (e.g. Asa
      // Di Vaar) keep an empty runId so each day renders as its own card.
      curr.runId = curr.isAkhandPath ? runId : '';
    }
  }
}

/// True when [now] falls inside [start] .. [start + hours].
bool _inLiveWindow(DateTime start, DateTime now, int hours) {
  final end = start.add(Duration(hours: hours));
  return !now.isBefore(start) && now.isBefore(end);
}

/// Per-event live (red dot) check for single-day events.
/// - Asa Di Vaar: 2 hours from its start time.
/// - Everything else: 4 hours from its start time.
bool isNowLive(HomepageEvent e, DateTime now) {
  final start = e.startAt;
  if (start == null) return false;
  final hours = e.isAsaDiVaar ? 2 : 4;
  return _inLiveWindow(start, now, hours);
}

/// Per-day live (red dot) check for a multi-day Akhand Path, based on the
/// programme's times on that specific day:
/// - First day ('start'): lit from its start time through 23:59.
/// - Middle days ('cont'): lit from 00:00 through 23:59.
/// - Last day ('end'): lit from 00:00 through its start time + 4 hours.
/// - Single-day Akhand Path: lit from its start time through +4 hours.
bool isAkhandDayLive(HomepageEvent day, DateTime now) {
  final start = day.startAt;
  final dayStart = dateOnly(day.date);
  final dayEnd = dayStart.add(const Duration(days: 1));
  switch (day.status) {
    case 'start':
      if (start == null) return false;
      return !now.isBefore(start) && now.isBefore(dayEnd);
    case 'cont':
      return !now.isBefore(dayStart) && now.isBefore(dayEnd);
    case 'end':
      if (start == null) return false;
      return !now.isBefore(dayStart) &&
          now.isBefore(start.add(const Duration(hours: 4)));
    default: // 'single'
      if (start == null) return false;
      return _inLiveWindow(start, now, 4);
  }
}

/// True when any entry in a run list is currently live. A single-day entry
/// uses its own live check; a multi-day Akhand Path is live when any of its
/// days is currently lit.
bool _entriesLiveNow(List<HomepageEvent> days, DateTime now) {
  if (days.length == 1) {
    final e = days.first;
    return e.isAkhandPath ? isAkhandDayLive(e, now) : isNowLive(e, now);
  }
  for (final day in days) {
    if (day.isAkhandPath && isAkhandDayLive(day, now)) return true;
  }
  return false;
}

/// The earliest non-null start time across a run list.
DateTime? _entriesStartAt(List<HomepageEvent> days) {
  for (final day in days) {
    if (day.startAt != null) return day.startAt;
  }
  return null;
}

/// Sort comparator for the home "Upcoming Events" run list: live entries
/// first, then by start time, then by date. Keeps two same-day events (e.g.
/// 9am and 4pm) in time order until one goes live, at which point it floats to
/// the top, then falls back to time order once its +4h window ends.
int compareEntriesLiveNow(
    List<HomepageEvent> a, List<HomepageEvent> b, DateTime now) {
  final aLive = _entriesLiveNow(a, now);
  final bLive = _entriesLiveNow(b, now);
  if (aLive != bLive) return aLive ? -1 : 1;

  final aTime = _entriesStartAt(a);
  final bTime = _entriesStartAt(b);
  if (aTime != null && bTime != null && aTime != bTime) {
    return aTime.compareTo(bTime);
  }

  return a.first.date.compareTo(b.first.date);
}

/// Plain label for a run position (used for non-live days).
String _statusLabel(HomepageEvent e) {
  switch (e.status) {
    case 'start':
      return 'Start';
    case 'cont':
      return 'Continue';
    case 'end':
      return 'End';
    default:
      return 'Today';
  }
}

List<HomepageEvent> parseHomepageEvents(String text) {
  final events = <HomepageEvent>[];

  for (final line in text.split(RegExp(r'\r?\n'))) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      continue;
    }

    final parts = trimmed.split('|');
    if (parts.length < 3) {
      continue;
    }

    final title = parts[0].trim();
    final date = DateTime.tryParse(parts[1].trim());
    final details = parts[2].trim();
    final imagePath = parts.length > 3 ? parts.sublist(3).join('|').trim() : '';

    if (title.isEmpty || date == null) {
      continue;
    }

    final startAt = parseStartAt(details, date);

    events.add(
      HomepageEvent(
        title: title,
        date: date,
        details: details,
        imagePath: imagePath,
        host: _extractHost(details),
        startAt: startAt,
      ),
    );
  }

  _assignRunMetadata(events);

  events.sort((a, b) => a.date.compareTo(b.date));
  return events;
}

DateTime dateOnly(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

/// Returns the inclusive end of the home "Upcoming Events" window.
/// Normally today through the next Sunday, but with a three-day minimum so
/// Saturday reaches Monday and Sunday reaches Tuesday.
DateTime upcomingWindowEnd(DateTime today) {
  final daysUntilSunday = DateTime.sunday - today.weekday;
  final nextSunday = today.add(Duration(days: daysUntilSunday));
  final minEnd = today.add(const Duration(days: 2)); // today + Sunday + next day
  return minEnd.isAfter(nextSunday) ? minEnd : nextSunday;
}

/// Keys an event identity for run-expansion de-duplication.
String _runKey(HomepageEvent e) =>
    e.runId.isNotEmpty
        ? '${e.runId}|${dateOnly(e.date)}'
        : 'single|${e.title}|${dateOnly(e.date)}';

/// Filters [allEvents] to the rolling "this week" window and expands any
/// started Akhand Path run that touches the window to include all of its
/// remaining days (so a Saturday start shows through Monday, and a Sunday
/// start shows through Tuesday).
List<HomepageEvent> filterUpcomingWindow(
    List<HomepageEvent> allEvents, DateTime today) {
  final endOfWindow = upcomingWindowEnd(today);
  final windowEvents = allEvents.where((event) {
    final eventDate = dateOnly(event.date);
    return !eventDate.isBefore(today) && !eventDate.isAfter(endOfWindow);
  }).toList();

  final present = <String, HomepageEvent>{};
  for (final e in windowEvents) {
    present[_runKey(e)] = e;
  }

  final runIds = <String>{};
  for (final e in windowEvents) {
    if (e.isAkhandPath && e.runId.isNotEmpty) runIds.add(e.runId);
  }

  final added = <HomepageEvent>[];
  for (final runId in runIds) {
    for (final full in allEvents.where((e) =>
        e.isAkhandPath &&
        e.runId == runId &&
        !dateOnly(e.date).isBefore(today))) {
      final key = _runKey(full);
      if (present.containsKey(key)) continue;
      present[key] = full;
      added.add(full);
    }
  }

  if (added.isEmpty) return windowEvents;
  final merged = <HomepageEvent>[];
  merged.addAll(windowEvents);
  merged.addAll(added);
  merged.sort((a, b) => a.date.compareTo(b.date));
  return merged;
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late Future<List<HomepageEvent>> _future;
  int _monthOffset = 0;
  bool _showListView = false;

  @override
  void initState() {
    super.initState();
    _future = _fetchAllEvents();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _fetchAllEvents();
    });
    await _future;
  }

  DateTime get _visibleMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + _monthOffset, 1);
  }

  void _previousMonth() {
    setState(() {
      _monthOffset--;
    });
  }

  void _nextMonth() {
    setState(() {
      _monthOffset++;
    });
  }

  void _jumpToToday() {
    setState(() {
      _monthOffset = 0;
    });
  }

  /// Returns only events from today onwards (for the list view).
  List<HomepageEvent> _filterUpcomingEvents(List<HomepageEvent> events) {
    final today = dateOnly(DateTime.now());
    return events.where((event) {
      return !dateOnly(event.date).isBefore(today);
    }).toList();
  }

  void _showDateDetails(
    BuildContext context,
    DateTime date,
    List<HomepageEvent> events,
  ) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close details',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final theme = Theme.of(dialogContext);

        return Material(
          color: Colors.transparent,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(dialogContext).pop(),
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: Card(
                  margin: const EdgeInsets.all(24),
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, d MMMM yyyy').format(date),
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          if (events.isEmpty)
                            Text(
                              'No events on this date.',
                              style: theme.textTheme.bodyMedium,
                            )
                          else
                            Column(
                              children: [
                                for (var i = 0; i < events.length; i++) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer
                                          .withValues(alpha: 0.45),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          events[i].title,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          events[i].details.isEmpty
                                              ? 'No extra details available.'
                                              : events[i].details,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (i != events.length - 1)
                                    const SizedBox(height: 8),
                                ],
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<HomepageEvent>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const CustomScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _SplashLoading(),
                ),
              ],
            );
          }

          if (snapshot.hasError) {
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  title: Text(
                    'Calendar',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorState(
                    title: 'Unable to load calendar',
                    message: 'Pull down to refresh the latest website data.',
                    onRetry: _refresh,
                  ),
                ),
              ],
            );
          }

          final events = snapshot.data ?? <HomepageEvent>[];
          final groupedEvents = _groupEventsByDate(events);

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                elevation: 0,
                title: Text(
                  'Calendar',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                actions: [
                  // Toggle between month grid and list view
                  IconButton(
                    tooltip: _showListView ? 'Show month grid' : 'Show event list',
                    icon: Icon(
                      _showListView
                          ? Icons.calendar_month_outlined
                          : Icons.view_list_rounded,
                    ),
                    onPressed: () {
                      setState(() {
                        _showListView = !_showListView;
                      });
                    },
                  ),
                ],
              ),
              if (_showListView)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        // Today button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _jumpToToday,
                            icon: const Icon(Icons.today_rounded, size: 18),
                            label: const Text('Today'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_filterUpcomingEvents(events).isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.event_busy_rounded,
                                  size: 56,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No upcoming events.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else
                          ..._filterUpcomingEvents(events).map(
                            (event) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Card(
                                margin: EdgeInsets.zero,
                                child: ListTile(
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                          .withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${event.date.day}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        Text(
                                          DateFormat('MMM')
                                              .format(event.date)
                                              .toUpperCase(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  title: Text(
                                    event.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: event.details.isEmpty
                                      ? null
                                      : Text(
                                          event.details,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                  onTap: () {
                                    _showDateDetails(
                                      context,
                                      event.date,
                                      [event],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _CalendarMonthCard(
                      month: _visibleMonth,
                      groupedEvents: groupedEvents,
                      onPreviousMonth: _previousMonth,
                      onNextMonth: _nextMonth,
                      onToday: _jumpToToday,
                      onDateSelected: (date, eventsForDate) {
                        _showDateDetails(context, date, eventsForDate);
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CalendarMonthCard extends StatelessWidget {
  const _CalendarMonthCard({
    required this.month,
    required this.groupedEvents,
    required this.onPreviousMonth,
    required this.onNextMonth,
    this.onToday,
    required this.onDateSelected,
  });

  final DateTime month;
  final Map<DateTime, List<HomepageEvent>> groupedEvents;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback? onToday;
  final void Function(DateTime date, List<HomepageEvent> events) onDateSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final leadingDays = (firstOfMonth.weekday + 6) % 7;
    final startDate = firstOfMonth.subtract(Duration(days: leadingDays));
    final today = dateOnly(DateTime.now()); // ⭐ Changed from _dateOnly

    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onPreviousMonth,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    DateFormat('MMMM yyyy').format(month),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: onNextMonth,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: const [
                Expanded(child: _WeekdayLabel(label: 'Mon')),
                Expanded(child: _WeekdayLabel(label: 'Tue')),
                Expanded(child: _WeekdayLabel(label: 'Wed')),
                Expanded(child: _WeekdayLabel(label: 'Thu')),
                Expanded(child: _WeekdayLabel(label: 'Fri')),
                Expanded(child: _WeekdayLabel(label: 'Sat')),
                Expanded(child: _WeekdayLabel(label: 'Sun')),
              ],
            ),
            const SizedBox(height: 6),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 42,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                final date = startDate.add(Duration(days: index));
                final isCurrentMonth = date.month == month.month;
                final dateKey = dateOnly(date);
                final eventsForDate = groupedEvents[dateKey] ?? const <HomepageEvent>[];
                final hasEvents = eventsForDate.isNotEmpty;
                final isToday = dateKey == today;

                return InkWell(
                  onTap: () => onDateSelected(dateKey, eventsForDate),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isToday
                          ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.85)
                          : hasEvents
                              ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.65)
                              : theme.colorScheme.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isToday
                            ? theme.colorScheme.secondary
                            : hasEvents
                                ? theme.colorScheme.tertiary.withValues(alpha: 0.35)
                                : theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Text(
                            '${date.day}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isCurrentMonth
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                        if (hasEvents)
                          Positioned(
                            right: 6,
                            bottom: 6,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  late Future<_GalleryData> _future;
  String? _selectedCategory;
  final Map<String, int?> _selectedYear = {};

  static const _categoryOrder = [
    'barsi',
    'vaisakhi',
    'youth',
    'cultural',
    'committee',
  ];

  @override
  void initState() {
    super.initState();
    _future = _loadGallery();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedCategory == null) {
        _future.then((data) {
          if (data.categories.isNotEmpty) {
            final firstCategory = data.categories.first;

            _selectedCategory = firstCategory;

            if (data.categoryYears[firstCategory]!.isNotEmpty) {
              _selectedYear[firstCategory] = data.categoryYears[firstCategory]!.first;
            } else {
              _selectedYear[firstCategory] = null;
            }

            setState(() {});
          }
        });
      }
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadGallery();
    });
    await _future;
  }

  Future<_GalleryData> _loadGallery() async {
    final categories = <String>[];
    final categoryImages = <String, Set<_GalleryImage>>{};
    final categoryYears = <String, List<int>>{};

    Future<_GalleryPageResult?> fetchGalleryPage(String event, {int? year}) async {
      final url = '$_siteBaseUrl/ajax_gallery.php?event=$event${year != null ? '&year=$year' : ''}';
      final response = await _dio.get<String>(url);
      final raw = (response.data ?? '').trim();
      if (raw.isEmpty) return null;

      late Map<String, dynamic> data;
      try {
        data = jsonDecode(raw);
      } catch (_) {
        return null;
      }

      final images = <_GalleryImage>[];
      final imagesList = data['images'] as List<dynamic>?;
      if (imagesList != null) {
        for (final item in imagesList) {
          if (item is Map<String, dynamic>) {
            final src = (item['src'] ?? '').toString().trim();
            if (src.isEmpty) continue;

            // Resolve the full-resolution URL
            final lower = src.toLowerCase();
            final String fullUrl;
            if (lower.startsWith('http://') || lower.startsWith('https://')) {
              fullUrl = src;
            } else {
              final path = src.startsWith('/') ? src : '/$src';
              fullUrl = '$_siteBaseUrl$path';
            }

            // Resolve the lightweight thumbnail URL (server-side WebP via thumb.php)
            final thumbRaw = (item['thumb'] ?? '').toString().trim();
            final String thumbUrl;
            if (thumbRaw.isEmpty) {
              // Fall back to the full URL if no thumbnail is provided
              thumbUrl = fullUrl;
            } else if (thumbRaw.startsWith('http://') || thumbRaw.startsWith('https://')) {
              thumbUrl = thumbRaw;
            } else {
              final thumbPath = thumbRaw.startsWith('/') ? thumbRaw : '/$thumbRaw';
              thumbUrl = '$_siteBaseUrl$thumbPath';
            }

            images.add(_GalleryImage(thumbUrl: thumbUrl, fullUrl: fullUrl));
          }
        }
      }
      return _GalleryPageResult(images: images);
    }

    const yearsToCheck = [

      2026, 2025, 2024, 2023, 2022, 2021, 2020,
      2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011, 2010,
    ];

    // Process categories sequentially but fetch all years for each category in parallel
    for (final category in _categoryOrder) {
      categories.add(category);
      final imageSet = <_GalleryImage>{};
      final yearSet = <int>{};
      categoryImages[category] = imageSet;
      categoryYears[category] = [];

      // Fire all year requests for this category simultaneously
      final results = await Future.wait(
        yearsToCheck.map((year) => fetchGalleryPage(category, year: year)),
        eagerError: false,
      );

      for (final page in results) {
        if (page == null || page.images.isEmpty) continue;
        for (final image in page.images) {
          imageSet.add(image);
          final match = RegExp(r'/(\d{4})/').firstMatch(image.fullUrl);
          if (match != null) {
            final yr = int.tryParse(match.group(1) ?? '') ?? 0;
            if (yr != 0) yearSet.add(yr);
          }
        }
      }


      final years = yearSet.toList()..sort((a, b) => b.compareTo(a));
      categoryYears[category] = years;
    }

    // Drop any stored year selection that no longer exists for its category
    // after a (re)load, so the dropdown value always maps to an available item.
    for (final entry in categoryYears.entries) {
      final stored = _selectedYear[entry.key];
      if (stored != null && stored != 0 && !entry.value.contains(stored)) {
        _selectedYear[entry.key] = null;
      }
    }

    return _GalleryData(
      categories: categories,
      categoryImages: categoryImages,
      categoryYears: categoryYears,
    );
  }

  /// Returns the list of gallery images for the currently selected category,
  /// filtered by the selected year (if any).
  List<_GalleryImage> _filteredImages(_GalleryData data) {
    final category = _selectedCategory;
    if (category == null) return const [];

    final all = data.categoryImages[category] ?? const <_GalleryImage>{};
    final selectedYear = _selectedYear[category];

    if (selectedYear == null || selectedYear == 0) {
      return all.toList();
    }

    return all
        .where((image) => image.fullUrl.contains('/$selectedYear/'))
        .toList();
  }

  @override
  Widget build(BuildContext context) {

    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<_GalleryData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const CustomScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _SplashLoading(),
                ),
              ],
            );
          }

          if (snapshot.hasError) {
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  title: Text(
                    'Gallery',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorState(
                    title: 'Unable to load gallery',
                    message: 'Pull down to refresh the latest website data.',
                    onRetry: _refresh,
                  ),
                ),
              ],
            );
          }

          final data = snapshot.data;
          if (data == null || data.categories.isEmpty) {
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  title: Text(
                    'Gallery',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Gallery',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No gallery images available from the website.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Here are some sample gallery images:',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 16 / 9,
                            children: [
                              _GalleryUrlItem(
                                image: _GalleryImage(
                                  thumbUrl: '$_siteBaseUrl/web/logo.png',
                                  fullUrl: '$_siteBaseUrl/web/logo.png',
                                ),
                              ),
                              _GalleryUrlItem(
                                image: _GalleryImage(
                                  thumbUrl: '$_siteBaseUrl/web/favicon.png',
                                  fullUrl: '$_siteBaseUrl/web/favicon.png',
                                ),
                              ),
                              _GalleryUrlItem(
                                image: _GalleryImage(
                                  thumbUrl: 'https://picsum.photos/600/400?random=1',
                                  fullUrl: 'https://picsum.photos/600/400?random=1',
                                ),
                              ),
                              _GalleryUrlItem(
                                image: _GalleryImage(
                                  thumbUrl: 'https://picsum.photos/600/400?random=2',
                                  fullUrl: 'https://picsum.photos/600/400?random=2',
                                ),
                              ),
                            ],

                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _refresh,
                          child: const Text('Refresh Gallery'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                elevation: 0,
                title: Text(
                  'Gallery',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (int i = 0; i < 3 && i < data.categories.length; i++)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _selectedCategory = data.categories[i];
                                          _selectedYear[data.categories[i]] = null;
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        backgroundColor: _selectedCategory == data.categories[i]
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                                        foregroundColor: _selectedCategory == data.categories[i]
                                            ? Colors.white
                                            : Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      child: Text(
                                        _capitalize(data.categories[i]),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (data.categories.length > 3)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (int i = 3; i < data.categories.length; i++)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _selectedCategory = data.categories[i];
                                            _selectedYear[data.categories[i]] = null;
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          backgroundColor: _selectedCategory == data.categories[i]
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                                          foregroundColor: _selectedCategory == data.categories[i]
                                              ? Colors.white
                                              : Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                        child: Text(
                                          _capitalize(data.categories[i]),
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_selectedCategory != null && data.categoryYears[_selectedCategory]!.isNotEmpty)
                        Builder(
                          builder: (context) {
                            final category = _selectedCategory!;
                            final yearList = data.categoryYears[category]!;
                            final current = _selectedYear[category];
                            // Only select a year that still exists in this option set;
                            // otherwise fall back to "All years" (0). The unique key forces
                            // the FormField to reset its internal selection whenever the
                            // option set changes, so a stale year can never violate the
                            // "exactly one item" assertion.
                            final initialValue =
                                (current != null && yearList.contains(current))
                                    ? current
                                    : 0;
                            return DropdownButtonFormField<int>(
                              key: ValueKey<String>('$category:${yearList.join(',')}'),
                              initialValue: initialValue,
                              decoration: InputDecoration(
                                labelText: 'Filter by year',
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: [
                                const DropdownMenuItem<int>(
                                  value: 0,
                                  child: Text('All years'),
                                ),
                                for (final year in yearList)
                                  DropdownMenuItem<int>(
                                    value: year,
                                    child: Text('$year'),
                                  ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedYear[category] = value;
                                  });
                                }
                              },
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              // Lazy-loading grid: only builds tiles that are near the viewport,
              // so off-screen images are not fetched until scrolled into view.
              if (_selectedCategory != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 16 / 9,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final images = _filteredImages(data);
                        return _GalleryUrlItem(
                          image: images[index],
                          images: images,
                          initialIndex: index,
                        );
                      },
                      childCount: _filteredImages(data).length,
                    ),
                  ),
                ),
              if (_selectedCategory != null && _filteredImages(data).isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No images in this category.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
            ],
          );

        },
      ),
    );
  }
}

/// A single gallery image with a lightweight thumbnail URL (for the grid)
/// and the full-resolution URL (for the full-screen viewer).
class _GalleryImage {
  const _GalleryImage({required this.thumbUrl, required this.fullUrl});

  final String thumbUrl;
  final String fullUrl;
}

class _GalleryPageResult {
  const _GalleryPageResult({required this.images});

  final List<_GalleryImage> images;
}

class _GalleryData {
  const _GalleryData({
    required this.categories,
    required this.categoryImages,
    required this.categoryYears,
  });

  final List<String> categories;
  final Map<String, Set<_GalleryImage>> categoryImages;
  final Map<String, List<int>> categoryYears;
}


String _capitalize(String input) {
  if (input.isEmpty) return input;
  final trimmed = input.trim();
  if (trimmed.isEmpty) return trimmed;
  return '${trimmed[0].toUpperCase()}${trimmed.substring(1).toLowerCase()}';
}

class _GalleryUrlItem extends StatelessWidget {
  const _GalleryUrlItem({
    required this.image,
    this.images = const [],
    this.initialIndex = 0,
  });

  final _GalleryImage image;

  /// The full list of images in the current filtered set, used to enable
  /// swipe-between-photos in the full-screen viewer.
  final List<_GalleryImage> images;

  /// The index of [image] within [images], used as the starting page.
  final int initialIndex;

  void _openFullScreen(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close image',
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        // If we have a full set, use a swipeable PageView; otherwise fall back
        // to a single image.
        final hasSet = images.length > 1;
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Full-screen viewer: PageView for swipe-between-photos, each
              // page wrapped in InteractiveViewer for pinch-to-zoom.
              Positioned.fill(
                child: hasSet
                    ? PageView.builder(
                        controller: PageController(initialPage: initialIndex),
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return _FullScreenImage(
                            image: images[index],
                            onTap: () => Navigator.of(dialogContext).pop(),
                          );
                        },
                      )
                    : _FullScreenImage(
                        image: image,
                        onTap: () => Navigator.of(dialogContext).pop(),
                      ),
              ),
              // Close button at top-right
              Positioned(
                top: MediaQuery.of(dialogContext).padding.top + 8,
                right: 12,
                child: SafeArea(
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black38,
                    ),
                  ),
                ),
              ),
              // Counter indicator (e.g. "3 / 24") when swiping through a set
              if (hasSet)
                Positioned(
                  bottom: MediaQuery.of(dialogContext).padding.bottom + 16,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${initialIndex + 1} / ${images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onTap: () => _openFullScreen(context),
          child: CachedNetworkImage(
            // Grid uses the lightweight server-side WebP thumbnail.
            imageUrl: image.thumbUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            // Decode the thumbnail at a small size to save memory & speed up rendering.
            memCacheWidth: 400,
            memCacheHeight: 400,
            placeholder: (context, url) => const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),


            errorWidget: (context, url, error) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 8),
                  Text(image.thumbUrl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single full-screen image with pinch-to-zoom, used inside the swipeable
/// PageView. Tapping closes the viewer.
class _FullScreenImage extends StatelessWidget {
  const _FullScreenImage({required this.image, required this.onTap});

  final _GalleryImage image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        panEnabled: true,
        boundaryMargin: const EdgeInsets.all(80),
        child: Center(
          child: CachedNetworkImage(
            imageUrl: image.fullUrl,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            memCacheWidth: 1600,
            memCacheHeight: 1600,
            progressIndicatorBuilder: (context, url, progress) => const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.broken_image,
                  size: 48,
                  color: Colors.white54,
                ),
                const SizedBox(height: 12),
                Text(
                  'Unable to load image',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class WebsitePageScreen extends StatefulWidget {
  const WebsitePageScreen({super.key, required this.spec});

  final WebsitePageSpec spec;

  @override
  State<WebsitePageScreen> createState() => _WebsitePageScreenState();
}

class _WebsitePageScreenState extends State<WebsitePageScreen> {
  late Future<WebsitePageData> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchWebsitePage(widget.spec.url);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _fetchWebsitePage(widget.spec.url);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<WebsitePageData>(
        future: _future,
        builder: (context, snapshot) {
          final slivers = <Widget>[
            SliverAppBar(
              pinned: true,
              elevation: 0,
              title: Text(
                widget.spec.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _SplashLoading(),
              )
            else if (snapshot.hasError)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _ErrorState(
                  title: 'Unable to load ${widget.spec.title.toLowerCase()}',
                  message: 'Pull down to refresh the latest website data.',
                  onRetry: _refresh,
                ),
              )
            else if (snapshot.hasData)
              _buildPageContent(context, snapshot.data!),
          ];

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: slivers,
          );
        },
      ),
    );
  }

  Widget _buildPageContent(BuildContext context, WebsitePageData data) {
    final sections = data.sections.isEmpty
        ? <WebsiteSection>[
            WebsiteSection(title: data.title, summary: data.summary),
          ]
        : data.sections;

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildListDelegate(
          [
            _PageIntroCard(
              icon: widget.spec.icon,
              title: data.title,
              description:
                  data.summary.isEmpty ? widget.spec.description : data.summary,
            ),
            const SizedBox(height: 8),
            ...sections.map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SectionCard(
                  title: section.title,
                  summary: section.summary.isEmpty
                      ? 'Content refreshed from the website.'
                      : section.summary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageIntroCard extends StatelessWidget {
  const _PageIntroCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 36,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.summary,
  });

  final String title;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              summary,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Saffron-tinted icon badge
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8A838).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_off_outlined,
                    size: 36,
                    color: Color(0xFFE8A838),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Gradient Retry button
                FilledButton(
                  onPressed: () => onRetry(),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE8A838),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Retry'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late Future<AboutData> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchAboutData();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _fetchAboutData();
    });
    await _future;
  }

  Future<AboutData> _fetchAboutData() async {
    List<CommitteeMember> committee = [];
    String contactNumber = '';
    String contactPerson = '';
    String contactEmail = '';
    String address = '';
    String mapUrl = '';

    // Offline-first: try the network, fall back to the cached copy.
    String contactRaw;
    try {
      final contactResponse = await _dio.get<String>('$_siteBaseUrl/contact_data.json');
      contactRaw = contactResponse.data ?? '';
      if (contactRaw.isNotEmpty) {
        await CacheService.instance.putWithTimestamp('about_contact', contactRaw);
      }
    } on Exception {
      contactRaw = await CacheService.instance.get(
            'about_contact',
            maxAge: const Duration(days: 7),
          ) ??
          '';
    }

    try {
      final contactJson = jsonDecode(contactRaw.isEmpty ? '{}' : contactRaw);


      final executiveList = contactJson['executiveCommittee'] as List<dynamic>? ?? [];
      for (final member in executiveList) {
        if (member is Map<String, dynamic>) {
          final position = (member['position'] as String? ?? '').trim();
          final name = (member['name'] as String? ?? '').trim();
          if (name.isNotEmpty) {
            committee.add(CommitteeMember(name: name, position: position));
          }
        }
      }

      final committeeMembersList = contactJson['committeeMembersAuditors'] as List<dynamic>? ?? [];
      for (final item in committeeMembersList) {
        if (item is Map<String, dynamic>) {
          final position = (item['position'] as String? ?? '').trim();
          final name = (item['name'] as String? ?? '').trim();
          if (name.isNotEmpty) {
            committee.add(CommitteeMember(name: name, position: position));
          }
        } else if (item is String) {
          final name = item.trim();
          if (name.isNotEmpty) {
            committee.add(CommitteeMember(name: name, position: 'Committee Member'));
          }
        }
      }

      final aboutPage = contactJson['aboutPage'] as Map<String, dynamic>?;
      if (aboutPage != null) {
        contactNumber = (aboutPage['contactPhone'] as String? ?? '').trim();
        contactPerson = (aboutPage['person'] as String? ?? '').trim();
        contactEmail = (aboutPage['email'] as String? ?? '').trim();
      }

      if (contactNumber.isEmpty || contactPerson.isEmpty) {
        final footerContact = contactJson['footerContact'] as Map<String, dynamic>?;
        if (footerContact != null) {
          contactNumber = (footerContact['phone'] as String? ?? contactNumber).trim();
          contactPerson = (footerContact['person'] as String? ?? contactPerson).trim();
        }
      }
      if (contactEmail.isEmpty) {
        final footerContact = contactJson['footerContact'] as Map<String, dynamic>?;
        if (footerContact != null) {
          contactEmail = (footerContact['email'] as String? ?? contactEmail).trim();
        }
      }
    } catch (e) {
      // Continue with empty contact data
    }

    try {
      final footerResponse = await _dio.get<String>('$_siteBaseUrl/footer.php');
      final footerHtml = footerResponse.data ?? '';

      final extractedAddress = _extractAddressFromFooter(footerHtml);
      if (extractedAddress.isNotEmpty) {
        address = extractedAddress;
      }

      mapUrl = _extractMapUrlFromFooter(footerHtml);
    } catch (e) {
      // Continue with whatever data we have
    }

    return AboutData(
      committee: committee,
      address: address,
      contactPerson: contactPerson,
      mapUrl: mapUrl,
      contactNumber: contactNumber,
      contactEmail: contactEmail,
    );
  }

  String _extractAddressFromFooter(String html) {
    final addressRegex = RegExp(r'<address[^>]*>(.*?)</address>', caseSensitive: false, dotAll: true);
    final match = addressRegex.firstMatch(html);
    if (match != null) {
      return _cleanText(match.group(1) ?? '');
    }

    final pRegex = RegExp(r'<p[^>]*>(.*?)</p>', caseSensitive: false, dotAll: true);
    for (final pMatch in pRegex.allMatches(html)) {
      final text = _cleanText(pMatch.group(1) ?? '');
      if (text.contains(RegExp(r'\d+\s+[A-Za-z\s]+,\s+[A-Za-z\s]+,\s+\d+'))) {
        return text;
      }
    }

    return '';
  }

  String _extractMapUrlFromFooter(String html) {
    final lowerHtml = html.toLowerCase();

    final iframeIndex = lowerHtml.indexOf('<iframe');
    if (iframeIndex != -1) {
      final iframeEndIndex = lowerHtml.indexOf('</iframe>', iframeIndex);
      if (iframeEndIndex != -1) {
        final iframeHtml = html.substring(iframeIndex, iframeEndIndex);
        final srcMatch = RegExp(r"""src\s*=\s*["']([^"']+)["']""").firstMatch(iframeHtml);
        if (srcMatch != null) {
          final src = srcMatch.group(1) ?? '';
          if (src.contains('google.com/maps') || src.contains('maps.google')) {
            return src;
          }
        }
      }
    }

    final patterns = [
      'google.com/maps',
      'maps.google',
      'gmap',
      'openstreetmap',
      '/maps/',
    ];

    for (final pattern in patterns) {
      final index = lowerHtml.indexOf(pattern);
      if (index != -1) {
        final before = lowerHtml.substring(0, index);
        final srcStart = before.lastIndexOf('src=');
        if (srcStart != -1) {
          final quoteStart = srcStart + 4;
          final quote = html[quoteStart];
          if (quote == '"' || quote == "'") {
            final endQuote = html.indexOf(quote, quoteStart + 1);
            if (endQuote != -1) {
              final url = html.substring(quoteStart + 1, endQuote);
              if (url.isNotEmpty) return url;
            }
          }
        }
      }
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<AboutData>(
        future: _future,
        builder: (context, snapshot) {
          final slivers = <Widget>[
            SliverAppBar(
              pinned: true,
              elevation: 0,
              title: Text(
                'About',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _SplashLoading(),
              )
            else if (snapshot.hasError)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _ErrorState(
                  title: 'Unable to load about information',
                  message: 'Pull down to refresh the latest website data.',
                  onRetry: _refresh,
                ),
              )
            else if (snapshot.hasData)
              _buildAboutContent(context, snapshot.data!),
          ];

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: slivers,
          );
        },
      ),
    );
  }

  Widget _buildAboutContent(BuildContext context, AboutData data) {
    final theme = Theme.of(context);
    final currentYear = DateTime.now().year;

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildListDelegate(
          [
            if (data.committee.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: _ImmersiveInfoCard(
                  gradientColors: const [
                    Color(0xFF667EEA), // Deep periwinkle
                    Color(0xFF764BA2), // Rich purple
                  ],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Office Bearers',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          for (var i = 0; i < data.committee.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      data.committee[i].name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                                        child: Text(
                                          data.committee[i].position,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.9),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            if (data.committee.isNotEmpty) const SizedBox(height: 16),

            if (data.address.isNotEmpty || data.contactPerson.isNotEmpty || data.contactNumber.isNotEmpty || data.contactEmail.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: _ImmersiveInfoCard(
                  gradientColors: const [
                    Color(0xFF43E97B), // Emerald
                    Color(0xFF38F9D7), // Mint
                  ],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact Information',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (data.address.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Address:',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data.address,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (data.contactPerson.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Contact Person:',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data.contactPerson,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (data.contactNumber.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contact Number:',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data.contactNumber,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      if (data.contactEmail.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Contact Email:',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data.contactEmail,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (data.address.isNotEmpty || data.contactPerson.isNotEmpty || data.contactNumber.isNotEmpty || data.contactEmail.isNotEmpty)
              const SizedBox(height: 16),

            if (data.mapUrl.isNotEmpty)
              Card(
                margin: EdgeInsets.zero,
                color: theme.colorScheme.surfaceContainerHighest,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Map to Location',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: WebViewWidget(
                            controller: WebViewController()
                              ..setJavaScriptMode(JavaScriptMode.unrestricted)
                              ..loadHtmlString('''
                                <!DOCTYPE html>
                                <html>
                                <head>
                                  <meta name="viewport" content="width=device-width, initial-scale=1.0">
                                  <style>
                                    body { margin: 0; padding: 0; }
                                    iframe { width: 100%; height: 100%; border: none; }
                                  </style>
                                </head>
                                <body>
                                  <iframe src="${data.mapUrl}"
                                    width="100%"
                                    height="100%"
                                    style="border:0"
                                    allowfullscreen
                                    loading="lazy"
                                    referrerpolicy="no-referrer-when-downgrade">
                                  </iframe>
                                </body>
                                </html>
                              '''),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Gurdwara Sahib Melaka is open daily.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            if (data.mapUrl.isNotEmpty) const SizedBox(height: 16),

            _AboutFooter(currentYear: currentYear),
          ],
        ),
      ),
    );
  }
}

/// Footer for the About page: shows the copyright line plus the installed
/// app version (read from pubspec.yaml at build time via package_info_plus).
class _AboutFooter extends StatefulWidget {
  const _AboutFooter({required this.currentYear});

  final int currentYear;

  @override
  State<_AboutFooter> createState() => _AboutFooterState();
}

class _AboutFooterState extends State<_AboutFooter> {
  String? _versionText;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    String? text;
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version.trim();
      final build = info.buildNumber.trim();
      text = build.isEmpty ? version : '$version ($build)';
    } catch (_) {
      // If package info can't be read, fall back to showing nothing extra.
      text = null;
    }
    if (mounted) {
      setState(() {
        _versionText = text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
    );

    return Column(
      children: [
        Text(
          '© ${widget.currentYear} Gurdwara Sahib Melaka. All rights reserved.',
          style: muted,
          textAlign: TextAlign.center,
        ),
        if (_versionText != null) ...[
          const SizedBox(height: 4),
          Text(
            'Version $_versionText',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class AboutData {

  const AboutData({
    required this.committee,
    required this.address,
    required this.contactPerson,
    required this.mapUrl,
    required this.contactNumber,
    required this.contactEmail,
  });

  final List<CommitteeMember> committee;
  final String address;
  final String contactPerson;
  final String mapUrl;
  final String contactNumber;
  final String contactEmail;

  factory AboutData.fromJson(Map<String, dynamic> json) {
    final committee = <CommitteeMember>[];
    final committeeList = json['committee'] as List<dynamic>? ?? [];

    for (final member in committeeList) {
      if (member is Map<String, dynamic>) {
        committee.add(CommitteeMember.fromJson(member));
      }
    }

    return AboutData(
      committee: committee,
      address: json['address'] as String? ?? '',
      contactPerson: json['contact_person'] as String? ?? '',
      mapUrl: json['map_url'] as String? ?? '',
      contactNumber: json['contact_number'] as String? ?? json['phone'] as String? ?? '',
      contactEmail: json['email'] as String? ?? '',
    );
  }
}

class CommitteeMember {
  const CommitteeMember({
    required this.name,
    required this.position,
  });

  final String name;
  final String position;

  factory CommitteeMember.fromJson(Map<String, dynamic> json) {
    return CommitteeMember(
      name: json['name'] as String? ?? '',
      position: json['position'] as String? ?? '',
    );
  }
}

class WebsitePageSpec {
  const WebsitePageSpec({
    required this.title,
    required this.url,
    required this.icon,
    required this.description,
  });

  final String title;
  final String url;
  final IconData icon;
  final String description;
}

class WebsitePageData {
  const WebsitePageData({
    required this.title,
    required this.summary,
    required this.sections,
    required this.paragraphs,
  });

  final String title;
  final String summary;
  final List<WebsiteSection> sections;
  final List<String> paragraphs;
}

class WebsiteSection {
  const WebsiteSection({
    required this.title,
    required this.summary,
  });

  final String title;
  final String summary;
}

Future<WebsitePageData> _fetchWebsitePage(String url) async {
  final response = await _dio.get<String>(url);
  final html = response.data ?? '';
  return _parseWebsitePage(html, url);
}

WebsitePageData _parseWebsitePage(String html, String url) {
  final tokenRegex = RegExp(
    r'<(h1|h2|h3|h4|p)[^>]*>(.*?)</\1>',
    caseSensitive: false,
    dotAll: true,
  );

  final title = _firstMatch(html, r'<h1[^>]*>(.*?)</h1>') ?? _titleFromUrl(url);

  final paragraphs = <String>[];
  final sections = <WebsiteSection>[];
  String? currentTitle;
  final currentParagraphs = <String>[];

  for (final match in tokenRegex.allMatches(html)) {
    final tag = (match.group(1) ?? '').toLowerCase();
    final text = _cleanText(match.group(2) ?? '');
    if (text.isEmpty || _isNoise(text)) {
      continue;
    }

    if (tag.startsWith('h')) {
      if (currentTitle != null) {
        sections.add(
          WebsiteSection(
            title: currentTitle,
            summary: _pickSummary(currentParagraphs),
          ),
        );
      }
      currentTitle = text;
      currentParagraphs.clear();
    } else if (tag == 'p') {
      paragraphs.add(text);
      if (currentTitle != null) {
        currentParagraphs.add(text);
      }
    }
  }

  if (currentTitle != null) {
    sections.add(
      WebsiteSection(
        title: currentTitle,
        summary: _pickSummary(currentParagraphs),
      ),
    );
  }

  return WebsitePageData(
    title: title,
    summary: _pickSummary(paragraphs),
    sections: sections,
    paragraphs: paragraphs,
  );
}

String _pickSummary(List<String> values) {
  for (final value in values) {
    final normalized = value.trim();
    final lower = normalized.toLowerCase();
    if (normalized.length >= 24 && !lower.contains('loading')) {
      return normalized;
    }
  }

  if (values.isNotEmpty) {
    return values.first.trim();
  }

  return '';
}

String _cleanText(String input) {
  final withoutTags = input.replaceAll(RegExp(r'<[^>]+>'), ' ');
  final decoded = withoutTags
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&', '&')
      .replaceAll('<', '<')
      .replaceAll('>', '>')
      .replaceAll('"', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  return decoded;
}

bool _isNoise(String text) {
  final lower = text.toLowerCase();
  return lower.contains('escapehtml(eventlabel)') ||
      lower.contains('function(') ||
      lower.contains('var ') && text.length < 20;
}

String? _firstMatch(String html, String pattern) {
  final match = RegExp(
    pattern,
    caseSensitive: false,
    dotAll: true,
  ).firstMatch(html);

  if (match == null) {
    return null;
  }

  final text = _cleanText(match.group(1) ?? '');
  return text.isEmpty ? null : text;
}

String _titleFromUrl(String url) {
  if (url.contains('calendar.php')) return 'Calendar';
  if (url.contains('gallery.php')) return 'Gallery';
  if (url.contains('about.php')) return 'About';
  return 'Gurdwara Sahib Melaka';
}