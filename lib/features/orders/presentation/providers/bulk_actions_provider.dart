import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/bulk_action_models.dart';
import 'order_provider.dart';

enum BulkActionStatus { idle, loading, success, error }

const Object _bulkUnchanged = Object();

class BulkActionsState {
  const BulkActionsState({
    this.status = BulkActionStatus.idle,
    this.error,
    this.result,
  });

  final BulkActionStatus status;
  final String? error;
  final BulkActionResult? result;

  BulkActionsState copyWith({
    BulkActionStatus? status,
    String? error,
    Object? result = _bulkUnchanged,
  }) =>
      BulkActionsState(
        status: status ?? this.status,
        error: error,
        result: identical(result, _bulkUnchanged)
            ? this.result
            : result as BulkActionResult?,
      );
}

class BulkActionsNotifier extends AutoDisposeNotifier<BulkActionsState> {
  @override
  BulkActionsState build() => const BulkActionsState();

  Future<BulkActionResult?> bulkUpdateStatus({
    required List<String> orderIds,
    required String newStatus,
  }) async {
    return _run(() => ref
        .read(orderRepositoryProvider)
        .bulkUpdateStatus(orderIds: orderIds, newStatus: newStatus));
  }

  Future<BulkActionResult?> bulkCancel({
    required List<String> orderIds,
  }) async {
    return _run(() =>
        ref.read(orderRepositoryProvider).bulkCancel(orderIds: orderIds));
  }

  Future<BulkActionResult?> _run(
    Future<BulkActionResult> Function() op,
  ) async {
    state = state.copyWith(
      status: BulkActionStatus.loading,
      error: null,
      result: null,
    );
    try {
      final result = await op();
      state = state.copyWith(
        status: BulkActionStatus.success,
        result: result,
      );
      return result;
    } catch (e) {
      state = state.copyWith(
        status: BulkActionStatus.error,
        error: e.toString(),
      );
      return null;
    }
  }

  void reset() => state = const BulkActionsState();
}

final bulkActionsProvider =
    NotifierProvider.autoDispose<BulkActionsNotifier, BulkActionsState>(
  BulkActionsNotifier.new,
);
