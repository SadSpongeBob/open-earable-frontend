class Validators {
  static final emailRegex = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  static final whiteSpaceRegex = RegExp(r'\s+');

  static final nameRegex = RegExp(r'^[A-Za-z]+(?: [A-Za-z]+)*$');

  /// Basic "not empty" validation
  static String? notEmpty(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "This field cannot be empty";
    }
    return null;
  }

  /// Email validation
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Email is required";
    }

    if (!emailRegex.hasMatch(value.trim())) {
      return "Enter a valid email address";
    }

    return null;
  }

  /// Password validation
  static String? password(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Password is required";
    }

    if (whiteSpaceRegex.hasMatch(value)) {
      return "Password can't contain spaces";
    }

    if (value.length < 8) {
      return "Password must be at least 6 characters";
    }

    if (value.length > 30) {
      return "Password length should not exceed 30 characters";
    }

    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "name is required";
    }

    if (!nameRegex.hasMatch(value)) {
      return "Name can't include special characters";
    }

    return null;
  }

  /// confirm password validator
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
