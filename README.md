# Open Earable


This directory is the UI controller of the application. In order for
it to work correctly it must be connected to the backend API gateway.

---

## Description

The goal of this project is to develop a Flutter application
for recording study sessions through video. The app will
primarily capture video data in combination with sensor data.
Using a tablet application, external sensors (Open-Wearable
devices) can be connected.

Within the app, users will be able to create video recordings
while simultaneously collecting sensor data from the
connected devices.

All collected data should be organized into projects,
and it must be possible to assign participants to these projects.
This enables the execution of studies even when the study
supervisor is not physically present.

---

## Architecture

The application is using feature-based structure. More information can be found
under [this link](https://codewithandrea.com/articles/flutter-project-structure/).
For the architectural design of the directories please refer to [this document](docs/ARCHITECTURE.md).

---

## Specifications

### Prerequisites

The application requires:

- **Flutter SDK (latest stable recommended)**
- **Dart SDK 3.10+**
- **Android Studio** (for device builds)
- **A connected physical device or emulator**

You can verify your setup with:

```bash
  flutter doctor
```

---

### Libraries & Frameworks

Core:
- Flutter
- Dart
- flutter_riverpod (state management)
- go_router (routing)
- dio (HTTP client)
- flutter_dotenv (environment variables)

Storage & Security
- flutter_secure_storage
- shared_preferences
- path_provider

Media & File Handling
- camera
- image_picker
- video_player
- video_thumbnail
- file_picker
- image

Connectivity & Sensors
- connectivity_plus
- geolocator
- flutter_blue_plus (Bluetooth)
- open_earable_flutter (device integration)

Visualization
- fl_chart (sensor charts)


Utilities
- uuid
- logger
- path

---

### Recommended IDE

The project is developed using:
- IntelliJ IDEA or WebStorm
- Flutter plugin
- Dart plugin

You may also use:
- Android Studio
- VS Code (with Flutter + Dart extensions)

---

## Setting Up

1️⃣ Clone the repository
```bash
   git clone <repository-url>
   cd openearable
```

2️⃣ Install dependencies
```bash
   flutter pub get
```

3️⃣ Run the application
```bash
   flutter run
```

---

### Environment Configuration

The project uses `flutter_dotenv`

Make sure the `.env` file exists inside: `assets/.env`

If there is an `.env.example` copy it:
```bash
   cp assets/.env.example assets/.env
```
Then update the values accordingly.

---

### Assets

The project includes:
- assets/images/
- assets/buttons/
- assets/buttons/home/
- assets/.env

Ensure assets are correctly declared in `pubspec.yaml`

---

## Build (APK)

> ⚠️ There is no IOS or Web support.

```bash
   flutter build apk
```

---

## Testing

The project includes **unit/widget tests** and **integration tests**.

### Unit & Widget Tests

Run unit and widget tests with:

```bash
   flutter test
```

---

### Integration Tests
Integration tests are located in the `integration_test/` directory.
Run integration tests with:

```bash
   flutter test integration_test/
```

---

## Disclaimers

+ The README file is only to be considered a resource in setting up the repository.
+ This file should **not** be treated as up-to-date.

---

## Reference Documentation

* [Official Flutter Documentation](https://docs.flutter.dev/)
* [Official Dart Documentation](https://dart.dev/docs/)
* [Riverpod Documentation](https://pub.dev/packages/riverpod)
* [Go_router Documentation](https://pub.dev/packages/go_router)
* [Dio Documentation](https://pub.dev/packages/dio)
* [Flutter Animate Documentation](https://pub.dev/packages/flutter_animate)
