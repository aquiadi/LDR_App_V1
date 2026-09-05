import 'package:flutter_test/flutter_test.dart';
import 'package:ldr_app/features/dashboard/providers/countdown_provider.dart';
import 'package:ldr_app/models/checkin_model.dart';
import 'package:ldr_app/models/couple_model.dart';
import 'package:ldr_app/models/user_model.dart';
import 'package:ldr_app/shared/mood_catalog.dart';

void main() {
  group('CheckinModel', () {
    test('parses a daily_checkins row', () {
      final model = CheckinModel.fromJson(const {
        'id': 'c1',
        'user_id': 'u1',
        'couple_id': 'p1',
        'mood_emoji': 'favorite',
        'mood_label': 'Loved',
        'affection_score': 9,
        'stress_score': 2,
        'energy_score': 7,
        'journal_note': 'Missing you.',
        'created_at': '2024-06-20T08:30:00Z',
        'shared_at': '2024-06-20T08:30:00Z',
      });
      expect(model.moodLabel, 'Loved');
      expect(model.energyScore, 7);
      expect(model.createdAt.toUtc().hour, 8);
    });

    test('tolerates a null journal note', () {
      final model = CheckinModel.fromJson(const {
        'id': 'c1', 'user_id': 'u1', 'couple_id': 'p1',
        'mood_emoji': 'cloud', 'mood_label': 'Gloomy',
        'affection_score': 5, 'stress_score': 5, 'energy_score': 5,
        'journal_note': null,
        'created_at': '2024-06-20T08:30:00Z',
        'shared_at': '2024-06-20T08:30:00Z',
      });
      expect(model.journalNote, isNull);
    });
  });

  group('CoupleModel', () {
    test('parses a solo couple that is still awaiting a partner', () {
      final couple = CoupleModel.fromJson(const {
        'id': 'p1',
        'created_at': '2024-06-01T00:00:00Z',
        'invite_code': 'ABCD1234',
        'partner_1_id': 'u1',
        'partner_2_id': null,
        'is_active': true,
        'space_name': 'Our Corner',
        'anniversary_date': '2022-03-14',
        'welcome_message': 'I made this for us',
        'cover_photo_url': null,
      });
      expect(couple.partner2Id, isNull);
      expect(couple.spaceName, 'Our Corner');
      // anniversary_date is a DATE column, not a timestamp.
      expect(couple.anniversaryDate, DateTime(2022, 3, 14));
    });

    test('round-trips through toJson', () {
      const json = {
        'id': 'p1',
        'created_at': '2024-06-01T00:00:00.000Z',
        'invite_code': 'ABCD1234',
        'partner_1_id': 'u1',
        'partner_2_id': 'u2',
        'is_active': true,
        'space_name': null,
        'anniversary_date': null,
        'welcome_message': null,
        'cover_photo_url': null,
      };
      final restored = CoupleModel.fromJson(Map<String, dynamic>.from(json));
      expect(restored.toJson()['invite_code'], 'ABCD1234');
      expect(restored.toJson()['partner_2_id'], 'u2');
    });
  });

  group('UserModel', () {
    test('parses a profile row including last_seen', () {
      final user = UserModel.fromJson(const {
        'id': 'u1',
        'created_at': '2024-06-01T00:00:00Z',
        'updated_at': '2024-06-02T00:00:00Z',
        'email': 'ada@example.com',
        'display_name': 'Ada',
        'avatar_url': null,
        'couple_id': 'p1',
        'fcm_token': null,
        'timezone': 'Europe/London',
        'premium_tier': false,
        'last_seen': '2024-06-20T10:00:00Z',
      });
      expect(user.displayName, 'Ada');
      expect(user.timezone, 'Europe/London');
      expect(user.lastSeen, isNotNull);
    });
  });

  group('CountdownEvent', () {
    // Regression: this used to read json['date'], a column that does not
    // exist. Every countdown fetch threw once a row was present.
    test('reads the target_date column', () {
      final event = CountdownEvent.fromJson(const {
        'id': 'e1',
        'title': 'Paris reunion',
        'description': 'Finally',
        'target_date': '2024-12-24T18:00:00Z',
      });
      expect(event.title, 'Paris reunion');
      expect(event.targetDate.toUtc().month, 12);
    });
  });

  group('mood catalog', () {
    test('every option resolves to its own icon', () {
      for (final mood in kMoodOptions) {
        expect(moodIconFor(mood.id), mood.icon, reason: mood.id);
      }
    });

    test('an unknown id falls back rather than throwing', () {
      expect(moodIconFor('something_from_an_older_build'), isNotNull);
    });

    test('ids are unique', () {
      final ids = kMoodOptions.map((m) => m.id).toSet();
      expect(ids.length, kMoodOptions.length);
    });
  });
}
