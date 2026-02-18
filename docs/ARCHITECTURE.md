# Architecture

This document describes the high-level architecture of the directory.
If you want to familiarize yourself with the code base,
you are just in the right place!

## Project Structure

This project uses feature based structure.
All source code is under `lib/`.

```pgsql
lib/
├── api/                      # API client & service modules
|   ├──interceptors           # Interceptors
|   |   └── interceptor_name.dart
│   ├── services/
│   │   └── service/          # One folder per domain
│   │       └── service_name.dart
│   └── client_dio.dart       # Dio config
│
├── features/
|   └── feature/
|       ├── controllers/
|       ├── pages/
|       ├── state/
|       └── widgets/
|
├── app/                    # Reusable globals
|   ├── constants/           # Static config and design tokens
|   ├── routing/
|   ├── ui/
|   ├── utils/               # Generic helpers and utilities
│   └── widgets/
│       └── widget_name.dart  # Component file
```

## Code Map

- `api/`

  Contains the configuration of Dio as well as the endpoints that are being
  used in the application.
    - `{service}/`

      Each service will have its own folder with the `snake_case` convention.
      These services should contain every endpoint defined in the backend
      and have their own callable functions under the directory.

- `features/`

  Contains all the pages inside the application.

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