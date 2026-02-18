Table of Contents

- [File Naming Conventions](#file-naming-conventions)
- [Component Guidelines](#component-guidelines)
- [API Layer](#api-layer)
- [Testing](#testing)
- [Formatting](#formatting)
- [Git](#git)
- [Documentation](#documentation)
- [Dependencies](#dependencies)

## File Naming Conventions

All files and directories will be following the `snake_case`: `login.dart, text_styles.dart..`

The classes inside files will follow the `CamelCase`: `class ButtonWidget()..`

## Component Guidelines

- Keep components small and focused (one responsibility).

## API Layer

- Each server declared in the backend should have its own `@/lib/api/services/service_folder/`
    - In `@/service_folder/service_endpoints.dart` URIs of the
      endpoints of that service should be declared.
    - In `@/service_folder/service_name.dart` should the endpoint calls happen.
- Use `dio` configured under `@/lib/api/client_dio.dart`

## Testing

- Each service, component and page must be tested.
- Service and components should be `unit tested`
    - Mock other dependencies
    - Test in isolation
    - Given a value should return an expected value (Given-When-Then)
- Pages should be `integration tested`
    - Mock external dependencies such as an external post call
    - Test how the components and services integrate with each other
    - Given a value should return an expected value (When-Then)

### Unit test example:

// TODO

### Integration Test Example

// TODO

## Formatting

- **Dart Format** is used for consistent formatting. This is the default
  formatter included in IDE. Just don't forget to use it after changes.

## Git

- Always create a new branch for the new feature or bugfix.
    - Use `git checkout -b feat/feature-name-ticket-id` for the feature branches.
- Always create a new branch from the `main` branch.
    - Use `git checkout main` to switch to the main branch.
    - Use `git pull origin main` to update the main branch.
    - Use `git checkout -b feat/feature-name-ticket-id` to create a new branch.
- Always create a pull request for the new branch.
- Always add the reviewer to the pull request.
- Always add the ticket id to the commit message.
- Make sure that your branch is up-to-date with the `main` branch.
    - Use `git pull origin main` to update your branch.
    - Use `git rebase main` to rebase your branch.
- Use `feat/` for the feature branches.
- Use `fix/` for fix branches.
- Use `bugfix/` for the bugfix branches.
- Use `doc/` for updating documentations.
- Commit messages should be clear and concise following the `type(scope): message [ticket-id]` pattern.
  For example for a feature: `feat(Auth): Authentication and Authorization added [TASK-26]`
  or for the test environment: `test(FriendService): Added the missing tests on addFriend endpoint [TASK-58]`
- In order to sort merge conflicts or get the updates from the `main` branch, use `merge main into your-branch` option
  instead of `rebase`:
    ```bash 
    # 1. Fetch the latest changes from the remote (good practice)
    git fetch origin

    # 2. Check your current branch (optional)
    git branch

    # 3. Switch to your working branch
    git checkout your-branch

    # 4. Make sure your working branch is up to date
    git pull origin your-branch

    # 5. Merge the latest main branch into your working branch
    git merge origin/main
    ```

## Documentation

- Write documentations for the methods in:
    - Widgets
    - API calls
- Write a short description for the method. What it does and for who/what it does it.
- Try including the parameters and return types.
- Use:
    - `**Parameters:**` for the parameters used.
    - `**Returns:**` for return values.
    - `**Throws:**` for exceptions.
    - `**Author:**` to tag yourself.

```dart
/// Creates a new project on the server.
///
/// **Parameters:**
/// - [title]: The name of the project.
/// - [description]: Optional additional details to store with the project.
///
/// **Returns:**
/// A [ProjectSummary] representing the newly created project.
///
/// **Throws:**
/// - [DioException] if the request fails or the server rejects the data.
///
/// **Author:** SadSpongeBob
Future<ProjectSummary> createProject({ ... })
```

## Dependencies

- Use the latest version of the dependencies.
- Use the stable version of the dependencies.
- Use the dependencies that are actively maintained.
- Use the latest version of the dependencies.
- Use the stable version of the dependencies.
- Use the dependencies that are actively maintained.