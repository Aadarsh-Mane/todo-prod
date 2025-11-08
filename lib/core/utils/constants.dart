const String kDatabaseName = 'task_manager.db';
const int kDatabaseVersion = 1; // Increment for migrations

// Enums as strings for DB storage
const List<String> kPriorities = ['low', 'medium', 'high'];
const List<String> kStatuses = ['todo', 'in-progress', 'done'];

// Validation
const String kTitleRequiredError = 'Title is required';
const String kDueDateFutureError = 'Due date cannot be in the past';
final RegExp kTitlePattern = RegExp(r'^.{1,100}$'); // 1-100 chars

// UX
const Duration kDueSoonThreshold =
    Duration(hours: 48); // For "due soon" section
const String kDefaultListName = 'Inbox';
