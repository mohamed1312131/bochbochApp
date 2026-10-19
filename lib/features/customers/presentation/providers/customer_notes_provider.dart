import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/customer_note_models.dart';
import 'customer_provider.dart';

/// Owns the in-flight list of notes for one customer.
/// Mutations apply optimistically and roll back on failure so the
/// caller can surface a snackbar via the rethrown exception.
final customerNotesProvider = AsyncNotifierProvider.autoDispose
    .family<CustomerNotesNotifier, List<CustomerNote>, String>(
  CustomerNotesNotifier.new,
);

class CustomerNotesNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<CustomerNote>, String> {
  String get customerId => arg;

  @override
  Future<List<CustomerNote>> build(String customerId) {
    return ref.read(customerRepositoryProvider).listNotes(customerId);
  }

  /// Sort pinned-first, then by createdAt DESC. Mirrors the backend's
  /// ORDER BY so the optimistic state matches what a re-fetch would
  /// return.
  List<CustomerNote> _sorted(Iterable<CustomerNote> notes) {
    final out = [...notes];
    out.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return out;
  }

  /// Create a new note. If `isPinned`, the previously pinned note (if
  /// any) is unpinned in the optimistic snapshot — matching the
  /// server's single-pin invariant.
  Future<void> create({
    required String content,
    bool isPinned = false,
  }) async {
    final current = state.valueOrNull ?? const <CustomerNote>[];

    final now = DateTime.now();
    final optimistic = CustomerNote(
      id: 'pending-${now.microsecondsSinceEpoch}',
      customerId: customerId,
      content: content,
      isPinned: isPinned,
      createdAt: now,
      updatedAt: now,
    );
    final next = [
      ...current.map(
        (n) => isPinned && n.isPinned ? n.copyWith(isPinned: false) : n,
      ),
      optimistic,
    ];
    state = AsyncData(_sorted(next));

    try {
      final created =
          await ref.read(customerRepositoryProvider).createNote(
                customerId: customerId,
                content: content,
                isPinned: isPinned,
              );
      // Swap the optimistic placeholder for the real row.
      final replaced = (state.valueOrNull ?? const <CustomerNote>[])
          .map((n) => n.id == optimistic.id ? created : n)
          .toList();
      state = AsyncData(_sorted(replaced));
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }

  /// Update content and/or pin status. At least one must be non-null.
  /// Pinning unpins any other pinned note optimistically.
  /// Named `edit` (not `update`) because the base class reserves
  /// `update` for the AsyncNotifier state-update API.
  Future<void> edit(
    String noteId, {
    String? content,
    bool? isPinned,
  }) async {
    final current = state.valueOrNull ?? const <CustomerNote>[];

    final next = current.map((n) {
      if (n.id == noteId) {
        return n.copyWith(
          content: content,
          isPinned: isPinned,
          updatedAt: DateTime.now(),
        );
      }
      // Single-pin: when pinning a different note, unpin the others.
      if (isPinned == true && n.isPinned) {
        return n.copyWith(isPinned: false);
      }
      return n;
    }).toList();
    state = AsyncData(_sorted(next));

    try {
      final fresh = await ref.read(customerRepositoryProvider).updateNote(
            customerId: customerId,
            noteId: noteId,
            content: content,
            isPinned: isPinned,
          );
      final merged = (state.valueOrNull ?? const <CustomerNote>[])
          .map((n) => n.id == noteId ? fresh : n)
          .toList();
      state = AsyncData(_sorted(merged));
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> delete(String noteId) async {
    final current = state.valueOrNull ?? const <CustomerNote>[];
    state =
        AsyncData(current.where((n) => n.id != noteId).toList());

    try {
      await ref.read(customerRepositoryProvider).deleteNote(
            customerId: customerId,
            noteId: noteId,
          );
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }
}
