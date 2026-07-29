# Gurdwara Mobile App - Architecture

## Project Structure

```
gurdwara_app/
├── lib/                          # Main Flutter source code
│   ├── main.dart                 # Application entry point
│   ├── screens/                  # UI screens
│   │   ├── home_screen.dart
│   │   ├── schedule_screen.dart
│   │   ├── services_screen.dart
│   │   └── settings_screen.dart
│   ├── widgets/                  # Reusable UI components
│   ├── models/                   # Data models
│   ├── services/                 # Business logic & API calls
│   ├── providers/                # State management (Provider)
│   └── utils/                    # Utility functions & constants
├── android/                      # Android-specific configuration
│   ├── app/
│   ├── build.gradle
│   └── gradle.properties
├── ios/                          # iOS-specific configuration
│   ├── Podfile
│   └── Runner.xcodeproj
├── test/                         # Unit and widget tests
├── pubspec.yaml                  # Flutter dependencies
├── pubspec.lock                  # Locked dependency versions
└── README.md                     # Project documentation
```

## Architecture Patterns
- **State Management**: Provider + Riverpod for reactive state management
- **Navigation**: Named routes with GoRouter for modern routing
- **API Communication**: Dio for HTTP requests to gurdwara-v3 backend
- **Local Storage**: Hive for structured data, SharedPreferences for simple values
- **UI Framework**: Material Design 3 with custom theming
- **Design Philosophy**: Minimalist, clean, uncluttered interface for young audience

## Key Decisions
1. **Flutter + Material Design 3**: Modern, polished UI out of the box
2. **Riverpod + Provider**: Flexible, powerful state management for app complexity
3. **Minimalist Design**: Intentionally simple, focusing on essential information
4. **Backend Integration**: Direct API calls to existing gurdwara-v3 PHP backend
5. **Brand Consistency**: Saffron (#E8A838), Navy (#1B365D), Gold (#C5A028) color scheme
6. **Offline Support**: Local caching of announcements, events, gallery
7. **Performance First**: Optimized for slow/intermittent internet connections

## Platform-Specific Configuration
- **Android**: Minimum API level 21, configured in android/app/build.gradle
- **iOS**: Minimum deployment target 11.0, configured in ios/Podfile

## Build Targets
- **Android**: APK built locally using `flutter build apk`
- **iOS**: IPA built via GitHub Actions using `flutter build ios`

## Dependencies (Initial)
- **flutter_riverpod** (Advanced state management)
- **provider** (Additional state management)
- **go_router** (Navigation & routing)
- **dio** (HTTP client for API calls)
- **shared_preferences** (Simple key-value storage)
- **hive** (Local database for complex data)
- **intl** (Internationalization - Malay, English, Punjabi)
- **cached_network_image** (Image caching & optimization)
- **flutter_local_notifications** (Push notifications)
- **url_launcher** (Open URLs, maps, phone calls)
- **firebase_messaging** (Push notifications via Firebase)
- **smooth_page_indicator** (Modern carousel indicators)
- **google_fonts** (Typography - similar to website)

## Color Palette
```
Primary: #E8A838 (Saffron)
Primary Light: #F5D084
Primary Dark: #C5851E
Secondary: #1B365D (Navy)
Accent: #C5A028 (Gold)
Background: #FAF8F5 (Cream)
Surface: #FFFFFF
Error: #D32F2F
```

## Typography
- **Headings**: 'Playfair Display' (elegant serif)
- **Body**: 'Inter' (modern sans-serif)
- **Sizes**: Dynamic scaling based on device screen
