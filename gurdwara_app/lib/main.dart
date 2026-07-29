// lib/main.dart - Add these at the VERY TOP of the file, before any other code

import 'dart:convert';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/theme.dart';
import 'services/firebase_options.dart';
import 'services/notification_service.dart';
import 'widgets/immersive_category_grid.dart';

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
  
  // Android: google-services.json auto-initializes Firebase
  // iOS/others: need explicit initialization
  try {
    final firebaseApp = Firebase.app();
    print('ℹ️ Firebase already initialized');
  } on Exception {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized via options');
    } on Exception catch (e) {
      print('⚠️ Firebase init skipped: $e');
    }
  }

  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    print('✅ Notification Service initialized');
  } catch (e) {
    print('⚠️ Notification Service init failed: $e');
  }
  
  runApp(const ProviderScope(child: GurdwaraApp()));
}

class GurdwaraApp extends ConsumerWidget {
  const GurdwaraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Gurdwara Sahib Melaka',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

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
          onGallerySelected: () => _selectTab(2),
          onAboutSelected: () => _selectTab(3),
        );
      case 1:
        return const CalendarScreen();
      case 2:
        return GalleryScreen();
      case 3:
        return const AboutScreen();
      default:
        return HomeScreenContent(
          onCalendarSelected: () => _selectTab(1),
          onGallerySelected: () => _selectTab(2),
          onAboutSelected: () => _selectTab(3),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildScreen(_selectedIndex),
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
            icon: Icon(Icons.collections_outlined),
            selectedIcon: Icon(Icons.collections),
            label: 'Gallery',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'About',
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
    required this.onGallerySelected,
    required this.onAboutSelected,
  });

  final VoidCallback onCalendarSelected;
  final VoidCallback onGallerySelected;
  final VoidCallback onAboutSelected;

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  late Future<List<HomepageEvent>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchUpcomingEvents();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _fetchUpcomingEvents();
    });
    await _future;
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
                  Image.asset(
                    _siteLogoAsset,
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.temple_buddhist,
                        size: 28,
                        color: Theme.of(context).colorScheme.primary,
                      );
                    },
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
            // Welcome card with immersive gradient style
            SizedBox(
              width: double.infinity,
              child: _ImmersiveInfoCard(
                gradientColors: const [
                  Color(0xFF667EEA), // Deep periwinkle
                  Color(0xFF764BA2), // Rich purple
                ],
                child: Column(
                  children: [
                    Text(
                      'Waheguru Ji Ka Khalsa Waheguru Ji Ki Fateh',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
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
                            'WELCOME : Guest',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Upcoming Events card with immersive gradient style
            SizedBox(
              width: double.infinity,
              child: _ImmersiveInfoCard(
                gradientColors: const [
                  Color(0xFF43E97B), // Emerald
                  Color(0xFF38F9D7), // Mint
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
                  title: 'Booking',
                  subtitle: 'Coming soon',
                  icon: Icons.event_rounded,
                  gradientColors: const [
                    Color(0xFF43E97B), // Emerald
                    Color(0xFF38F9D7), // Mint
                  ],
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  TextTheme themeText(BuildContext context) => Theme.of(context).textTheme;
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

/// A widget that displays a countdown to the next Barsi from the website's barsidates.txt
class _BarsiQuickCard extends StatefulWidget {
  const _BarsiQuickCard();

  @override
  State<_BarsiQuickCard> createState() => _BarsiQuickCardState();
}

class _BarsiQuickCardState extends State<_BarsiQuickCard> {
  static const String _barsidatesUrl = '$_siteBaseUrl/barsidates.txt';

  late Future<_BarsiEvent> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchNextBarsi();
  }

  Future<_BarsiEvent> _fetchNextBarsi() async {
    final response = await _dio.get<String>(_barsidatesUrl);
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

      if (year == null || startDay == null || endDay == null) continue;

      // Barsi is always in May (month 5)
      final startDate = DateTime(year, 5, startDay);
      final endDate = DateTime(year, 5, endDay + 1); // end of endDay

      if (now.isBefore(endDate)) {
        targetEvent = _BarsiEvent(
          ordinal: ordinal,
          startDay: startDay,
          endDay: endDay,
          year: year,
          startDate: startDate,
          endDate: endDate,
        );
        break;
      }
    }

    // If all events passed, use the last one
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
        if (year == null || startDay == null || endDay == null) continue;
        targetEvent = _BarsiEvent(
          ordinal: ordinal,
          startDay: startDay,
          endDay: endDay,
          year: year,
          startDate: DateTime(year, 5, startDay),
          endDate: DateTime(year, 5, endDay + 1),
        );
        break;
      }
    }

    if (targetEvent == null) {
      throw Exception('No barsi dates available.');
    }

    return targetEvent;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BarsiEvent>(
      future: _future,
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        final bgColor = theme.colorScheme.primaryContainer;
        final fgColor = theme.colorScheme.onPrimaryContainer;
        final borderColor = theme.colorScheme.primary.withValues(alpha: 0.35);

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            margin: EdgeInsets.zero,
            color: bgColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            margin: EdgeInsets.zero,
            color: bgColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Barsi',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: fgColor,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Unavailable',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: fgColor.withValues(alpha: 0.75),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
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

        return Card(
          margin: EdgeInsets.zero,
          color: bgColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: theme.colorScheme.primary.withValues(alpha: 0.20),
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${event.ordinal} Barsi',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: fgColor,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${event.startDay} - ${event.endDay} ${monthNames[4]} ${event.year}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: fgColor.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    countdownText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: fgColor.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
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
  static const String _barsidatesUrl = '$_siteBaseUrl/barsidates.txt';

  late Future<_BarsiEvent> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchNextBarsi();
  }

  Future<_BarsiEvent> _fetchNextBarsi() async {
    final response = await _dio.get<String>(_barsidatesUrl);
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

      if (year == null || startDay == null || endDay == null) continue;

      final startDate = DateTime(year, 5, startDay);
      final endDate = DateTime(year, 5, endDay + 1);

      if (now.isBefore(endDate)) {
        targetEvent = _BarsiEvent(
          ordinal: ordinal,
          startDay: startDay,
          endDay: endDay,
          year: year,
          startDate: startDate,
          endDate: endDate,
        );
        break;
      }
    }

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
        if (year == null || startDay == null || endDay == null) continue;
        targetEvent = _BarsiEvent(
          ordinal: ordinal,
          startDay: startDay,
          endDay: endDay,
          year: year,
          startDate: DateTime(year, 5, startDay),
          endDate: DateTime(year, 5, endDay + 1),
        );
        break;
      }
    }

    if (targetEvent == null) {
      throw Exception('No barsi dates available.');
    }

    return targetEvent;
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
            // Date range
            AnimatedBuilder(
              animation: widget.parallax,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -widget.parallax.value.dy * 0.3),
                  child: child,
                );
              },
              child: Text(
                '${event.startDay} - ${event.endDay} ${monthNames[4]} ${event.year}',
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
    required this.startDate,
    required this.endDate,
  });

  final String ordinal;
  final int startDay;
  final int endDay;
  final int year;
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
    // Calculate the next Sunday (end of the current week)
    final daysUntilSunday = DateTime.sunday - today.weekday;
    final endOfWeek = today.add(Duration(days: daysUntilSunday));

    final filtered = widget.events.where((event) {
      final eventDate = dateOnly(event.date);
      return !eventDate.isBefore(today) && !eventDate.isAfter(endOfWeek);
    }).toList();

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final events = _filteredEvents;
    final theme = Theme.of(context);

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
          Text(
            'No event data available.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < events.length; i++) ...[
                _HomepageEventTile(event: events[i]),
                if (i != events.length - 1) const SizedBox(height: 6),
              ],
            ],
          ),
      ],
    );
  }
}

class _SplashLoading extends StatelessWidget {
  const _SplashLoading();

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
            Expanded(
              child: Image.asset(
                _siteLogoAsset,
                width: 64,
                height: 64,
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
            const SizedBox(height: 8),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
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
            if (isToday) ...[
              const SizedBox(height: 4),
              Text(
                'Ongoing now',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: palette.foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
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
  const HomepageEvent({
    required this.title,
    required this.date,
    required this.details,
    required this.imagePath,
  });

  final String title;
  final DateTime date;
  final String details;
  final String imagePath;

  String? get imageUrl => imagePath.isEmpty ? null : imagePath;
}

// lib/main.dart

Future<List<HomepageEvent>> _fetchUpcomingEvents() async {
  final response = await _dio.get<String>(_eventsUrl);
  final text = response.data ?? '';
  final events = parseHomepageEvents(text); // ⭐ Changed from _parseHomepageEvents

  if (events.isEmpty) {
    throw Exception('No upcoming events found.');
  }

  final today = dateOnly(DateTime.now()); // ⭐ Changed from _dateOnly
  final upcoming = events.where((event) {
    final eventDate = dateOnly(event.date); // ⭐ Changed from _dateOnly
    return !eventDate.isBefore(today);
  }).toList();

  return upcoming.isNotEmpty ? upcoming : events;
}

Future<List<HomepageEvent>> _fetchAllEvents() async {
  final response = await _dio.get<String>(_eventsUrl);
  final text = response.data ?? '';
  final events = parseHomepageEvents(text); // ⭐ Changed from _parseHomepageEvents

  if (events.isEmpty) {
    throw Exception('No events found.');
  }

  return events;
}

Map<DateTime, List<HomepageEvent>> _groupEventsByDate(List<HomepageEvent> events) {
  final grouped = <DateTime, List<HomepageEvent>>{};

  for (final event in events) {
    final key = dateOnly(event.date); // ⭐ Changed from _dateOnly
    grouped.putIfAbsent(key, () => <HomepageEvent>[]).add(event);
  }

  return grouped;
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

    events.add(
      HomepageEvent(
        title: title,
        date: date,
        details: details,
        imagePath: imagePath,
      ),
    );
  }

  events.sort((a, b) => a.date.compareTo(b.date));
  return events;
}

DateTime dateOnly(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late Future<List<HomepageEvent>> _future;
  int _monthOffset = 0;

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
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _CalendarMonthCard(
                    month: _visibleMonth,
                    groupedEvents: groupedEvents,
                    onPreviousMonth: _previousMonth,
                    onNextMonth: _nextMonth,
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
    required this.onDateSelected,
  });

  final DateTime month;
  final Map<DateTime, List<HomepageEvent>> groupedEvents;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
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
      if (_selectedCategory == null && _future != null) {
        _future.then((data) {
          if (data != null && data.categories.isNotEmpty) {
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
    final categoryImages = <String, Set<String>>{};
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

      final images = <String>[];
      final imagesList = data['images'] as List<dynamic>?;
      if (imagesList != null) {
        for (final item in imagesList) {
          if (item is Map<String, dynamic>) {
            final src = (item['src'] ?? '').toString().trim();
            if (src.isEmpty) continue;
            final lower = src.toLowerCase();
            if (lower.startsWith('http://') || lower.startsWith('https://')) {
              images.add(src);
            } else {
              final path = src.startsWith('/') ? src : '/$src';
              images.add('$_siteBaseUrl$path');
            }
          }
        }
      }
      return _GalleryPageResult(images: images);
    }

    final candidates = _categoryOrder;

    for (final category in candidates) {
      final yearSet = <int>{};
      final imageSet = <String>{};

      categories.add(category);
      categoryImages[category] = imageSet;
      categoryYears[category] = [];

      // Match the years available on the website's gallery dropdown
      for (final year in [2026, 2025, 2024, 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011, 2010]) {
        final page = await fetchGalleryPage(category, year: year);
        if (page == null || page.images.isEmpty) {
          continue;
        }
        for (final src in page.images) {
          imageSet.add(src);
          final match = RegExp(r'/(\d{4})/').firstMatch(src);
          if (match != null) {
            final yr = int.tryParse(match.group(1) ?? '') ?? 0;
            if (yr != 0) yearSet.add(yr);
          }
        }
      }

      final years = yearSet.toList()..sort((a, b) => b.compareTo(a));
      categoryYears[category] = years;
    }

    return _GalleryData(
      categories: categories,
      categoryImages: categoryImages,
      categoryYears: categoryYears,
    );
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
                              _GalleryUrlItem(url: '$_siteBaseUrl/web/logo.png'),
                              _GalleryUrlItem(url: '$_siteBaseUrl/web/favicon.png'),
                              _GalleryUrlItem(url: 'https://picsum.photos/600/400?random=1'),
                              _GalleryUrlItem(url: 'https://picsum.photos/600/400?random=2'),
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
                padding: const EdgeInsets.all(16),
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
                        DropdownButtonFormField<int>(
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
                            for (final year in data.categoryYears[_selectedCategory]!)
                              DropdownMenuItem<int>(
                                value: year,
                                child: Text('$year'),
                              ),
                          ],
                          onChanged: (value) {
                            if (value != null && _selectedCategory != null) {
                              setState(() {
                                _selectedYear[_selectedCategory!] = value;
                              });
                            }
                          },
                        ),
                      const SizedBox(height: 16),
                      if (_selectedCategory != null)
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 16 / 9,
                          children: [
                            for (final url in data.categoryImages[_selectedCategory] ?? const <String>{})
                              if (_selectedYear[_selectedCategory] == null || _selectedYear[_selectedCategory] == 0)
                                _GalleryUrlItem(url: url)
                              else if (url.contains('/${_selectedYear[_selectedCategory]}/'))
                                _GalleryUrlItem(url: url),
                          ],
                        ),
                      if (_selectedCategory != null && (data.categoryImages[_selectedCategory] ?? <String>{}).isEmpty)
                        Text(
                          'No images in this category.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
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

class _GalleryPageResult {
  const _GalleryPageResult({required this.images});

  final List<String> images;
}

class _GalleryData {
  const _GalleryData({
    required this.categories,
    required this.categoryImages,
    required this.categoryYears,
  });

  final List<String> categories;
  final Map<String, Set<String>> categoryImages;
  final Map<String, List<int>> categoryYears;
}

String _capitalize(String input) {
  if (input.isEmpty) return input;
  final trimmed = input.trim();
  if (trimmed.isEmpty) return trimmed;
  return '${trimmed[0].toUpperCase()}${trimmed.substring(1).toLowerCase()}';
}

class _GalleryUrlItem extends StatelessWidget {
  const _GalleryUrlItem({required this.url});

  final String url;

  void _openFullScreen(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close image',
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Full-screen image with InteractiveViewer for pinch-to-zoom
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.of(dialogContext).pop(),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    panEnabled: true,
                    boundaryMargin: const EdgeInsets.all(80),
                    child: Center(
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Column(
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
                                style: Theme.of(dialogContext)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.white54),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
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
          child: Image.network(
            url,
            fit: BoxFit.cover,
            width: double.infinity,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Padding(
                padding: EdgeInsets.all(32),
                child: _SplashLoading(),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 8),
                    Text(url),
                  ],
                ),
              );
            },
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => onRetry(),
                  child: const Text('Retry'),
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
    String address = '';
    String mapUrl = '';

    try {
      final contactResponse = await _dio.get<String>('$_siteBaseUrl/contact_data.json');
      final contactJson = jsonDecode(contactResponse.data ?? '{}');

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
      }

      if (contactNumber.isEmpty || contactPerson.isEmpty) {
        final footerContact = contactJson['footerContact'] as Map<String, dynamic>?;
        if (footerContact != null) {
          contactNumber = (footerContact['phone'] as String? ?? contactNumber).trim();
          contactPerson = (footerContact['person'] as String? ?? contactPerson).trim();
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

            if (data.address.isNotEmpty || data.contactPerson.isNotEmpty || data.contactNumber.isNotEmpty)
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
                    ],
                  ),
                ),
              ),
            if (data.address.isNotEmpty || data.contactPerson.isNotEmpty || data.contactNumber.isNotEmpty)
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
                        'We welcome all visitors to Gurdwara Sahib Melaka. Please feel free to visit us during our open hours.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            if (data.mapUrl.isNotEmpty) const SizedBox(height: 16),

            Text(
              '© $currentYear Gurdwara Sahib Melaka. All rights reserved.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
  });

  final List<CommitteeMember> committee;
  final String address;
  final String contactPerson;
  final String mapUrl;
  final String contactNumber;

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