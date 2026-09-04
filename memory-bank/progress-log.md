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

## Session 11: Remove Duplicate iOS Build Workflow (2026-08-17)

### Problem
Two GitHub Actions workflow files named "iOS Build" existed in the repo, both triggering on pushes to `main`. This caused **two identical iOS builds** to run on every push, wasting Actions minutes.

### Root Cause
- `gurdwara_app/.github/workflows/ios-build.yml` (project level) — added in initial commit (July 23), missing `working-directory` config
- `.github/workflows/ios-build.yml` (root level) — added July 29, has correct `defaults.run.working-directory: gurdwara_app`

### Completed
- [x] Investigated git history to confirm which workflow ran in previous single-build push (project-level, the only one that existed at the time)
- [x] Deleted the duplicate project-level workflow (`gurdwara_app/.github/workflows/ios-build.yml`)
- [x] Committed (commit `06ab297`) and pushed to GitHub (`a9eeb7d..06ab297 main -> main`)
- [x] Verified only one workflow remains: `.github/workflows/ios-build.yml` (root level, correct config)

### Result
- Only **one** iOS build now runs per push to `main`
- The remaining root-level workflow has the correct `working-directory: gurdwara_app` config

## Session 12: Fix iOS App Icon & Firebase Config (2026-08-17)

### Problem
The iOS app looked different from Android:
1. iOS app icon was the **default Flutter template** (white background) instead of the saffron Gurdwara icon
2. iOS Firebase config had critical mismatches that would break the app

### Root Cause Analysis
- **iOS icons** (`ios/Runner/Assets.xcassets/AppIcon.appiconset/`) were never customized — still default Flutter template icons (only touched in initial commit)
- **Android icons** were updated in commit `0e0d8d1` with saffron `#E8A838` background + custom foreground
- **`GoogleService-Info.plist`** had `BUNDLE_ID = com.gurdwara.mobileapp` (OLD) while Xcode project uses `com.gsmelaka.mobileapp` (NEW) — mismatch would break Firebase/push on iOS
- **`firebase_options.dart`** iOS `apiKey` was the **Android** key (`AIzaSyDBpX3skwF4CruTyzhaV6XtUdbqf0egcU4`) instead of the correct iOS key (`AIzaSyD4TBX5T2fOgk4stWI5naae9PCibYkYQj4`)

### Completed
- [x] Generated saffron iOS app icons from `web/translogo.png` composited on `#E8A838` background (all 21 sizes)
- [x] Fixed `GoogleService-Info.plist` BUNDLE_ID → `com.gsmelaka.mobileapp`
- [x] Fixed `firebase_options.dart` iOS API key → `AIzaSyD4TBX5T2fOgk4stWI5naae9PCibYkYQj4`
- [x] Verified `MARKETING_VERSION` — main app correctly uses Flutter version (1.0.3+4); the `1.0` in pbxproj is only for RunnerTests target (harmless)
- [x] Verified `flutter analyze` — only pre-existing warnings, no errors from changes
- [x] Added `tool/generate_ios_icons.py` for regenerating iOS icons
- [x] Committed (commit `002d6ed`) and pushed to GitHub (`7fdb43e..002d6ed main -> main`)

### Result
- iOS app now shows the saffron Gurdwara icon matching Android
- iOS Firebase config now matches the app's bundle ID and uses the correct iOS API key
- Push notifications and Firebase init will work correctly on iOS

## Session 13: Add Path Filter to iOS Build Workflow (2026-08-17)

### Problem
Two iOS build actions were running at the same time for commits `002d6ed` and `ccc8cb7`. This was **expected** (two separate pushes each trigger a run), but it highlighted that documentation-only commits (e.g. memory-bank updates) were unnecessarily triggering full iOS builds, wasting Actions minutes.

### Completed
- [x] Explained to user that the two runs were from two separate pushes (not the duplicate-workflow issue fixed in Session 11)
- [x] Added `paths` filter to the iOS build workflow (`.github/workflows/ios-build.yml`) for both `push` and `pull_request` triggers
- [x] Paths that trigger a build: `gurdwara_app/lib/**`, `gurdwara_app/ios/**`, `gurdwara_app/android/**`, `gurdwara_app/pubspec.yaml`, `gurdwara_app/pubspec.lock`, `.github/workflows/ios-build.yml`
- [x] Committed (commit `a35085b`) and pushed to GitHub (`ccc8cb7..a35085b main -> main`)

### Result
- Documentation-only commits (e.g. memory-bank updates) no longer trigger an iOS build
- Only app code changes trigger the build, saving Actions minutes
- Note: This workflow change itself triggered a build (since the workflow file is in the paths filter) — expected and verifies the workflow still works

## Session 14: Show App Version in About Page Footer (2026-08-17)

### Completed
- [x] Added `package_info_plus` import to `main.dart` (dependency already present from Session 9)
- [x] Created `_AboutFooter` stateful widget that reads the installed app version via `PackageInfo.fromPlatform()` and displays it below the copyright line
- [x] Replaced the plain copyright `Text` in `_buildAboutContent` with the new `_AboutFooter` widget
- [x] Version displays as e.g. `Version 1.0.3 (4)` (version + build number from pubspec.yaml at build time)
- [x] Graceful fallback: if package info can't be read, only the copyright line shows
- [x] Verified `flutter analyze` — no new errors (only pre-existing warnings/infos remain)
- [x] Committed (commit `fbd3dcf`) and pushed to GitHub (`e280d53..fbd3dcf main -> main`)

### Result
- The About page footer now shows the installed app version (e.g. `Version 1.0.3 (4)`) below the copyright line
- Reads the actual installed build version, so it always reflects what the user has (useful for support/debugging)
- This change modified `lib/**`, so it triggered an iOS build (expected)

## Session 15: Hide Booking Card & Move About Card on Home Screen (2026-08-21)

### Completed
- [x] Removed the "Booking" immersive category card from the home screen Explore grid
- [x] Moved the "About" immersive category card up to the 4th position (replacing Booking)
- [x] Home screen Explore grid now shows: Calendar, Gallery, Barsi, About (clean 2×2 grid)
- [x] Verified `flutter analyze` — no new errors (only pre-existing warnings/infos remain)
- [x] Committed (commit `4099c93`) and pushed to GitHub (`55e7d40..4099c93 main -> main`)

### Key Changes
1. **`lib/main.dart`** (modified): Removed the `ImmersiveCategory` entry for "Booking" (subtitle: "Coming soon") and moved the "About" `ImmersiveCategory` up to take its place in the grid
2. **Booking card**: Was a placeholder with no `onTap` handler and no booking screen — completely hidden for now
3. **Result**: The Explore grid now has 4 cards (Calendar, Gallery, Barsi, About) forming a clean 2×2 layout

### Next Steps
- When ready to work on booking, add the Booking `ImmersiveCategory` back to the grid and implement the booking screen

## Session 16: Mobile App Beautification & Enhancements (2026-08-21)

### Completed
- [x] **Theme Color Fix**: Replaced blue/green/red color scheme with brand palette — Saffron (#E8A838), Navy (#1B365D), Gold (#C5A028), Cream (#FAF8F5)
- [x] **Branded Splash Screen**: New `branded_splash_screen.dart` — saffron→navy gradient with logo, fade-in + scale animation
- [x] **Smooth Page Transitions**: Fade + slide animation between bottom nav tabs (AnimatedSwitcher)
- [x] **Home Screen Hero**: Welcome card now uses saffron gradient, replaced "WELCOME : Guest" with today's date badge
- [x] **Offline Caching**: New `cache_service.dart` — events data cached with SharedPreferences (7-day expiry), falls back to cache on network failure
- [x] **Calendar Enhancements**: List view toggle (month grid ↔ event list), "Today" button, date badge tiles in list view
- [x] **Better Empty States**: Illustrated empty state on home "Upcoming Events" card (icon + friendly message)
- [x] **Settings Screen**: New 5th tab + home grid card — notification toggle, theme mode selection (system/light/dark), about section
- [x] Theme mode preference persisted in SharedPreferences and applied at app startup
- [x] `flutter analyze` — no new errors (only pre-existing warnings remain)
- [x] Committed (commit `617cbb0`) and pushed to GitHub (`6b2cccd..617cbb0 main -> main`)

### Key Changes
1. **`lib/config/theme.dart`**: Complete brand color overhaul — primary = saffron, secondary = navy, tertiary = gold, cream background
2. **`lib/widgets/branded_splash_screen.dart`** (new): Splash with logo on saffron→navy gradient + animations
3. **`lib/services/cache_service.dart`** (new): SharedPreferences-based caching with timestamps and expiry
4. **`lib/widgets/settings_screen.dart`** (new): Settings with notification toggle + theme override
5. **`lib/main.dart`**: Splash integration, tab transitions, theme mode loading, calendar list view, better empty states, Settings tab + card

### Next Steps
- Push notification deep linking (open relevant screen on notification tap)
- Gallery enhancements (masonry layout, swipe between full-screen images, share button)
- Onboarding screen for first-time users
- Language selection (English/Malay/Punjabi)

## Session 17: Calendar List Filter, Theme Auto-Switch & About Section Fixes (2026-08-21)

### Completed
- [x] **Calendar List View Filter**: When switching to the event list view, only events from today onwards are shown (past records hidden)
- [x] **Settings Dark Mode Auto-Switch**: Selecting Dark/Light/System in Settings now switches the app theme immediately (via `onThemeModeChanged` callback wired from `_GurdwaraAppState` → `HomeScreen` → `SettingsScreen`)
- [x] **Settings About Section**: Replaced temple icon with the Gurdwara logo (`web/logo.png`), and wording now reads "Developed for Gurdwara Sahib Melaka vX.X.X" (version read from pubspec via `package_info_plus`)
- [x] `flutter analyze` — no new errors (only pre-existing warnings/infos remain)
- [x] Committed (commit `55dcc93`) and pushed to GitHub (`2811971..55dcc93 main -> main`)

### Key Changes
1. **`lib/main.dart`** (modified): Added `_filterUpcomingEvents()` helper used by the calendar list view to show only today-and-future events; added `_applyThemeMode()` and passed `onThemeModeChanged` down to `SettingsScreen` so theme changes apply instantly
2. **`lib/widgets/settings_screen.dart`** (modified): Added `onThemeModeChanged` callback; About section now shows the Gurdwara logo and "Developed for Gurdwara Sahib Melaka vX.X.X" using `package_info_plus`

### Next Steps
- When ready, re-add the Booking card and implement the booking screen
- Push notification deep linking (open relevant screen on notification tap)
- Gallery enhancements (masonry layout, share button)
- Language selection (English/Malay/Punjabi)

## Session 18: Hero Banner, Gallery Swipe, Onboarding & Branded States (2026-08-21)

### Completed
- [x] **Home Hero Banner**: Replaced the gradient welcome card with a hero banner featuring the Gurdwara building image (`images/gurdwara/gurdwarafront.jpeg`) with a saffron→navy gradient overlay, kept the today's-date badge, and added a graceful gradient fallback if the image fails to load
- [x] **Gallery Swipe Between Photos**: Upgraded the full-screen viewer from a single image to a swipeable `PageView` (each page keeps pinch-to-zoom), with a "N / M" counter indicator; the grid stays a uniform 2-column layout
- [x] **Onboarding Screen** (new `lib/widgets/onboarding_screen.dart`): 3-page swipeable onboarding (Welcome / Events & Calendar / Stay Connected) with brand gradient, glassmorphism icons, `smooth_page_indicator`, Skip + Next/Get Started; shown only on first launch via a `SharedPreferences` flag (`onboarding_seen`)
- [x] **Branded Loading & Error States**: `_SplashLoading` now shows a pulsing saffron→navy gradient ring around the logo; `_ErrorState` got a saffron-tinted icon badge and a gradient Retry button
- [x] `flutter analyze` — no new errors (only pre-existing warnings/infos remain)

### Key Changes
1. **`lib/main.dart`** (modified): Hero banner in `_buildHomeContent`; `_GalleryUrlItem` now accepts the full image set + starting index and opens a swipeable `PageView` via new `_FullScreenImage` widget; `_SplashLoading` converted to a stateful pulsing gradient ring; `_ErrorState` restyled with saffron badge + gradient Retry; onboarding wiring (`_checkOnboarding`, `_finishOnboarding`, `_showOnboarding`) in `_GurdwaraAppState`
2. **`lib/widgets/onboarding_screen.dart`** (new): First-launch onboarding with 3 swipeable pages, brand gradient background, glassmorphism icon cards, page indicator, and Skip/Next/Get Started buttons

### Next Steps
- When ready, re-add the Booking card and implement the booking screen
- Push notification deep linking (open relevant screen on notification tap)
- Gallery enhancements (masonry layout, share button)
- Language selection (English/Malay/Punjabi)

## Session 19: Push Deep Linking, Quick Actions, Language Toggle, Offline About & Cleanup (2026-08-21)

### Completed
- [x] **Push Notification Deep Linking**: Added `NotificationService.onNotificationTap` static callback; `_HomeScreenState` registers it and maps a notification's `screen` payload to the matching bottom-nav tab (defaults to Calendar for event reminders)
- [x] **Pull-to-Refresh "Last Updated" Hint**: Home screen now shows a small "Updated h:mm" hint (with sync icon) after a pull-to-refresh completes
- [x] **Offline-First About Page**: `_fetchAboutData` now caches `contact_data.json` via `CacheService` (7-day expiry) and falls back to the cached copy on network failure
- [x] **Language Toggle (English/Malay/Punjabi)**: Added a Language section to the Settings screen using the existing `LocalizationService` + `AppLanguage` enum; the screen rebuilds on language change via a `ValueNotifier` listener
- [x] **Home Quick Actions**: Added a `_QuickActionsRow` under the hero banner with Call (`tel:`), Directions (Google Maps), and WhatsApp (`wa.me`) chips using `url_launcher`
- [x] **"What's New" Screen**: Wired `maybeShowWhatsNew(context)` to show the one-time changelog sheet after onboarding completes
- [x] **Analyzer Cleanup**: Removed unused `firebaseApp` variable, unused `theme` variable, unused `_barsidatesUrl` field, unnecessary null comparisons, and unused `dart:convert` import
- [x] `flutter analyze` — zero warnings/errors (only `avoid_print` info-level suggestions remain)

### Key Changes
1. **`lib/services/notification_service.dart`** (modified): Added `onNotificationTap` static callback; `_handleNotificationTap` reads the `screen` payload and invokes the callback
2. **`lib/main.dart`** (modified): Registered the deep-link callback in `_HomeScreenState`; added `_lastUpdated` state + hint on Home; added `_QuickActionsRow`/`_QuickAction` widgets; cached About contact data; wired `maybeShowWhatsNew`; cleaned up analyzer warnings
3. **`lib/widgets/settings_screen.dart`** (modified): Added Language section with `AppLanguage` radio list; listens to `LocalizationService.instance.language` to rebuild on change

### Follow-up Fix: Home Hero Banner Image Not Showing (2026-08-21)
- [x] Investigated why the home screen hero banner wasn't showing `images/gurdwara/gurdwarafront.jpeg`
- [x] **Verified the image & URL are fine**: `https://www.gurdwarasahibmelaka.com/images/gurdwara/gurdwarafront.jpeg` returns HTTP 200 with `Content-Type: image/jpeg` (115,504 bytes); downloaded and confirmed valid JPEG magic bytes (`ffd8ffe0` + `JFIF`); file also exists locally at `website/images/gurdwara/gurdwarafront.jpeg`
- [x] **Root cause**: `CachedNetworkImage` caches load failures too. If the image failed to load once (e.g. during earlier flaky-network testing), the app kept showing the saffron gradient `errorWidget` instead of retrying
- [x] **Fix**: Added a cache-busting query param `?v=2` to the hero image URL so `CachedNetworkImage` treats it as a fresh URL and re-fetches, clearing any previously cached load error
- [x] `flutter analyze` — no new errors (only pre-existing `avoid_print` info-level suggestions remain)
- [x] **Note**: Requires a hot restart (not just hot reload) on the device to clear the in-memory image cache
- [x] Committed (commit `6544420`) and pushed to GitHub (`969a697..6544420 main -> main`)


### Next Steps
- When ready, re-add the Booking card and implement the booking screen
- Gallery enhancements (masonry layout, share button)
- Apply localization strings more broadly across all screens


## Session 20: Time Zone Fix, Remove Language Toggle & Dynamic Quick Actions (2026-08-21)

### Completed
- [x] **"Last Updated" Hint Time Zone Fix**: The Home screen's "Updated h:mm" hint now calls `.toLocal()` on the timestamp before formatting, guaranteeing it always renders in the user's device time zone regardless of how the DateTime was created
- [x] **Removed Language Toggle**: Removed the entire Language section (English/Malay/Punjabi radio list) from the Settings screen, along with the `_onLanguageChanged` listener registration/disposal and the now-unused `localization_service.dart` import
- [x] **Quick Actions Use contact_data.json Number**: The Call and WhatsApp chips now use the contact number from the website's `contact_data.json` → `footerContact.phone` (`+6016-666 5513`) instead of the hardcoded `+6062811809` / `60162811809`
- [x] **Removed Directions Chip**: Removed the Directions (Google Maps) quick-action chip and its `_mapsQuery` constant; the row now shows only Call + WhatsApp
- [x] `flutter analyze` — no new errors (only pre-existing `avoid_print` info-level suggestions remain)

### Key Changes
1. **`lib/main.dart`** (modified): `_QuickActionsRow` now takes a required `phoneNumber` parameter and strips non-digits for the `wa.me` link; added `_contactNumber` state + `_loadContactNumber()` in `_HomeScreenContentState` that fetches `contact_data.json` and passes the number to the row (row hidden until the number loads); removed the Directions chip and `_mapsQuery`; added `.toLocal()` to the "last updated" hint
2. **`lib/widgets/settings_screen.dart`** (modified): Removed the Language section UI, the `LocalizationService.instance.language` listener, the `_onLanguageChanged` method, and the unused `localization_service.dart` import

### Note
- No git commit/push was performed because the `d:\GSM` workspace is not currently a git repository (no `.git` directory found). The previous repo was at `https://github.com/kodihammer73/Gurdwaraapp.git`.

### Follow-up Fix: Gallery RenderFlex Overflow Crash (2026-08-21)
- [x] Fixed a `RenderFlex overflowed by 83 pixels` crash that occurred when opening the Gallery tab
- [x] **Root cause**: `_SplashLoading` was a fixed 128×128 widget (88px ring + 16px gap + 24px spinner). When used as the `placeholder` for `CachedNetworkImage` in the gallery grid tiles, it was squeezed into a small box (e.g. 128×44.8 after padding), causing the vertical Column to overflow
- [x] **First attempt (reverted)**: Made `_SplashLoading` constraint-aware using `LayoutBuilder` — but this broke the full-screen loading states because `_SplashLoading` is also used inside `SliverFillRemaining` (Home/Calendar/Gallery/About), which computes intrinsic dimensions and threw `LayoutBuilder does not support returning intrinsic dimensions`
- [x] **Final fix**: Reverted `_SplashLoading` to its original fixed-size form (no `LayoutBuilder`), and changed the gallery image `placeholder` to use a simple centered 24×24 `CircularProgressIndicator` instead of `_SplashLoading`. This avoids the overflow in small grid tiles without affecting the full-screen loading states
- [x] `flutter analyze` — no new errors (only pre-existing `avoid_print` info-level suggestions remain)


### Next Steps
- When ready, re-add the Booking card and implement the booking screen
- Gallery enhancements (masonry layout, share button)
- Apply localization strings more broadly across all screens


## Development Starting Points







1. **Android Development**: Use `flutter run` on Windows with Android emulator

2. **Dependency Management**: Update pubspec.yaml with required packages
3. **UI Implementation**: Start with main.dart and create base screens
4. **GitHub Integration**: Connect local repo to GitHub for CI/CD testing
5. **Push Notifications**: Deploy PHP backend files to mini PC, configure FCM key, rebuild APK



## 2026-09-04 - iOS App Store submission (GitHub Actions signed IPA)

### Goal
Enable building a **signed** iOS .ipa via GitHub Actions and auto-upload to App Store Connect
(Android 1.0.6 was already live on Google Play under `com.gsmelaka.mobileapp`).

### What was completed
- Apple Developer Program (Individual) enrollment active; Apple ID `hammerjit@hotmail.com`.
- App Store Connect app record created: Bundle ID / SKU = `com.gsmelaka.mobileapp`, name decided
  = **"Gurdwara Sahib Melaka"** (App Store), on-phone icon label stays **GSMelaka** (in code, no change).
- Certificates, Identifiers & Profiles:
  - Identifier `com.gsmelaka.mobileapp`.
  - **iPhone Distribution** cert (identity: `iPhone Distribution: Hemerjit Singh (536335249D)`),
    stored as p12 (Team ID = `536335249D`).
  - App Store distribution provisioning profile (also stored).
- Credentials kept locally in `D:\gsm\app\apple-certs\` (gitignored). NEVER commit this folder.
- GitHub secrets added on repo `kodihammer73/Gurdwaraapp`:
  `APPLE_DIST_P12`, `APPLE_DIST_P12_PASSWORD`, `APPLE_DIST_PROFILE`, `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`.
  (Unused/removable: `APPLE_API_KEY_ID`, `APPLE_API_ISSUER_ID`, `APPLE_API_KEY_FILE` - API-key method
  did not work for an Individual account; switched to Apple ID + App-Specific Password.)
- Workflow `app/.github/workflows/ios-build.yml` now:
  build unsigned -> sign with iPhone Distribution cert -> embed profile + aps-environment ->
  package .ipa -> (on a `v*` tag only) upload to App Store Connect via `xcrun altool -u/-p`
  -> create GitHub release.
- `app/gurdwara_app/ios/Runner.xcodeproj/project.pbxproj`: Runner Release target signing ->
  Manual / Apple Distribution identity / DEVELOPMENT_TEAM 536335249D (mostly informational now,
  since CI signs manually after `--no-codesign` build).
- Added `app/.gitignore` to exclude `apple-certs/`, `.p12`, `.p8`, `.cer`, `.key`.

### Current status (as of EOD)
- Build **1.0.6 (7)** was uploaded and submitted for review: **iOS App 1.0.6, "Waiting for Review"**
  (Submission ID `985b5411-7eef-47e7-9e43-82cb65f3226c`, submitted Sep 4, 2026).
- Export compliance: none / no proprietary crypto. Age rating answered all-No -> 4+,
  Age category "Not Applicable", primary category "Lifestyle".

### Remaining / next steps (tomorrow)
- CONFIRM App Information -> Name is set to "Gurdwara Sahib Melaka". If the field was blank/locked
  while Waiting for Review, may need Cancel Submission -> rename -> resubmit.
- Watch review; address any App Review issues (make sure backend at gurdwarasahibmelaka.com is live so
  events/gallery screens are not empty for the reviewer).
- After approval: release (manual or auto per release option chosen).
- Future releases: bump `pubspec.yaml` version/build, commit, push tag `vX.Y.Z` -> CI uploads automatically.
- Optional cleanup (not started): remove duplicate run when a tag push also rebuilds on main push.
- NOTE: There are pre-existing uncommitted local edits in `main.dart`, `AndroidManifest.xml`,
  `.flutter-plugins-dependencies` that were NOT part of this iOS work - left untouched/uncommitted.

