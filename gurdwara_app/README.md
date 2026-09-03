# Gurdwara Mobile App

A cross-platform mobile application for Gurdwara management, built with Flutter. Supports both Android (APK) and iOS (IPA) platforms.

## Features

- Cross-platform support (Android & iOS)
- Modern Material Design 3 UI
- Efficient state management with Provider
- Local and remote data persistence
- Internationalization support

## Prerequisites

### Windows (Local Development)
- **Flutter SDK**: Latest stable version
- **Android SDK**: API level 21 or higher
- **Java Development Kit (JDK)**: Version 11 or higher
- **Visual Studio Code**: With Flutter and Dart extensions

### iOS (GitHub Actions)
- Build pipeline configured via GitHub Actions
- Automatic IPA generation on push to main/develop

## Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/gurdwara_app.git
cd gurdwara_app
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app on Android**
```bash
flutter run
```

## Build Instructions

### Android APK (Local Build on Windows)

Build a debug APK:
```bash
flutter build apk --debug
```

Build an obfuscated release APK:
```bash
flutter build apk --release --obfuscate --split-debug-info=build/symbols/android
```

Build the Play Store App Bundle with the same options:
```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols/android
```

R8 shrinking/obfuscation and resource shrinking are enabled for Android release builds.
Keep `build/symbols/android` private and back it up; it is required to decode Dart stack traces from Play Console crashes.

Output locations:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

### iOS IPA (GitHub Actions)

1. Push changes to `main` or `develop` branch
2. GitHub Actions workflow automatically triggers
3. IPA is generated and available as artifact
4. Create a tag to generate a release with IPA attachment

```bash
git tag v1.0.0
git push origin v1.0.0
```

## Project Structure

```
lib/
├── main.dart              # App entry point
├── screens/               # UI screens
├── widgets/               # Reusable components
├── models/                # Data models
├── services/              # Business logic
├── providers/             # State management
└── utils/                 # Utilities & constants

android/                   # Android-specific config
ios/                       # iOS-specific config
test/                      # Unit & widget tests
```

## Configuration

### Android Configuration
- **Min SDK Level**: 21
- **Target SDK Level**: Latest (configured in android/app/build.gradle)
- **Package Name**: com.example.gurdwara_app

### iOS Configuration
- **Deployment Target**: 11.0
- **Bundle Identifier**: com.example.gurdwaraApp
- **Supported Devices**: iPhone, iPad

## Development

### Running Tests
```bash
flutter test
```

### Running with Hot Reload
```bash
flutter run
```

### Code Analysis
```bash
flutter analyze
```

### Format Code
```bash
dart format lib/
```

## Dependencies

Key packages included:
- **provider**: State management
- **go_router**: Navigation
- **dio**: HTTP client
- **shared_preferences**: Local storage
- **hive**: Advanced local database
- **intl**: Internationalization

See `pubspec.yaml` for complete dependency list.

## Build Troubleshooting

### Android Build Issues
- Clear build cache: `flutter clean`
- Update Gradle: Update `android/build.gradle`
- Check Java version: `java -version` (Should be 11+)

### iOS Build Issues (GitHub Actions)
- Check workflow logs in GitHub Actions tab
- Verify pod cache: Workflows handle this automatically
- Check deployment target compatibility

## Contributing

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Commit changes: `git commit -am 'Add feature'`
3. Push to branch: `git push origin feature/your-feature`
4. Submit a pull request

## License

This project is licensed under the MIT License - see LICENSE file for details.

## Support

For issues and questions, please create an issue in the GitHub repository.

---

**Last Updated**: 2026-07-23
**Flutter Version**: Latest stable