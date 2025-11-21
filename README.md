Table of Contents

- [Description](#description)
- [General Architecture](#general-architecture)
- [Specifications](#specifications)
- [Setting Up](#setting-up)
- [Disclaimers](#disclaimers)
- [Reference Documentation](#reference-documentation)

# Description

This directory is the UI controller of the application. In order for
it to work correctly it must be connected to the backend API gateway.
For more information on the matter contact @SadSpongeBob.

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

# General Architecture

The application is using feature-based structure. More information can be found
under [this link](https://codewithandrea.com/articles/flutter-project-structure/).
For the architectural design of the directories please refer to [this document](docs/ARCHITECTURE.md).


# Specifications

## Prerequisite

The application requires:

- Dart 3.5+
- Flutter 3.2+

The preferred IDE is WebStorm / IntelliJ.

## Libraries & Frameworks

The application uses:

- Expo Router 5.0
- React 19.0
- React Native 0.79
- Babel 7.25
- Zod 3.25

# Setting Up

Given that you have Flutter and Dart SDKs setup, to set up this project:

1. Install the project dependencies:
   ```bash
   flutter pub get
   ```
2. Run code generation:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. Run the application:
   ```bash
   flutter run
   ```

# Disclaimers

+ The README file is only to be considered a resource in setting up the repository.
+ This file should NOT be treated as up-to-date.


# Reference Documentation

* [Official Flutter Documentation](https://docs.flutter.dev/)
* [Official Dart Documentation](https://dart.dev/docs/)
* [Riverpod Documentation](https://pub.dev/packages/riverpod)
* [Acanthis Validation Documentation](https://acanthis.serinus.app/)
* [Go_router Documentation](https://pub.dev/packages/go_router)
* [Dio Documentation](https://pub.dev/packages/dio)
* [Flutter Animate Documentation](https://pub.dev/packages/flutter_animate)
* [mobx Documentation](https://github.com/mobxjs/mobx.dart#mobxdart)

