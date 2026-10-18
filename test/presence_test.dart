import 'package:flutter_test/flutter_test.dart';
import 'package:ldr_app/features/dashboard/providers/presence_provider.dart';

void main() {
  group('utcOffsetLabel', () {
    test('zero offset is plain UTC', () {
      expect(utcOffsetLabel(Duration.zero), 'UTC');
    });

    test('positive offsets keep minutes', () {
      expect(utcOffsetLabel(const Duration(hours: 5, minutes: 30)), 'UTC+05:30');
    });

    test('negative offsets', () {
      expect(utcOffsetLabel(const Duration(hours: -7)), 'UTC-07:00');
      expect(utcOffsetLabel(const Duration(hours: -3, minutes: -30)), 'UTC-03:30');
    });
  });
}
