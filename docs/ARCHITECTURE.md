# Architecture

This document describes the high-level architecture of the directory.
If you want to familiarize yourself with the code base,
you are just in the right place!

## Project Structure

This project uses feature based structure.
All source code is under `lib/`. Use directory based routing 
under `src/app/`.

```pgsql
src/
├── api/                      # API client & service modules
|   ├──interceptors           # Interceptors
|   |   └── interceptor_name.dart
│   ├── services/
│   │   └── service/          # One folder per domain
│   │       └── service_name.dart
│   └── client.dart           # Dio config
│
├── app/                      # Pages
│   ├── app                   # Contains application pages
│   |   └── screen/
│   |       └── screen_name.dart
│   └── auth                  # Contains auth-specific pages
│       └── screen/
│           └── screen_name.dart
│
├── widgets/                  # Reusable UI components
│   └── widget/               # Each component as a folder
│       └── widget_name.dart  # Component file
│
├── constants/                # Static config and design tokens
│   ├── colors.dart
│   ├── text_styles.dart
│   └── spacing.dart
│
├── utils/                    # Generic helpers and utilities
|   ├── validators.dart
│   └── date_format.dart
│
├── models/                   # Global or shared classes/models
|   └── user.dart
```

## Code Map

- `api/`

  Contains the configuration of Dio as well as the endpoints that are being
  used in the application.
    - `{service}/`

      Each service will have its own folder with the `snake_case` convention.
      These services should contain every endpoint defined in the backend
      and have their own callable functions under the directory.

- `app/`

  Contains all the pages inside the application.
    - `app/`

      This is the main directory for the pages inside the application.
      These pages defined should only be available once after an authentication into
      the app.
    - `auth/`

      This directory contains only the pages necessary for authentication.

- `widgets/`

  Contains the reusable components such as buttons and input boxes.
    - `{widget}/`

      Each component should have its own directory inside following the `snake_case`
      convention.


- `constants/`

  Contains the static design tokens such as colors.

- `utils/`

  Contains the helper and utility methods.

- `models/`

  Contains the globally used classes.
