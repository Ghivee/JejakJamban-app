class LogXpAward {
  const LogXpAward({required this.points, required this.eligible});

  final int points;
  final bool eligible;
}

LogXpAward calculateLogXp({
  required int alreadyAwardedToday,
  required bool completeLog,
  required int completedFields,
  required bool retroactive,
}) {
  if (alreadyAwardedToday >= 3) {
    return const LogXpAward(points: 0, eligible: false);
  }

  final points = completeLog && completedFields >= 4 ? 20 : 10;
  return LogXpAward(points: retroactive ? points ~/ 2 : points, eligible: true);
}

class StreakResult {
  const StreakResult({required this.days, required this.freezesUsed});

  final int days;
  final int freezesUsed;
}

StreakResult calculateStreak({
  required Iterable<DateTime> checkIns,
  required DateTime today,
  int freezesAvailable = 0,
}) {
  final checkedDays = checkIns.map(_dateOnly).toSet();
  final todayDate = _dateOnly(today);
  final checkedInToday = checkedDays.contains(todayDate);
  var cursor = checkedInToday
      ? todayDate
      : DateTime(todayDate.year, todayDate.month, todayDate.day - 1);
  var days = 0;
  var freezesUsed = 0;

  while (checkedDays.contains(cursor)) {
    days++;
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }

  final previousDay = DateTime(cursor.year, cursor.month, cursor.day - 1);
  if (freezesAvailable > 0 && checkedDays.contains(previousDay)) {
    freezesUsed = 1;
    cursor = previousDay;
    while (checkedDays.contains(cursor)) {
      days++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
  }

  return StreakResult(days: days, freezesUsed: freezesUsed);
}

int calculateStreakDays({
  required Iterable<DateTime> checkIns,
  required DateTime today,
}) {
  return calculateStreak(checkIns: checkIns, today: today).days;
}

class JejakScoreInput {
  const JejakScoreInput({
    required this.checkedInDays,
    required this.bristolTypes,
    required this.hydrationTargetDays,
    required this.fiberTargetDays,
    required this.completedMissions,
    required this.totalMissions,
    required this.communityContributions,
  });

  final int checkedInDays;
  final List<int> bristolTypes;
  final int hydrationTargetDays;
  final int fiberTargetDays;
  final int completedMissions;
  final int totalMissions;
  final int communityContributions;
}

int calculateJejakScore(JejakScoreInput input) {
  final consistency = (input.checkedInDays.clamp(0, 7) / 7 * 40).round();
  final qualifiedLogs = input.bristolTypes.length >= 3;
  final idealLogs = input.bristolTypes
      .where((type) => type == 3 || type == 4)
      .length;
  final quality = qualifiedLogs
      ? (idealLogs / input.bristolTypes.length * 20).round()
      : 0;
  final hydration = (input.hydrationTargetDays.clamp(0, 7) / 7 * 15).round();
  final fiber = (input.fiberTargetDays.clamp(0, 7) / 7 * 10).round();
  final missions = input.totalMissions <= 0
      ? 0
      : (input.completedMissions.clamp(0, input.totalMissions) /
                input.totalMissions *
                10)
            .round();
  final community = input.communityContributions.clamp(0, 5);

  return (consistency + quality + hydration + fiber + missions + community)
      .clamp(0, 100);
}

enum RedFlagKind {
  blood,
  blackStool,
  paleStool,
  severePain,
  persistentDiarrhea,
  persistentConstipation,
  patternChange,
}

class RedFlagInput {
  const RedFlagInput({
    required this.loggedAt,
    required this.bristolType,
    this.color,
    this.severePain = false,
  });

  final DateTime loggedAt;
  final int bristolType;
  final String? color;
  final bool severePain;
}

List<RedFlagKind> detectRedFlags(
  Iterable<RedFlagInput> observations, {
  int drasticPatternDays = 0,
}) {
  final items = observations.toList();
  final flags = <RedFlagKind>[];

  if (items.any((item) => item.color == 'red')) {
    flags.add(RedFlagKind.blood);
  }
  if (items.any((item) => item.color == 'black')) {
    flags.add(RedFlagKind.blackStool);
  }
  if (_distinctDays(items.where((item) => item.color == 'pale')) >= 2) {
    flags.add(RedFlagKind.paleStool);
  }
  if (items.any((item) => item.severePain)) {
    flags.add(RedFlagKind.severePain);
  }
  if (_hasConsecutiveDays(items, (type) => type >= 6, 3)) {
    flags.add(RedFlagKind.persistentDiarrhea);
  }
  if (_hasConsecutiveDays(items, (type) => type <= 2, 6)) {
    flags.add(RedFlagKind.persistentConstipation);
  }
  if (drasticPatternDays > 14) {
    flags.add(RedFlagKind.patternChange);
  }
  return flags;
}

bool _hasConsecutiveDays(
  List<RedFlagInput> items,
  bool Function(int type) matches,
  int requiredDays,
) {
  final days = items
      .where((item) => matches(item.bristolType))
      .map((item) => _dateOnly(item.loggedAt))
      .toSet();
  if (days.length < requiredDays) return false;

  for (final start in days) {
    var consecutive = 1;
    var cursor = DateTime(start.year, start.month, start.day + 1);
    while (days.contains(cursor)) {
      consecutive++;
      if (consecutive >= requiredDays) return true;
      cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
    }
  }
  return false;
}

int _distinctDays(Iterable<RedFlagInput> items) =>
    items.map((item) => _dateOnly(item.loggedAt)).toSet().length;

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
