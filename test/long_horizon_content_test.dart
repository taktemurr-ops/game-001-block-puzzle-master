import 'package:flutter_test/flutter_test.dart';
import 'package:game_001_block_puzzle_master/game/long_horizon_content.dart';

void main() {
  final engine = LongHorizonContent();
  test('50,000 level descriptors are reproducible', () {
    for (var id = 1; id <= 50000; id++) {
      final first = engine.level(id);
      final again = engine.level(id);
      expect(first.seed, again.seed);
      expect(first.world, (id - 1) ~/ 100 + 1);
      expect(first.difficulty, inInclusiveRange(1, 5));
      expect(first.targetScore, greaterThan(0));
    }
  });
  test('daily plans are stable throughout the UTC day', () {
    final a = engine.dailyMissions(DateTime.utc(2026, 11, 19, 1));
    final b = engine.dailyMissions(DateTime.utc(2026, 11, 19, 23));
    expect(a.map((m) => m.id), b.map((m) => m.id));
    expect(a.map((m) => m.target), b.map((m) => m.target));
    expect(a.length, 3);
  });
  test('weekly mission key rolls over on Monday', () {
    expect(engine.weekKey(DateTime.utc(2026, 11, 16)),
        engine.weekKey(DateTime.utc(2026, 11, 22)));
    expect(engine.weekKey(DateTime.utc(2026, 11, 23)),
        isNot(engine.weekKey(DateTime.utc(2026, 11, 22))));
  });
  test('rejects invalid level numbers', () {
    expect(() => engine.level(0), throwsRangeError);
  });
}
