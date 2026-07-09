# Quiz Online

A Flutter-based quiz application for lecturers (`dosen`) and students (`mahasiswa`) with Firebase integration and a mock fallback mode.

## Features

- Role-based authentication for `dosen` and `mahasiswa`
- Login and registration flow
- Lecturer dashboard for quiz management
- Student dashboard for taking quizzes, reviewing answers, and viewing results
- Firebase Auth, Firestore, and Firebase Messaging support
- Local mock/demo mode when Firebase initialization is unavailable
- Provider-based state management
- Dark mode support and custom UI components

## Tech stack

- Flutter
- Dart
- Provider
- Firebase Core
- Firebase Auth
- Cloud Firestore
- Firebase Messaging
- Shared Preferences
- UUID
- Intl

## Getting started

### Prerequisites

- Flutter SDK 3.10.4 or compatible
- Android Studio / Xcode / Visual Studio (for desktop builds)
- A Firebase project with `google-services.json` and `GoogleService-Info.plist` if using Firebase mode

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

### Build the app

```bash
flutter build apk
flutter build ios
flutter build web
```

## Firebase mode

By default, the app attempts to initialize Firebase in `ServiceRegistry`. If Firebase initialization fails, the app falls back to mock/demo services.

To enable Firebase mode, make sure `lib/utils/constants.dart` has:

```dart
static const bool attemptFirebase = true;
```

Then add your Firebase configuration files:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

## Notes

- This project is configured as a local Flutter app and is not published to pub.dev.
- The app includes platform folders for Android, iOS, Linux, macOS, Windows, and Web.

## Repository

https://github.com/NanTechID/AplikasiQuiz
