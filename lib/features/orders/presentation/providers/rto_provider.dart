import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/rto_models.dart';
import 'order_provider.dart';

enum SubmitRtoStatus { idle, loading, success, error }

const Object _submitRtoUnchanged = Object();

class SubmitRtoState {
  const SubmitRtoState({
    this.status = SubmitRtoStatus.idle,
    this.error,
    this.createdResult,
  });

  final SubmitRtoStatus status;
  final String? error;
  final MarkRtoResult? createdResult;

  SubmitRtoState copyWith({
    SubmitRtoStatus? status,
    String? error,
    Object? createdResult = _submitRtoUnchanged,
  }) =>
      SubmitRtoState(
        status: status ?? this.status,
        error: error,
        createdResult: identical(createdResult, _submitRtoUnchanged)
            ? this.createdResult
            : createdResult as MarkRtoResult?,
      );
}

class SubmitRtoNotifier extends AutoDisposeNotifier<SubmitRtoState> {
  @override
  SubmitRtoState build() => const SubmitRtoState();

  Future<void> submit({
    required String orderId,
    required RtoReason reason,
    required RtoTargetStatus targetStatus,
  }) async {
    state = state.copyWith(
      status: SubmitRtoStatus.loading,
      error: null,
      createdResult: null,
    );
    try {
      final result = await ref.read(orderRepositoryProvider).markRto(
            orderId: orderId,
            reason: reason,
            status: targetStatus,
          );
      state = state.copyWith(
        status: SubmitRtoStatus.success,
        createdResult: result,
      );
    } catch (e) {
      state = state.copyWith(
        status: SubmitRtoStatus.error,
        error: e.toString(),
      );
    }
  }

  void reset() => state = const SubmitRtoState();
}

final submitRtoProvider =
    NotifierProvider.autoDispose<SubmitRtoNotifier, SubmitRtoState>(
  SubmitRtoNotifier.new,
);
