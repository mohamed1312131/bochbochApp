import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/partial_fulfill_models.dart';
import 'order_provider.dart';

enum SubmitPartialFulfillStatus { idle, loading, success, error }

const Object _partialFulfillUnchanged = Object();

class SubmitPartialFulfillState {
  const SubmitPartialFulfillState({
    this.status = SubmitPartialFulfillStatus.idle,
    this.error,
    this.result,
  });

  final SubmitPartialFulfillStatus status;
  final String? error;
  final PartialFulfillResult? result;

  SubmitPartialFulfillState copyWith({
    SubmitPartialFulfillStatus? status,
    String? error,
    Object? result = _partialFulfillUnchanged,
  }) =>
      SubmitPartialFulfillState(
        status: status ?? this.status,
        error: error,
        result: identical(result, _partialFulfillUnchanged)
            ? this.result
            : result as PartialFulfillResult?,
      );
}

class SubmitPartialFulfillNotifier
    extends AutoDisposeNotifier<SubmitPartialFulfillState> {
  @override
  SubmitPartialFulfillState build() => const SubmitPartialFulfillState();

  Future<void> submit({
    required String orderId,
    required PartialFulfillAction action,
    DateTime? estimatedRestockDate,
  }) async {
    state = state.copyWith(
      status: SubmitPartialFulfillStatus.loading,
      error: null,
      result: null,
    );
    try {
      final result = await ref.read(orderRepositoryProvider).partialFulfill(
            orderId: orderId,
            action: action,
            estimatedRestockDate: estimatedRestockDate,
          );
      state = state.copyWith(
        status: SubmitPartialFulfillStatus.success,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        status: SubmitPartialFulfillStatus.error,
        error: e.toString(),
      );
    }
  }

  void reset() => state = const SubmitPartialFulfillState();
}

final submitPartialFulfillProvider = NotifierProvider.autoDispose<
    SubmitPartialFulfillNotifier, SubmitPartialFulfillState>(
  SubmitPartialFulfillNotifier.new,
);
