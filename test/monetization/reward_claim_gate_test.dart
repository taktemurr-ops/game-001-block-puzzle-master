import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_001_block_puzzle_master/monetization/reward_claim_gate.dart';

class _Verifier implements RewardReceiptVerifier {
  _Verifier(this.result);
  final Future<bool> Function() result;
  int calls = 0;

  @override
  Future<bool> verify({
    required String accountId,
    required String placementId,
    required String receiptId,
  }) {
    calls++;
    return result();
  }
}

void main() {
  test('opt-in is required and no verification occurs otherwise', () async {
    final verifier = _Verifier(() async => true);
    final gate = RewardClaimGate(verifier);
    expect(await gate.claim(accountId: 'a', placementId: 'hint',
        receiptId: 'r1', userOptedIn: false), isFalse);
    expect(verifier.calls, 0);
  });

  test('failed verification does not grant reward; retry can succeed', () async {
    var approved = false;
    final gate = RewardClaimGate(_Verifier(() async => approved));
    Future<bool> claim() => gate.claim(accountId: 'a',
        placementId: 'hint', receiptId: 'r1', userOptedIn: true);
    expect(await claim(), isFalse);
    approved = true;
    expect(await claim(), isTrue);
    expect(await claim(), isFalse);
  });

  test('concurrent claims for one receipt cannot both succeed', () async {
    final completer = Completer<bool>();
    final verifier = _Verifier(() => completer.future);
    final gate = RewardClaimGate(verifier);
    Future<bool> claim() => gate.claim(accountId: 'a',
        placementId: 'hint', receiptId: 'r1', userOptedIn: true);
    final first = claim();
    expect(await claim(), isFalse);
    completer.complete(true);
    expect(await first, isTrue);
    expect(verifier.calls, 1);
  });

  test('verifier errors fail closed and do not grant reward', () async {
    final gate = RewardClaimGate(_Verifier(() async => throw StateError('offline')));
    expect(await gate.claim(accountId: 'a', placementId: 'hint',
        receiptId: 'r1', userOptedIn: true), isFalse);
  });

  test('empty identifiers are rejected before verification', () async {
    final verifier = _Verifier(() async => true);
    final gate = RewardClaimGate(verifier);
    expect(await gate.claim(accountId: ' ', placementId: 'hint',
        receiptId: 'r1', userOptedIn: true), isFalse);
    expect(verifier.calls, 0);
  });
}
