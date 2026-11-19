/// Offline, deterministic content descriptors. The generated metadata is
/// NOT proof that the board is solvable: add a solver before release.
class LevelPlan {
  final int level;
  final int seed;
  final int difficulty;
  final int world;
  final int targetScore;
  final int version;
  const LevelPlan(this.level, this.seed, this.difficulty, this.world, this.targetScore, this.version);
}

class MissionPlan {
  final String id;
  final String metric;
  final int target;
  final int reward;
  const MissionPlan(this.id, this.metric, this.target, this.reward);
}

class LongHorizonContent {
  static const int version = 1;
  static int _mix(int value) {
    var x = value & 0x7fffffff;
    x = ((x ^ (x >> 16)) * 0x45d9f3b) & 0x7fffffff;
    x = ((x ^ (x >> 16)) * 0x45d9f3b) & 0x7fffffff;
    return (x ^ (x >> 16)) & 0x7fffffff;
  }

  LevelPlan level(int number) {
    if (number < 1) throw RangeError.value(number, 'number');
    final difficulty = 1 + ((number - 1) ~/ 10000).clamp(0, 4);
    final world = (number - 1) ~/ 100 + 1;
    final target = 50 + difficulty * 25 + ((number - 1) ~/ 10) * 2;
    return LevelPlan(number, _mix(number ^ 1001 ^ (version * 1000003)),
        difficulty, world, target, version);
  }

  DateTime _day(DateTime time) {
    final utc = time.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }

  String dayKey(DateTime time) {
    final day = _day(time);
    return '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
  }

  List<MissionPlan> dailyMissions(DateTime time) {
    final key = dayKey(time);
    final day = _day(time).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    final x = _mix(day ^ 1001);
    return [
      MissionPlan('$key-placed', 'placed', 8 + x % 8, 20),
      MissionPlan('$key-lines', 'lines', 2 + x % 4, 30),
      MissionPlan('$key-score', 'score', 100 + x % 5 * 50, 25),
    ];
  }

  String weekKey(DateTime time) {
    final day = _day(time);
    return dayKey(day.subtract(Duration(days: day.weekday - 1)));
  }

  List<MissionPlan> weeklyMissions(DateTime time) {
    final key = weekKey(time);
    return [
      MissionPlan('$key-week-placed', 'placed', 200, 100),
      MissionPlan('$key-week-lines', 'lines', 50, 150),
      MissionPlan('$key-week-score', 'score', 5000, 200),
    ];
  }
}
