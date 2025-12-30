class Validators {
  static String? required(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? positiveNumber(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    final number = double.tryParse(value);
    if (number == null || number <= 0) {
      return '$fieldName must be a positive number';
    }
    return null;
  }

  static String? minLength(String? value, int minLength, {String fieldName = 'Field'}) {
    if (value == null || value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  static String? dateRange(DateTime? start, DateTime? end) {
    if (start != null && end != null && end.isBefore(start)) {
      return 'End date must be after start date';
    }
    return null;
  }

  static bool isValidEmail(String value) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(value);
  }

  static String? nonNegativeNumber(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    final number = double.tryParse(value);
    if (number == null || number < 0) {
      return '$fieldName must be zero or a positive number';
    }
    return null;
  }

  static String? percentage(String? value, {String fieldName = 'Percentage'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    final number = double.tryParse(value);
    if (number == null || number < 0 || number > 100) {
      return '$fieldName must be between 0 and 100';
    }
    return null;
  }

  static String? combine(List<String? Function()> validators) {
    for (var validator in validators) {
      final error = validator();
      if (error != null) return error;
    }
    return null;
  }
}
