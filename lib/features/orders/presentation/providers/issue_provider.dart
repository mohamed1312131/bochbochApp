import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/issue_models.dart';
import 'order_provider.dart';

// ── Submit-issue state ─────────────────────────────────────
//
// Mirrors the exchange/submit pattern: 3-state Notifier
// (idle/loading/success/error) with sentinel-aware copyWith so a
// stale createdResult from a prior submit doesn't leak into a retry.

enum SubmitIssueStatus { idle, loading, success, error }

const Object _submitIssueUnchanged = Object();

class SubmitIssueState {
  const SubmitIssueState({
    this.status = SubmitIssueStatus.idle,
    this.error,
    this.createdResult,
  });

  final SubmitIssueStatus status;
  final String? error;
  final CreateIssueResult? createdResult;

  SubmitIssueState copyWith({
    SubmitIssueStatus? status,
    String? error,
    Object? createdResult = _submitIssueUnchanged,
  }) =>
      SubmitIssueState(
        status: status ?? this.status,
        error: error,
        createdResult: identical(createdResult, _submitIssueUnchanged)
            ? this.createdResult
            : createdResult as CreateIssueResult?,
      );
}

class SubmitIssueNotifier extends AutoDisposeNotifier<SubmitIssueState> {
  @override
  SubmitIssueState build() => const SubmitIssueState();

  Future<void> submit(IssueDraft draft) async {
    final type = draft.issueType;
    final res = draft.resolution;
    if (type == null || res == null) {
      state = state.copyWith(
        status: SubmitIssueStatus.error,
        error: 'Type ou résolution manquant.',
      );
      return;
    }

    state = state.copyWith(
      status: SubmitIssueStatus.loading,
      error: null,
      createdResult: null,
    );

    try {
      final result = await ref.read(orderRepositoryProvider).createIssue(
            orderId: draft.orderId,
            issueType: type,
            resolution: res,
            notes: draft.notes,
          );
      state = state.copyWith(
        status: SubmitIssueStatus.success,
        createdResult: result,
      );
    } catch (e) {
      state = state.copyWith(
        status: SubmitIssueStatus.error,
        error: e.toString(),
      );
    }
  }

  void reset() => state = const SubmitIssueState();
}

final submitIssueProvider =
    NotifierProvider.autoDispose<SubmitIssueNotifier, SubmitIssueState>(
  SubmitIssueNotifier.new,
);

final issuesForOrderProvider = FutureProvider.autoDispose
    .family<List<Issue>, String>((ref, orderId) async {
  return ref.read(orderRepositoryProvider).listIssues(orderId);
});
