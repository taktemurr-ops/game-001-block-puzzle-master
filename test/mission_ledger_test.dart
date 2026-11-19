import 'package:flutter_test/flutter_test.dart';
import 'package:game_001_block_puzzle_master/game/mission_ledger.dart';

void main() {
  test('day rollover preserves weekly counters', () {
    final m = MissionLedger(day:'2026-11-19',week:'2026-11-16');
    m.record(DateTime.utc(2026,11,19),placed:3,lines:2,score:30);
    m.record(DateTime.utc(2026,11,20),placed:1,lines:1,score:20);
    expect(m.dailyPieces,1);
    expect(m.weeklyPieces,4);
    m.tick(DateTime.utc(2026,11,23));
    expect(m.weeklyPieces,0);
  });
  test('save and load preserve counters', () {
    final now = DateTime.utc(2026,11,19);
    final m = MissionLedger(day:MissionLedger.dayKey(now),week:MissionLedger.weekKey(now));
    m.record(now,placed:2,lines:1,score:44);
    final copy = MissionLedger.fromJson(m.toJson(),now);
    expect(copy.dailyPieces,2);
    expect(copy.weeklyScore,44);
  });
  test('invalid saved counters are rejected', () {
    expect(() => MissionLedger.fromJson({'day':'invalid','week':'invalid'},DateTime.utc(2026,11,19)),throwsFormatException);
  });
}
