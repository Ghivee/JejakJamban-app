import 'package:flutter_test/flutter_test.dart';
import 'package:jejak_jamban/core/domain/health_rules.dart';

void main() {
  group('log XP rules', () {
    test('caps rewarded logs at three each day', () {
      final award = calculateLogXp(
        alreadyAwardedToday: 3,
        completeLog: true,
        completedFields: 8,
        retroactive: false,
      );

      expect(award.points, 0);
      expect(award.eligible, isFalse);
    });

    test('awards complete log points and halves retroactive awards', () {
      expect(
        calculateLogXp(
          alreadyAwardedToday: 0,
          completeLog: true,
          completedFields: 4,
          retroactive: false,
        ).points,
        20,
      );
      expect(
        calculateLogXp(
          alreadyAwardedToday: 0,
          completeLog: true,
          completedFields: 4,
          retroactive: true,
        ).points,
        10,
      );
    });
  });

  group('streak rules', () {
    final today = DateTime(2026, 10, 7);

    test('counts consecutive check-ins including today', () {
      final streak = calculateStreak(
        today: today,
        checkIns: [
          today,
          today.subtract(const Duration(days: 1)),
          today.subtract(const Duration(days: 2)),
        ],
      );

      expect(streak.days, 3);
      expect(streak.freezesUsed, 0);
    });

    test('a streak freeze bridges one missed day without awarding a day', () {
      final streak = calculateStreak(
        today: today,
        freezesAvailable: 1,
        checkIns: [
          today,
          today.subtract(const Duration(days: 1)),
          today.subtract(const Duration(days: 3)),
        ],
      );

      expect(streak.days, 3);
      expect(streak.freezesUsed, 1);
    });
  });

  group('Skor Jejak', () {
    test('clamps the score to the 0–100 range', () {
      final perfect = JejakScoreInput(
        checkedInDays: 7,
        bristolTypes: [3, 4, 3],
        hydrationTargetDays: 7,
        fiberTargetDays: 7,
        completedMissions: 3,
        totalMissions: 3,
        communityContributions: 5,
      );
      final overLimit = JejakScoreInput(
        checkedInDays: 12,
        bristolTypes: [3, 4, 3],
        hydrationTargetDays: 10,
        fiberTargetDays: 9,
        completedMissions: 9,
        totalMissions: 3,
        communityContributions: 99,
      );

      expect(calculateJejakScore(perfect), 100);
      expect(calculateJejakScore(overLimit), 100);
    });

    test('does not score Bristol quality with fewer than three logs', () {
      final score = calculateJejakScore(
        const JejakScoreInput(
          checkedInDays: 0,
          bristolTypes: [4, 4],
          hydrationTargetDays: 0,
          fiberTargetDays: 0,
          completedMissions: 0,
          totalMissions: 3,
          communityContributions: 0,
        ),
      );

      expect(score, 0);
    });
  });

  group('informational red flags', () {
    test('flags blood immediately without diagnosing', () {
      final flags = detectRedFlags([
        RedFlagInput(
          loggedAt: DateTime(2026, 10, 7),
          bristolType: 4,
          color: 'red',
        ),
      ]);

      expect(flags, contains(RedFlagKind.blood));
    });

    test('requires more than two days of loose stools', () {
      final twoDays = detectRedFlags([
        RedFlagInput(loggedAt: DateTime(2026, 10, 7), bristolType: 7),
        RedFlagInput(loggedAt: DateTime(2026, 10, 6), bristolType: 6),
      ]);
      final threeDays = detectRedFlags([
        RedFlagInput(loggedAt: DateTime(2026, 10, 7), bristolType: 7),
        RedFlagInput(loggedAt: DateTime(2026, 10, 6), bristolType: 6),
        RedFlagInput(loggedAt: DateTime(2026, 10, 5), bristolType: 7),
      ]);

      expect(twoDays, isNot(contains(RedFlagKind.persistentDiarrhea)));
      expect(threeDays, contains(RedFlagKind.persistentDiarrhea));
    });
  });
}
