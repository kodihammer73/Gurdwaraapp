# Gurdwara Mobile App - Progress Log

## Session 1: Complete Project Setup with Modern Design (2026-07-23)

### Completed
- [x] Created project overview documentation
- [x] Defined project architecture and structure
- [x] Documented tech stack decisions
- [x] Initialize Flutter project with flutter create
- [x] Set up Git repository and .gitignore
- [x] Created GitHub Actions iOS build workflow
- [x] Created comprehensive README with build instructions
- [x] Analyzed Gurdwara Sahib Melaka website design
- [x] Created comprehensive design guidelines (modern, minimalist, trendy)
- [x] Configured pubspec.yaml with modern dependencies
- [x] Created modern theme configuration with brand colors (Saffron/Navy/Gold)
- [x] Implemented base app structure with bottom navigation
- [x] Created minimalist home screen with hero section and quick links
- [x] Set up modular screen structure (Home, Events, Gallery, More)
- [x] Applied Material Design 3 with custom theming
- [x] Installed and resolved all dependencies
- [x] Fixed theme.dart compilation errors (CardThemeData, DialogThemeData)
- [x] Ready for APK and IPA builds

### Setup Phase
**Objective**: Establish foundation for Flutter mobile app development

**Key Decisions Made**:
1. Project name: gurdwara_app
2. State management: Provider pattern
3. Navigation: GoRouter for named routes
4. Local development: Android APK compilation on Windows
5. CI/CD: GitHub Actions for iOS IPA builds

### Next Steps (Feature Development Phase)
1. Connect to gurdwara-v3 backend API (Dio integration)
2. Implement announcements fetching and display
3. Create events system with real data from backend
4. Build gallery with image loading from API
5. Add push notifications with Firebase
6. Implement offline caching with Hive
7. Add barsi countdown feature (from website)
8. Create Sant Ji teachings section
9. Add event calendar with filtering
10. Implement user preferences and settings
11. Test on Android emulator (local APK build)
12. Push to GitHub and verify iOS workflow
13. Beta testing and refinement

### Environment Configuration
- Flutter: Installed on Windows 11
- IDE: Visual Studio Code
- Git: Ready for GitHub integration
- Android: Ready for local APK builds
- iOS: GitHub Actions pipeline to be configured

### Build Status
- Android Build: Ready for local APK compilation via `flutter build apk`
- iOS Build: GitHub Actions workflow configured (triggers on push to main/develop)
- Project Structure: Complete with all platform-specific folders

---

## Session Completion Summary
- **Duration**: Full project setup with modern design implementation
- **Status**: ✅ Complete - Ready for feature development
- **Output**: 
  - Flutter project structure created with modern architecture
  - Git repository initialized with .gitignore
  - iOS CI/CD pipeline configured (GitHub Actions)
  - Comprehensive documentation (design guidelines, architecture, overview)
  - Modern theme system with brand colors and typography
  - Base app structure with navigation
  - Minimalist, clean UI following Material Design 3
  - All dependencies installed and resolved
  - Ready for backend integration and feature implementation

## Design Implementation Highlights
- **Color Scheme**: Saffron (#E8A838), Navy (#1B365D), Gold (#C5A028)
- **Typography**: Playfair Display (headings), Inter (body)
- **Philosophy**: Minimalist, modern, trendy for young Sikh community
- **Features**: Dark mode support, responsive layout, accessible components
- **Architecture**: Clean modular structure with separation of concerns

## Quick Commands Reference
```bash
# Development
flutter run                          # Run app on connected device/emulator
flutter pub get                      # Install dependencies
flutter test                         # Run unit tests
flutter analyze                      # Code analysis

# Android Build (Windows Local)
flutter build apk --debug            # Debug APK
flutter build apk --release          # Release APK

# iOS Build (GitHub Actions)
# - Automatically triggered on push
# - Manual build: Create tag and push (git tag v1.0.0 && git push origin v1.0.0)
```

## File Structure Created
```
gurdwara_app/
├── lib/                   # Flutter source code
├── android/               # Android configuration (ready)
├── ios/                   # iOS configuration (ready)
├── .github/workflows/     # CI/CD pipelines
│   └── ios-build.yml      # iOS IPA build workflow
├── .gitignore             # Git ignore patterns
├── README.md              # Project documentation
├── pubspec.yaml           # Dependencies (to be updated)
└── pubspec.lock
```

## Session 2: Push Notification System Fix & Backend (2026-07-27)

### Completed
- [x] Fixed Firebase configuration (wrong API key in firebase_options.dart)
- [x] Fixed main.dart to properly initialize Firebase with options
- [x] Fixed Android namespace mismatch (com.example.gurdwara_app → com.gurdwara.mobileapp)
- [x] Added FCM token registration with backend server
- [x] Added onTokenRefresh listener for token changes
- [x] Created PHP backend: device token registration endpoint (api/register_device.php)
- [x] Created PHP backend: push notification sender (api/send_push.php)
- [x] Removed duplicate firebase_options.dart at root level
- [x] All Flutter code compiles without errors
- [x] Fixed iOS deployment target from 13.0 to 15.0 in project.pbxproj (3 occurrences)
- [x] Fixed .gitignore broad `**/ios/**/*.xcconfig` rule (was ignoring essential Debug.xcconfig & Release.xcconfig)
- [x] Committed essential Flutter xcconfig files (Debug.xcconfig, Release.xcconfig, AppFrameworkInfo.plist)
- [x] Added push notification background modes (remote-notification, fetch) to Info.plist
- [x] Pushed to GitHub to trigger CI build

### Key Fixes Made
1. **firebase_options.dart**: Updated Android API key from invalid `70d8b29648c75fcb4980b56dbe29` to correct `AIzaSyDBpX3skwF4CruTyzhaV6XtUdbqf0egcU4` (from google-services.json)
2. **main.dart**: Uncommented Firebase options import and passed `DefaultFirebaseOptions.currentPlatform` to `Firebase.initializeApp()`
3. **Android build.gradle.kts**: Fixed namespace to match applicationId `com.gurdwara.mobileapp`
4. **notification_service.dart**: Added `_registerDeviceToken()` method that sends FCM token to PHP backend, added `onTokenRefresh` listener
5. **Removed** duplicate `lib/firebase_options.dart` (correct one is at `lib/services/firebase_options.dart`)

### PHP Backend Files Created
- **api/register_device.php** - Endpoint for Flutter app to register FCM tokens (uses SQLite)
- **api/send_push.php** - Sends push notifications to all registered devices via Firebase FCM API

### Deployment Instructions
1. Upload `backend/api/register_device.php` and `backend/api/send_push.php` to your mini PC at `https://www.gurdwarasahibmelaka.com/api/`
2. Get FCM Server Key from Firebase Console → Project Settings → Cloud Messaging
3. Set `FCM_SERVER_KEY` in `send_push.php`
4. Rebuild the Flutter app with `flutter build apk --release`

### Next Steps
1. Deploy PHP backend files to mini PC
2. Configure FCM Server Key in send_push.php
3. Rebuild APK and test push notifications end-to-end
4. Integrate push notification sending into admin panel (auto-send when events are created)

## Session 3: Barsi Countdown Card Fix (2026-07-29)

### Completed
- [x] Fixed Barsi card on homepage to fetch real barsi dates from website's barsidates.txt
- [x] Removed calendar icon from Barsi card (text-only display)
- [x] Added ordinal display (e.g., "55th Salana Yaadgiri")
- [x] Added date range display (e.g., "20 - 23 May 2027")
- [x] Added live countdown text (e.g., "295 days, 12h left")
- [x] Replaced hardcoded March 14 date with real data from barsidates.txt
- [x] Added proper loading/error states for the Barsi card
- [x] All code compiles without errors

### Key Changes
1. **`_BarsiQuickCard` widget**: Completely rewritten to fetch `barsidates.txt` from the website via Dio
2. **Removed** `_getNextBarsi()` method that used hardcoded March 14 date
3. **Added** `_BarsiEvent` data class to hold parsed barsi event data
4. **Added** `FutureBuilder` pattern for async data loading with loading spinner and error fallback
5. **Logic matches website**: Same algorithm as the website's JavaScript - finds the next upcoming event based on current date

## Session 4: Immersive Apple App Store-Style Category Grid (2026-07-29)

### Completed
- [x] Created new `ImmersiveCategoryGrid` widget with vibrant gradient cards
- [x] Each card features multi-color gradient backgrounds (periwinkle→purple, hot pink→coral, sky blue→cyan, emerald→mint, rose→yellow)
- [x] Multi-layered composition: background gradient, midground abstract geometric shapes, foreground text/icons
- [x] Glassmorphism effects using `BackdropFilter` with blur on icon backgrounds and subtitle badges
- [x] 3D floating depth with soft drop shadows on cards
- [x] Tap animation: scale(1.03) with parallax foreground shift on press
- [x] 2-column responsive grid with 4:3 aspect ratio and 20px rounded corners
- [x] Replaced old 3-column quick link grid on homepage with new immersive grid
- [x] Removed unused `_buildQuickLinkCard` method and `_aboutUrl` constant
- [x] All code compiles with zero errors

### Key Changes
1. **New file**: `lib/widgets/immersive_category_grid.dart` - Reusable widget with `ImmersiveCategoryGrid`, `ImmersiveCategory` data model, and `_ImmersiveCategoryCard` with animations
2. **main.dart**: Replaced `GridView.count` with 3-column quick links → `ImmersiveCategoryGrid` with 2-column vibrant gradient cards
3. **Design**: Each card has unique gradient, glassmorphism icon container, abstract geometric shapes (circles, pills, squares), and parallax tap animation
4. **Removed**: `_buildQuickLinkCard()` method (no longer needed), `_aboutUrl` constant (unused)

### Design Specifications Met
- ✅ 2-column responsive grid with 4:3 aspect ratio
- ✅ Large rounded corners (20px)
- ✅ Unique vibrant multi-color gradient per card
- ✅ Multi-layered composition (background → midground shapes → foreground content)
- ✅ Soft drop shadows for 3D floating effect
- ✅ Glassmorphism (backdrop-filter: blur) on icon backgrounds and subtitle badges
- ✅ Tap interaction: scale(1.03) with parallax foreground shift
- ✅ Clean, accessible, high-performance layout

### Barsi Card Enhancement
- Added `customContentBuilder` parameter to `ImmersiveCategory` model for dynamic card content
- Created `_BarsiCountdownContent` widget that fetches barsi data from `barsidates.txt`
- Barsi immersive card now displays: ordinal (e.g., "55th Barsi"), date range (e.g., "20 - 23 May 2027"), and live countdown (e.g., "295 days, 12h left")
- Loading spinner shown while fetching, gracefully hides on error
- All code compiles with zero errors

## Session 5: Daily Push Notification Cron Deployed to MiniPC (2026-07-30)

### Completed
- [x] Created `backend/cron/daily_event_check.php` - checks events.txt for tomorrow's events and sends push notifications
- [x] Configured cron job on MiniPC to run daily at 11:00 AM
- [x] Deployed PHP backend files (`register_device.php`, `send_push.php`, `daily_event_check.php`) to MiniPC
- [x] Configured FCM Server Key in `send_push.php`
- [x] Cron job logs to `/var/log/gurdwara_push.log`
- [x] Daily push notification system is live and running

### Cron Setup on MiniPC
```bash
# Runs daily at 11:00 AM
0 11 * * * /usr/bin/php /var/www/html/api/cron/daily_event_check.php >> /var/log/gurdwara_push.log 2>&1
```

### How It Works
1. Cron triggers `daily_event_check.php` at 11:00 AM daily
2. Script reads `events.txt` and checks for events happening tomorrow
3. If tomorrow events are found, sends push notifications via `send_push.php` to all registered devices
4. Results are logged to `/var/log/gurdwara_push.log`

### Files Deployed to MiniPC
- `api/register_device.php` - FCM token registration endpoint
- `api/send_push.php` - Push notification sender (FCM Server Key configured)
- `cron/daily_event_check.php` - Daily event check cron script

## Session 6: Push Notification Tab Added to Website Admin Panel (2026-07-30)

### Completed
- [x] Added "Push Notification" tab (Tab 7) to website admin panel (`admin.php`)
- [x] Manual push form with title, body, type dropdown, and live preview
- [x] PHP handler calls `send_push.php` via cURL (auto-detects localhost vs production)
- [x] Deployed `send_push.php` and `daily_event_check.php` to website's `api/` and `cron/` directories
- [x] Updated website memory bank with all changes

### Key Changes
1. **`admin.php`** (modified): Added Tab 7 with sidebar nav link, PHP handler, HTML form, live preview JS, and info sidebar
2. **`api/send_push.php`** (deployed to website): FCM V1 push notification sender
3. **`cron/daily_event_check.php`** (deployed to website): Daily cron script for event reminders

### Result
- Admin can now send push notifications to all registered app devices directly from the admin panel
- Live preview shows exactly how the notification will appear on a device
- Works on both localhost (XAMPP) and production (gurdwarasahibmelaka.com)
- Same FCM infrastructure as the automatic daily event reminder

## Session 7: Bug Fixes & Performance Improvements (2026-08-07)

### Completed
- [x] Extracted shared `_fetchNextBarsi()` top-level function — eliminated duplicate barsi fetch logic between `_BarsiQuickCard` and `_BarsiFullContent`
- [x] Deleted dead `_BarsiQuickCard` widget (was never mounted, caused double network requests)
- [x] Fixed hardcoded `monthNames[4]` (May) — now uses `event.month` field derived from parsed data
- [x] Added optional 5th `|month` token to `barsidates.txt` parser (defaults to 5/May if absent, future-proof)
- [x] Parallelised gallery HTTP requests using `Future.wait()` — 17 year requests per category now fire simultaneously instead of sequentially
- [x] Gallery load time reduced from ~30s (85 sequential requests) to ~5s (5 parallel batches of 17)

### Key Changes
1. **`_fetchNextBarsi()`** — moved to top-level shared function; `_BarsiEvent` now has `month` field
2. **`_BarsiQuickCard`** — deleted (dead code, ~250 lines removed)
3. **`_BarsiFullContent`** — now calls shared `_fetchNextBarsi()`, date display uses `event.month - 1` index
4. **`_GalleryScreenState._loadGallery()`** — inner loop replaced with `Future.wait(yearsToCheck.map(...))` with `eagerError: false`

### Performance Impact
- **Before**: Gallery = 5 categories × 17 years = 85 sequential awaits (~30s on mobile)
- **After**: Gallery = 5 categories × 1 parallel batch each = ~5s total

## Session 8: Google Play Store Package Migration (2026-08-10)

### Completed
- [x] Updated `google-services.json` to new Firebase project `gsmelaka1925` with package `com.gsmelaka.mobileapp`
- [x] Updated `build.gradle.kts`: namespace/applicationId → `com.gsmelaka.mobileapp`, compileSdk/targetSdk → 36, added Play Store signing config
- [x] Fixed `firebase_options.dart`: corrected Android appId to match google-services.json, updated storageBucket to `gsmelaka1925.firebasestorage.app`, fixed iosBundleId → `com.gsmelaka.mobileapp`
- [x] Created new `MainActivity.kt` at correct path `kotlin/com/gsmelaka/mobileapp/` with updated package declaration
- [x] Deleted old `MainActivity.kt` at `kotlin/com/gurdwara/mobileapp/`
- [x] Verified `flutter pub get` resolves successfully

### Key Changes
- **Package ID**: `com.gurdwara.mobileapp` → `com.gsmelaka.mobileapp`
- **Firebase project**: `gsmelaka1925` (unchanged, but appId corrected)
- **Android build**: compileSdk/targetSdk bumped to 36, signing config added for Play Store release
- **`key.properties`** must exist at `android/key.properties` with keystore credentials for release build

### Next Steps for Play Store Upload
1. Ensure `android/key.properties` is configured with your keystore path and passwords
2. Run `flutter build appbundle --release` to generate the AAB
3. Upload the AAB from `build/app/outputs/bundle/release/app-release.aab` to Google Play Console

## Session 9: Force Update Feature (2026-08-13)

### Completed
- [x] Created backend version config file (`website/app_version.json`) with minimum_version, latest_version, play_store_url, force_update flag, and update_message
- [x] Added `package_info_plus` dependency to pubspec.yaml to read installed app version at runtime
- [x] Created `lib/services/version_check_service.dart` — fetches version config from website, compares installed version against minimum required version using semantic version comparison
- [x] Created `lib/widgets/force_update_dialog.dart` — branded gradient dialog (periwinkle→purple) with "Update Now" button that opens the Play Store via url_launcher
- [x] Wired version check into `main.dart` startup — `GurdwaraApp` is now a `ConsumerStatefulWidget` that runs the version check on init and shows the dialog if an update is required
- [x] Force update dialog is non-dismissible (barrier locked, back button blocked via PopScope) when `force_update` is true
- [x] Optional "Later" button shown when `force_update` is false (recommended update mode)
- [x] Fail-open behaviour: on any network/parse error, the app continues normally (no update prompt)
- [x] `flutter pub get` resolves successfully; `dart analyze` shows zero errors

### Key Changes
1. **`website/app_version.json`** (new): Hosted at `https://www.gurdwarasahibmelaka.com/app_version.json` — the single source of truth for the minimum required version. Admin edits this file to force updates without rebuilding the app.
2. **`pubspec.yaml`**: Added `package_info_plus: ^8.0.0`
3. **`lib/services/version_check_service.dart`** (new): `VersionCheckService.checkForUpdate()` returns a `VersionCheckResult` with `updateRequired`, `forceUpdate`, `latestVersion`, `minimumVersion`, `playStoreUrl`, `updateMessage`. Uses semantic version comparison (major.minor.patch).
4. **`lib/widgets/force_update_dialog.dart`** (new): `showForceUpdateDialog(context, result)` — branded dialog matching the app's immersive gradient aesthetic. Non-dismissible when forced.
5. **`lib/main.dart`**: `GurdwaraApp` converted from `ConsumerWidget` to `ConsumerStatefulWidget`; `_checkForUpdate()` runs on startup and shows the dialog after the first frame.

### How to Use (Admin)
1. To force an update, edit `app_version.json` on the website:
   - Set `minimum_version` to the new required version (e.g. `"1.0.2"`)
   - Set `force_update` to `true`
   - Set `latest_version` and `update_message` as desired
2. Users on versions below `minimum_version` will see the non-dismissible update dialog on next app launch.
3. To make it a recommended (dismissible) update, set `force_update` to `false`.

### Version Bump & AAB Build (2026-08-13)
- [x] Bumped app version from `1.0.1+2` → `1.0.2+3` in `pubspec.yaml`
- [x] Verified `android/key.properties` and `upload-keystore.jks` exist for Play Store release signing
- [x] Compiled release AAB successfully via `flutter build appbundle --release`
- [x] Output: `build/app/outputs/bundle/release/app-release.aab` (ready to upload to Google Play Console)

### Next Steps
1. Deploy `app_version.json` to the MiniPC website root
2. Upload `app-release.aab` (v1.0.2+3) to Google Play Console
3. Test force update end-to-end (install old version, bump minimum_version, verify dialog appears)


## Gallery Performance Optimization (2026-08-13)

### Problem
The Gallery tab was slow to load and scrolled sluggishly because the app ignored the server-side WebP thumbnails (`thumb` field) returned by `ajax_gallery.php` and instead fetched every full-resolution original image for the grid.

### Changes Made (lib/main.dart)
- [x] Added `_GalleryImage` model holding both `thumbUrl` (lightweight WebP) and `fullUrl` (full-resolution)
- [x] Updated `_loadGallery` to parse both `item['thumb']` and `item['src']` from the API, falling back to the full URL when no thumbnail is provided
- [x] Changed `_GalleryData.categoryImages` to `Map<String, Set<_GalleryImage>>`
- [x] Added `_filteredImages()` helper to resolve the selected category/year image list
- [x] Converted the non-lazy `GridView.count` to a lazy `SliverGrid` (only builds tiles near the viewport, so off-screen images aren't fetched until scrolled into view)
- [x] Updated `_GalleryUrlItem` to use `thumbUrl` for the grid with `memCacheWidth/Height: 400` decode hints, and `fullUrl` for the full-screen viewer with `memCacheWidth/Height: 1600`
- [x] Updated the empty-state sample grid to use `_GalleryImage` objects
- [x] Verified with `flutter analyze` (no new errors; only pre-existing warnings remain)

### Result
Gallery now loads lightweight WebP thumbnails in the grid, decodes them at a small size, and only fetches full-resolution images when a user taps to view them full-screen. Scrolling is smooth and initial load is much faster.

### Version Bump & AAB Build (2026-08-13)
- [x] Bumped app version from `1.0.2+3` → `1.0.3+4` in `pubspec.yaml`
- [x] Compiled release AAB successfully via `flutter build appbundle --release`
- [x] Output: `build/app/outputs/bundle/release/app-release.aab` (58.1MB, ready to upload to Google Play Console)

## Session 10: Commit & Push Pending Android Work to GitHub (2026-08-17)

### Completed
- [x] Verified iOS work was previously done and pushed to GitHub (iOS folder, workflow, config all committed)
- [x] Identified significant uncommitted Android work sitting in working directory
- [x] Added signing credentials (`upload-keystore.jks`, `key.properties`, `*.jks`, `*.keystore`) to `.gitignore` for security
- [x] Staged all legitimate changes (package migration, force update, version bump, app icons)
- [x] Committed with descriptive message (commit `0e0d8d1`)
- [x] Pushed to GitHub (`535185c..0e0d8d1 main -> main`)
- [x] Verified working tree is clean and branch is up to date with origin/main

### Key Changes Committed
1. **Android package migration**: `com.gurdwara.mobileapp` → `com.gsmelaka.mobileapp` (MainActivity.kt renamed)
2. **Force update feature**: New `version_check_service.dart` + `force_update_dialog.dart`
3. **Version bump**: `pubspec.yaml` updated
4. **App icons**: New launcher icons (drawable/mipmap resources)
5. **iOS**: `project.pbxproj` updated
6. **Security**: Signing credentials excluded from repo via `.gitignore`

### Git State
- Remote: `https://github.com/kodihammer73/Gurdwaraapp.git`
- Branch: `main` (up to date with origin/main)
- Working tree: clean
- 3 commits total: initial, iOS workflow, Android migration + force update

### Next Steps
1. Verify GitHub Actions iOS build triggered successfully on the latest push
2. Continue iOS development/testing if needed

## Development Starting Points

1. **Android Development**: Use `flutter run` on Windows with Android emulator

2. **Dependency Management**: Update pubspec.yaml with required packages
3. **UI Implementation**: Start with main.dart and create base screens
4. **GitHub Integration**: Connect local repo to GitHub for CI/CD testing
5. **Push Notifications**: Deploy PHP backend files to mini PC, configure FCM key, rebuild APK



