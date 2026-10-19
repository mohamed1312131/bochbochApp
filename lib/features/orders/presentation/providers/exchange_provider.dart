import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/exchange_models.dart';
import 'order_provider.dart';

// ── Submit-exchange state ──────────────────────────────────
//
// Owns the in-flight POST. The 3-screen picker → costs → confirm
// flow passes the draft via Navigator constructor args; this notifier
// is consumed only on the confirm screen and reset before navigating
// away. autoDispose so the state is wiped if the user backs out.

enum SubmitExchangeStatus { idle, loading, success, error }

// Sentinel pattern (mirrors AddOrderState in order_provider.dart) so
// copyWith can distinguish "field not passed" from "explicitly null."
// Without this, a stale createdResult from a prior submit would leak
// through to a retry that sets status: loading but doesn't clear it.
const Object _submitExchangeUnchanged = Object();

class SubmitExchangeState {
  const SubmitExchangeState({
    this.status = SubmitExchangeStatus.idle,
    this.error,
    this.createdResult,
  });

  final SubmitExchangeStatus status;
  final String? error;
  final CreateExchangeResult? createdResult;

  SubmitExchangeState copyWith({
    SubmitExchangeStatus? status,
    String? error,
    Object? createdResult = _submitExchangeUnchanged,
  }) =>
      SubmitExchangeState(
        status: status ?? this.status,
        error: error,
        createdResult: identical(createdResult, _submitExchangeUnchanged)
            ? this.createdResult
            : createdResult as CreateExchangeResult?,
      );
}

class SubmitExchangeNotifier
    extends AutoDisposeNotifier<SubmitExchangeState> {
  @override
  SubmitExchangeState build() => const SubmitExchangeState();

  Future<void> submit(ExchangeDraft draft) async {
    final target = draft.target;
    if (target == null) {
      state = state.copyWith(
        status: SubmitExchangeStatus.error,
        error: 'Aucun article sélectionné.',
      );
      return;
    }

    // Clear any stale createdResult from a prior submit — see
    // sentinel comment above.
    state = state.copyWith(
      status: SubmitExchangeStatus.loading,
      error: null,
      createdResult: null,
    );

    try {
      final result = await ref.read(orderRepositoryProvider).createExchange(
            orderId: draft.orderId,
            // originalVariantId omitted in v1 — Flutter OrderItem
            // doesn't surface variantId. See ExchangeOriginalSnapshot.
            newProductId: target.productId,
            newVariantId: target.variantId,
            returnShippingCost: draft.returnShippingCost,
            redeliveryCost: draft.redeliveryCost,
            priceDifference: draft.priceDifference,
            notes: draft.notes,
          );
      state = state.copyWith(
        status: SubmitExchangeStatus.success,
        createdResult: result,
      );
    } catch (e) {
      state = state.copyWith(
        status: SubmitExchangeStatus.error,
        error: e.toString(),
      );
    }
  }

  void reset() => state = const SubmitExchangeState();
}

final submitExchangeProvider = NotifierProvider.autoDispose<
    SubmitExchangeNotifier, SubmitExchangeState>(
  SubmitExchangeNotifier.new,
);

// ── List of exchanges for an order (for future profit-panel reuse) ──
final exchangesForOrderProvider = FutureProvider.autoDispose
    .family<List<Exchange>, String>((ref, orderId) async {
  return ref.read(orderRepositoryProvider).listExchanges(orderId);
});
