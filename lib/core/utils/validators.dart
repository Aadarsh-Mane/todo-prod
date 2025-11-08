import 'constants.dart';

class Validators {
  static String? title(String? value) {
    if (value == null || value.trim().isEmpty) {
      return kTitleRequiredError;
    }
    if (!kTitlePattern.hasMatch(value.trim())) {
      return 'Title must be 1-100 characters';
    }
    return null;
  }

  static String? description(String? value) {
    // Optional, but limit length
    if (value != null && value.length > 1000) {
      return 'Description too long (max 1000 chars)';
    }
    return null;
  }

  static String? dueDate(DateTime? date) {
    if (date == null) return null; // Optional
    if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return kDueDateFutureError;
    }
    return null;
  }

  static String? priority(String? value) {
    if (value == null || !kPriorities.contains(value)) {
      return 'Invalid priority';
    }
    return null;
  }

  static String? status(String? value) {
    if (value == null || !kStatuses.contains(value)) {
      return 'Invalid status';
    }
    return null;
  }

  static String? tagName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tag name required';
    }
    if (value.trim().length > 20) {
      return 'Tag too long (max 20 chars)';
    }
    return null;
  }

  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
