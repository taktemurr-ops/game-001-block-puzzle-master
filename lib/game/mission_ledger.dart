/// Local-only mission progress. Use server verification for valuable rewards.
class MissionLedger {
  String day;
  String week;
  int dailyPieces;
  int dailyLines;
  int dailyScore;
  int weeklyPieces;
  int weeklyLines;
  int weeklyScore;

  MissionLedger({required this.day, required this.week,
    this.dailyPieces = 0, this.dailyLines = 0, this.dailyScore = 0,
    this.weeklyPieces = 0, this.weeklyLines = 0, this.weeklyScore = 0});

  static String dayKey(DateTime value) {
    final d = value.toUtc();
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static String weekKey(DateTime value) {
    final utc = value.toUtc();
    final day = DateTime.utc(utc.year, utc.month, utc.day);
    return dayKey(day.subtract(Duration(days: day.weekday - 1)));
  }

  void tick(DateTime now) {
    final newDay = dayKey(now);
    final newWeek = weekKey(now);
    if (newWeek != week) {
      week = newWeek;
      weeklyPieces = 0;
      weeklyLines = 0;
      weeklyScore = 0;
    }
    if (newDay != day) {
      day = newDay;
      dailyPieces = 0;
      dailyLines = 0;
      dailyScore = 0;
    }
  }

  void record(DateTime now, {required int placed, required int lines, required int score}) {
    if (placed < 0 || lines < 0 || score < 0) throw ArgumentError('Negative progress');
    tick(now);
    dailyPieces += placed; dailyLines += lines; dailyScore += score;
    weeklyPieces += placed; weeklyLines += lines; weeklyScore += score;
  }

  int dailyValue(String metric) {
    switch (metric) {
      case 'pieces': return dailyPieces;
      case 'lines': return dailyLines;
      case 'score': return dailyScore;
      default: return 0;
    }
  }

  Map<String, Object> toJson() => {
    'day': day, 'week': week,
    'daily_pieces': dailyPieces, 'daily_lines': dailyLines, 'daily_score': dailyScore,
    'weekly_pieces': weeklyPieces, 'weekly_lines': weeklyLines, 'weekly_score': weeklyScore,
  };

  factory MissionLedger.fromJson(Map<String, dynamic> json, DateTime now) {
    int getInt(String key) {
      final x = json[key];
      if (x is! int || x < 0 || x > 1000000000) throw FormatException('Invalid $key');
      return x;
    }
    final d = json['day'], w = json['week'];
    if (d is! String || w is! String || d.length != 10 || w.length != 10) {
      throw const FormatException('Invalid calendar');
    }
    return MissionLedger(day:d, week:w,
      dailyPieces:getInt('daily_pieces'), dailyLines:getInt('daily_lines'),
      dailyScore:getInt('daily_score'),weeklyPieces:getInt('weekly_pieces'),
      weeklyLines:getInt('weekly_lines'),weeklyScore:getInt('weekly_score'))..tick(now);
  }
}
