import 'package:flutter_test/flutter_test.dart';
import 'package:todo/core/utils/constants.dart';
import 'package:todo/core/utils/validators.dart';

void main() {
  group('Validators - edge cases', () {
    test('title returns error when empty', () {
      expect(Validators.title(''), kTitleRequiredError);
      expect(Validators.title(null), kTitleRequiredError);
      expect(Validators.title('   '), kTitleRequiredError);
    });

    test('title returns error when too long', () {
      final longTitle = 'a' * 101;
      expect(Validators.title(longTitle), 'Title must be 1-100 characters');
    });

    test('title accepts valid input', () {
      expect(Validators.title('Valid title'), null);
      expect(Validators.title('a' * 100), null);
    });

    test('dueDate returns error when in the past', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      expect(Validators.dueDate(past), isNotNull);
      expect(Validators.dueDate(past), kDueDateFutureError);
    });

    test('dueDate allows today and future', () {
      expect(Validators.dueDate(DateTime.now()), null);
      expect(Validators.dueDate(DateTime.now().add(const Duration(days: 1))),
          null);
    });

    test('priority rejects invalid values', () {
      expect(Validators.priority('invalid'), 'Invalid priority');
      expect(Validators.priority(null), 'Invalid priority');
    });

    test('priority accepts valid values', () {
      for (final p in kPriorities) {
        expect(Validators.priority(p), null);
      }
    });

    test('status rejects invalid values', () {
      expect(Validators.status('invalid'), 'Invalid status');
      expect(Validators.status(null), 'Invalid status');
    });

    test('status accepts valid values', () {
      for (final s in kStatuses) {
        expect(Validators.status(s), null);
      }
    });

    test('tagName enforces length and required', () {
      expect(Validators.tagName(''), 'Tag name required');
      expect(Validators.tagName('a' * 21), 'Tag too long (max 20 chars)');
      expect(Validators.tagName('good'), null);
    });
  });
}
