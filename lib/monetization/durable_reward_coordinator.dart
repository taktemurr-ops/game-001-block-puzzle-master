/// Production reward claims must be settled atomically on a trusted server.
/// A successful ad callback alone is not proof of a valid reward.
/// This interface deliberately contains no mock advertising or payment SDK.
abstract class RewardSettlementBackend {
  /// Verify ad network server-to-server proof and atomically reserve a unique
  /// transaction. Return true only when the reward was durably granted once.
  Future<bool> verifyAndGrant({
    required String accountId,
    required String placementId,
    required String transactionId,
  });
}

/// Client-side fail-closed coordinator. The backend is the source of truth:
/// it must reject reused transactions across devices, users and placements.
class DurableRewardCoordinator {
  DurableRewardCoordinator(this.backend);

  final RewardSettlementBackend backend;
  final Set<String> _inFlight = <String>{};

  Future<bool> claim({
    required String accountId,
    required String placementId,
    required String transactionId,
    required bool userOptedIn,
    required bool completedCallbackReceived,
  }) async {
    if (!userOptedIn || !completedCallbackReceived ||
        accountId.trim().isEmpty || placementId.trim().isEmpty ||
        transactionId.trim().isEmpty) {
      return false;
    }
    final key = transactionId.trim();
    if (!_inFlight.add(key)) return false;
    try {
      return await backend.verifyAndGrant(
        accountId: accountId.trim(),
        placementId: placementId.trim(),
        transactionId: key,
      );
    } catch (_) {
      return false;
    } finally {
      _inFlight.remove(key);
    }
  }
}
