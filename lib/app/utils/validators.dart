/// A collection of reusable form validation utilities.
///
/// Provides common validators for user input such as email, password,
/// name, and non-empty fields. Each validator returns an error message
/// if validation fails, or `null` if the input is valid.
class Validators {
  /// Regular expression used to validate email addresses.
  static final emailRegex = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  /// Regular expression that matches any whitespace characters.
  static final whiteSpaceRegex = RegExp(r'\s+');

  /// Regular expression used to validate names containing only letters
  /// and single spaces between words.
  static final nameRegex = RegExp(r'^[A-Za-z]+(?: [A-Za-z]+)*$');

  /// Validates that the given value is not null or empty.
  ///
  /// Returns an error message if the value is null or consists only of
  /// whitespace, otherwise returns `null`.
  static String? notEmpty(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "This field cannot be empty";
    }
    return null;
  }

  /// Validates that the given value is a properly formatted email address.
  ///
  /// Returns an error message if the value is null, empty, or does not
  /// match the email format defined by [emailRegex]. Otherwise returns `null`.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Email is required";
    }

    if (!emailRegex.hasMatch(value.trim())) {
      return "Enter a valid email address";
    }

    return null;
  }

  /// Validates a password based on basic security rules.
  ///
  /// The password:
  /// - Must not be null or empty
  /// - Must not contain whitespace
  /// - Must be between 8 and 30 characters long
  ///
  /// Returns an error message if validation fails, otherwise returns `null`.
  static String? password(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Password is required";
    }

    if (whiteSpaceRegex.hasMatch(value)) {
      return "Password can't contain spaces";
    }

    if (value.length < 8) {
      return "Password must be at least 8 characters";
    }

    if (value.length > 30) {
      return "Password length should not exceed 30 characters";
    }

    return null;
  }

  // Validates a user's name.
  ///
  /// The name must:
  /// - Not be null or empty
  /// - Contain only alphabetic characters and single spaces
  ///
  /// Returns an error message if validation fails, otherwise returns `null`.
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "name is required";
    }

    if (!nameRegex.hasMatch(value)) {
      return "Name can't include special characters";
    }

    return null;
  }

  /// Validates that the confirmation password matches the original password.
  ///
  /// Returns an error message if the value is null, empty, or does not match
  /// the [original] password. Otherwise returns `null`.
  static String? confirmPassword(String? value, String original) {
    if (value == null || value.trim().isEmpty) {
      return "Please confirm your password";
    }

    if (value.trim() != original.trim()) {
      return "Passwords do not match";
    }

    return null;
  }
}
