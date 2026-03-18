# Project Jordan

Flutter app for NBA news, scores, teams, and Firebase authentication.

## Supported targets

- Android
- iOS
- Web

## Stack

- Flutter 3.41.x
- Dart 3.11.x
- Firebase Core/Auth
- Google Sign-In
- NewsAPI
- BALLDONTLIE

## Project structure

- `lib/auth/`: auth gate, sign-in, and sign-up screens
- `lib/UI/`: home tabs and primary app screens
- `lib/components/`: reusable UI widgets
- `lib/model/`: API/domain models
- `lib/services/`: auth and API integrations
- `.vscode/`: committed VS Code workspace setup for this repo

## Prerequisites

- Flutter stable installed and on your `PATH`
- Xcode and CocoaPods for iOS builds
- Android SDK / emulator for Android builds
- iOS deployment target `15.0` or newer
- Firebase project already configured with:
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`
  - `lib/firebase_options.dart`
- Email/password auth enabled in Firebase Auth
- Google auth enabled in Firebase Auth if you want Google sign-in

## Runtime configuration

### Required for scores and scoreboard

BALLDONTLIE now requires an API key. Provide it with:

```bash
flutter run --dart-define=BALLDONTLIE_API_KEY=your_api_key
```

Without this key, the app still launches. The score tab falls back to bundled
demo data and the stats tab shows a clear configuration warning instead of
hanging.

### Local VS Code setup

For local runs from VS Code:

1. Copy `.dart_define.local.example.json` to `.dart_define.local.json`
2. Fill in the API key values you already have
3. Launch the app from one of the committed `.vscode/launch.json` profiles

The real `.dart_define.local.json` file is ignored by git and is passed to
Flutter automatically through `--dart-define-from-file`.

### Required for the primary news feed

The redesigned news page uses NewsAPI as the primary source:

```bash
flutter run --dart-define=NEWSAPI_API_KEY=your_newsapi_key
```

### Optional fallback news provider

To enable the GNews fallback/merge path:

```bash
flutter run --dart-define=GNEWS_API_KEY=your_gnews_key
```

If only one news provider key is configured, the app still works with that
single provider. If both providers are unavailable, the app falls back to a
bundled demo feed so the screen remains usable.

### Premium stats note

The stats dashboard uses BALLDONTLIE standings, leaders, and team season
averages. Those endpoints may require a higher BALLDONTLIE plan than the basic
games/teams endpoints. If your key does not have access, the app shows partial
data warnings instead of crashing.

### Optional for native Google Sign-In

If your Firebase/Google setup needs a server client ID on Android or iOS, run:

```bash
flutter run --dart-define=GOOGLE_SIGN_IN_SERVER_CLIENT_ID=your_server_client_id
```

## Common commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d emulator-5554 --dart-define=BALLDONTLIE_API_KEY=your_api_key --dart-define=NEWSAPI_API_KEY=your_newsapi_key --dart-define=GNEWS_API_KEY=your_gnews_key
flutter run -d chrome --web-hostname localhost --web-port 7357 --dart-define=BALLDONTLIE_API_KEY=your_api_key --dart-define=NEWSAPI_API_KEY=your_newsapi_key --dart-define=GNEWS_API_KEY=your_gnews_key
```

## VS Code

The repo includes:

- `.vscode/settings.json` for format-on-save and Dart import organization
- `.vscode/launch.json` for Android, iOS, and Chrome launch profiles
- `.vscode/extensions.json` for recommended Flutter extensions

## Notes

- The current visual theme and screen flow were intentionally preserved during
  modernization while the page layouts were redesigned.
- News no longer uses a bundled API key. Configure `NEWSAPI_API_KEY` and
  optionally `GNEWS_API_KEY` at runtime.
- Scores and news fall back to bundled demo content when live APIs are not
  reachable or local keys are missing.
- Web uses Firebase Auth for Google popup sign-in so the existing custom button
  can remain in place.
