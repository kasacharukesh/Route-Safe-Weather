# RouteSafe Flutter starter

This is a native Flutter starter inspired by the supplied RouteSafe website. It includes:
- Current weather at the map centre using Open-Meteo
- Place lookup using OpenStreetMap Nominatim
- Driving route lookup and route geometry using OSRM
- Interactive OpenStreetMap map with route line and start/end markers
- Device location (permission requested at runtime)
- Turn-by-turn text steps returned by OSRM
- Local incident reports and saved routes using SharedPreferences
- Dark RouteSafe-style UI and bottom navigation

## Important limitations

This is a working starter, not a complete one-to-one port of every website feature. Hourly/7-day forecast charts, push notifications, voice assistant, live hazard geofences, weather overlays, CSV trip export, emergency SOS workflow, trip replay, language translations, EV/fuel calculations and backend/community synchronization are not implemented yet. Do not present the local incident list as a public shared reporting system. Weather risk is not an official emergency warning.

The app uses public/demo endpoints. Nominatim and OSRM have usage policies and are not guaranteed production services. For a public launch, use a compliant geocoding/routing provider, attribution, caching and a backend where appropriate. OpenStreetMap tiles require internet and attribution.

## 1. Install tools on Windows

1. Install Git for Windows: https://git-scm.com/download/win
2. Download the stable Flutter SDK: https://docs.flutter.dev/install
3. Extract it to `C:\dev\flutter` (avoid `Program Files`).
4. Add `C:\dev\flutter\bin` to Windows PATH, then restart PowerShell and Android Studio.
5. Run:
   ```powershell
   flutter --version
   dart --version
   flutter doctor -v
   ```
   Dart is bundled with Flutter; do not install a separate Dart SDK for Flutter development.
6. Install Android Studio: https://developer.android.com/studio
7. Android Studio > Settings > Plugins: install **Flutter** (the Dart plugin is normally installed with it); restart.
8. Android Studio > SDK Manager: install an Android SDK platform, Android SDK Build-Tools, Android SDK Command-line Tools (latest), Android Emulator and Platform-Tools.
9. Run `flutter doctor --android-licenses` and accept the licenses, then run `flutter doctor -v` again.
10. Android Studio > Device Manager > Create Virtual Device > choose a Pixel device > download a system image > Finish > Start.

## 2. Create the Android platform folder for this source

Open PowerShell in the extracted `RouteSafe_Flutter` folder. Confirm `flutter` works, then run:

```powershell
flutter create --platforms=android,web,windows --org com.routesafe .
flutter pub get
flutter analyze
flutter run
```

`flutter create` generates the native platform folders (including `android/`) and the standard Flutter project metadata around the supplied `lib/` and `pubspec.yaml`. If Flutter asks whether to overwrite an existing file, stop and inspect rather than blindly overwriting your source.

For Android Studio: File > Open > select the `RouteSafe_Flutter` folder. Wait for indexing and package resolution. Select your emulator in the device selector and press Run.

## 3. Project folder and what each file is for

```text
RouteSafe_Flutter/
├── android/                 # Generated Android app, Gradle and permissions
├── web/                     # Generated web runner (if selected)
├── windows/                 # Generated Windows runner (if selected)
├── assets/
│   └── images/              # App images and illustrations
├── lib/
│   ├── main.dart             # App entry point, theme and MaterialApp
│   ├── models/
│   │   └── incident.dart     # Incident data model and JSON conversion
│   ├── screens/
│   │   └── home_screen.dart  # Main dashboard, route planner, map and tabs
│   ├── services/
│   │   ├── local_store.dart  # Device storage for reports and saved routes
│   │   └── route_safe_service.dart # Weather, geocoding and routing API calls
│   ├── widgets/              # Reusable UI components (create as needed)
│   ├── providers/            # App state classes (create when state grows)
│   ├── utils/                # Helpers and validators
│   ├── theme/                # Separate theme files (optional)
│   └── constants/            # API endpoints and app constants (optional)
├── test/                     # Unit/widget tests
├── pubspec.yaml              # Packages, assets and app metadata
├── pubspec.lock              # Generated exact dependency versions
├── analysis_options.yaml     # Dart lint rules
├── .gitignore
└── README.md
```

The `android/`, `web/`, `windows/`, `pubspec.lock` and `.dart_tool/` content is generated or managed by Flutter. Do not manually create every generated file. For any new Flutter app, use `flutter create`; add only the Dart files and folders your app actually needs.

## 4. Add another Dart file in Android Studio

1. In the left Project panel, switch to **Project** or **Android** view as needed.
2. Expand `lib`.
3. Right-click `lib` > New > Directory. Create a folder such as `screens`, `models`, `services`, `widgets` or `providers`.
4. Right-click the folder > New > Dart File.
5. Use lowercase `snake_case`, for example `profile_screen.dart`.
6. Add the import to the file that uses it, for example:
   `import 'screens/profile_screen.dart';`
7. Save and run `flutter analyze`.

## 5. Useful commands

```powershell
flutter doctor -v       # Check toolchain
flutter devices         # List phones/emulators
flutter pub get         # Download dependencies
flutter analyze         # Find code issues
flutter test            # Run tests
flutter run             # Run on selected device
flutter clean           # Remove generated build cache
flutter pub get         # Restore packages after clean
flutter build apk --release
```

## 6. Android location permission

The app requests location permission at runtime. If Android blocks it or the app reports permission denied, inspect `android/app/src/main/AndroidManifest.xml` and ensure these permissions appear directly inside the `<manifest>` element and outside `<application>`:

```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

Do not request background location for this starter. It only reads the device's location when the user taps the location button.

## 7. Performance notes

- API requests are made only when needed; the app does not continuously poll weather.
- The map is limited to one map widget and one route polyline.
- Saved reports/routes are small local JSON/string records.
- Use a physical device or release build for realistic performance measurements. Debug builds are slower.
- Run `flutter build apk --release` for a release APK.
- Faster performance cannot be guaranteed across every device/network. Network response time, map tile loading and emulator performance are outside the app's control.

## Official documentation

- Flutter install: https://docs.flutter.dev/install
- Android setup: https://docs.flutter.dev/platform-integration/android/setup
- Android Studio editor: https://docs.flutter.dev/tools/android-studio
- Create a Flutter app: https://docs.flutter.dev/reference/create-new-app
- Dart language: https://dart.dev/language
