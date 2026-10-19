import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/customer_repository.dart';
import '../../domain/customer_models.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});

final customerListProvider =
    AsyncNotifierProvider.autoDispose<CustomerListNotifier, List<CustomerLean>>(
  CustomerListNotifier.new,
);

class CustomerListNotifier
    extends AutoDisposeAsyncNotifier<List<CustomerLean>> {
  String? _nextCursor;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  Future<List<CustomerLean>> build() async {
    _nextCursor = null;
    _hasMore = true;
    return _fetch();
  }

  Future<List<CustomerLean>> _fetch({String? cursor}) async {
    final repo = ref.read(customerRepositoryProvider);
    final result = await repo.getCustomers(cursor: cursor);
    _nextCursor = result.nextCursor;
    _hasMore = result.hasMore;
    return result.data;
  }

  Future<void> refresh() async {
    _nextCursor = null;
    _hasMore = true;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || _nextCursor == null) return;
    _isLoadingMore = true;
    final current = state.valueOrNull ?? [];
    try {
      final more = await _fetch(cursor: _nextCursor);
      state = AsyncData([...current, ...more]);
    } catch (_) {
    } finally {
      _isLoadingMore = false;
    }
  }
}

// Owns the in-flight CustomerDetail for one customerId. Exposes
// setToggles() for optimistic block/prepayment updates with rollback.
final customerDetailProvider = AsyncNotifierProvider.autoDispose
    .family<CustomerDetailNotifier, CustomerDetail, String>(
  CustomerDetailNotifier.new,
);

class CustomerDetailNotifier
    extends AutoDisposeFamilyAsyncNotifier<CustomerDetail, String> {
  @override
  Future<CustomerDetail> build(String customerId) {
    return ref.read(customerRepositoryProvider).getCustomer(customerId);
  }

  /// Optimistically apply the toggle change and POST in the background.
  /// On failure, restores the prior state and rethrows so the caller
  /// can surface a snackbar.
  ///
  /// `blockReason: null` is meaningful — explicitly clears the column.
  /// To leave reason untouched, omit the parameter (use [unchangedReason]).
  Future<void> setToggles({
    bool? isBlocked,
    Object? blockReason = unchangedReason,
    bool? requirePrepayment,
    bool? codEnabled,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // Build the optimistic snapshot. When unblocking, mirror the
    // backend by clearing blockReason + blockedAt locally too — the
    // server response will overwrite if the timing differs.
    CustomerDetail optimistic;
    if (isBlocked == false) {
      optimistic = current.copyWith(
        isBlocked: false,
        blockReason: null,
        blockedAt: null,
        requirePrepayment: requirePrepayment,
        codEnabled: codEnabled,
      );
    } else {
      optimistic = current.copyWith(
        isBlocked: isBlocked,
        blockReason: identical(blockReason, unchangedReason)
            ? null  // means: don't change (sentinel passed through)
            : blockReason as String?,
        // First-block timestamp stamped optimistically (backend will
        // re-stamp atomically; this just gives the UI a value to render).
        blockedAt: isBlocked == true && !current.isBlocked
            ? DateTime.now()
            : null,
        requirePrepayment: requirePrepayment,
        codEnabled: codEnabled,
      );
    }

    state = AsyncData(optimistic);

    try {
      final fresh =
          await ref.read(customerRepositoryProvider).updateToggles(
                customerId,
                isBlocked: isBlocked,
                blockReason: identical(blockReason, unchangedReason)
                    ? null
                    : blockReason as String?,
                requirePrepayment: requirePrepayment,
                codEnabled: codEnabled,
              );
      state = AsyncData(fresh);
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }

  /// Optimistic profile edit (birthday + channel + tags). On failure
  /// restores prior state + rethrows.
  ///
  /// To clear birthday, pass `clearBirthday: true`. `tags` is REPLACE
  /// semantics — pass [] to clear all.
  Future<void> setProfile({
    DateTime? birthday,
    bool clearBirthday = false,
    ContactChannel? preferredContactChannel,
    List<String>? tags,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final optimistic = current.copyWith(
      birthday: clearBirthday ? null : (birthday ?? current.birthday),
      preferredContactChannel: preferredContactChannel,
      tags: tags,
    );
    state = AsyncData(optimistic);

    try {
      final fresh =
          await ref.read(customerRepositoryProvider).updateProfile(
                customerId,
                birthday: birthday,
                clearBirthday: clearBirthday,
                preferredContactChannel: preferredContactChannel,
                tags: tags,
              );
      state = AsyncData(fresh);
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }

  /// Optimistic risk update. riskUpdatedAt stamped client-side as a
  /// preview; the server-truth response overwrites with the real
  /// value (which only re-stamps if the level OR reason actually
  /// changed — the optimistic stamp can over-shoot in idempotent
  /// cases, gets corrected on response).
  Future<void> setRisk({
    required RiskLevel riskLevel,
    String? riskReason,
    bool clearReason = false,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final levelChanged = current.riskLevel != riskLevel;
    final newReason =
        clearReason ? null : (riskReason ?? current.riskReason);
    final reasonChanged = current.riskReason != newReason;

    final optimistic = current.copyWith(
      riskLevel: riskLevel,
      riskReason: clearReason ? null : riskReason,
      riskUpdatedAt: (levelChanged || reasonChanged)
          ? DateTime.now()
          : current.riskUpdatedAt,
    );
    state = AsyncData(optimistic);

    try {
      final fresh =
          await ref.read(customerRepositoryProvider).updateRisk(
                customerId,
                riskLevel: riskLevel,
                riskReason: riskReason,
                clearReason: clearReason,
              );
      state = AsyncData(fresh);
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }

  String get customerId => arg;
}

/// Sentinel for [CustomerDetailNotifier.setToggles] — distinguishes
/// "don't change reason" from "explicitly clear reason."
const Object unchangedReason = Object();
