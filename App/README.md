# mobile_project

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase Cloud Messaging

The app registers an FCM token after login and sends it to the backend.

Before real push notifications can work, connect this app to your Firebase
project:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Or add the platform Firebase config manually:

- Android: `android/app/google-services.json`
- iOS/macOS: `GoogleService-Info.plist`

If Firebase is not configured yet, the app still runs, but FCM registration is
skipped and a warning is logged.
