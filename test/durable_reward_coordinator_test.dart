import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_001_block_puzzle_master/monetization/durable_reward_coordinator.dart';

class _Backend implements RewardSettlementBackend {
  _Backend(this.handler);
  final Future<bool> Function(String transactionId) handler;
  int calls = 0;

  @override
  Future<bool> verifyAndGrant({
    required String accountId,
    required String placementId,
    required String transactionId,
  }) {
    calls++;
    return handler(transactionId);
  }
}

void main() {
  test('no consent or completion callback never reaches backend', () async {
    final backend = _Backend((_) async => true);
    final coordinator = DurableRewardCoordinator(backend);
    Future<bool> claim(bool optIn, bool completed) => coordinator.claim(
      accountId: 'a', placementId: 'hint', transactionId: 'tx',
      userOptedIn: optIn, completedCallbackReceived: completed);
    expect(await claim(false, true), isFalse);
    expect(await claim(true, false), isFalse);
    expect(backend.calls, 0);
  });

  test('backend rejection does not grant reward', () async {
    final coordinator = DurableRewardCoordinator(_Backend((_) async => false));
    expect(await coordinator.claim(accountId: 'a', placementId: 'hint',
      transactionId: 'tx', userOptedIn: true,
      completedCallbackReceived: true), isFalse);
  });

  test('simultaneous claims for a transaction only invoke backend once', () async {
    final pending = Completer<bool>();
    final backend = _Backend((_) => pending.future);
    final coordinator = DurableRewardCoordinator(backend);
    Future<bool> claim() => coordinator.claim(accountId: 'a',
      placementId: 'hint', transactionId: 'tx', userOptedIn: true,
      completedCallbackReceived: true);
    final first = claim();
    expect(await claim(), isFalse);
    pending.complete(true);
    expect(await first, isTrue);
    expect(backend.calls, 1);
  });

  test('network errors fail closed', () async {
    final coordinator = DurableRewardCoordinator(
      _Backend((_) async => throw StateError('network')));
    expect(await coordinator.claim(accountId: 'a', placementId: 'hint',
      transactionId: 'tx', userOptedIn: true,
      completedCallbackReceived: true), isFalse);
  });
}
