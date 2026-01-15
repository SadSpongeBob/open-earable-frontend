class Validators {
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

    const emailRegex =
        r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$';

    if (!RegExp(emailRegex).hasMatch(value.trim())) {
      return "Enter a valid email address";
    }

    return null;
  }

  /// Password validation
  static String? password(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Password is required";
    }

    if (value.length < 6) {
      return "Password must be at least 6 characters";
    }

    return null;
  }
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "name is required";
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