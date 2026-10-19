import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/paginated_response.dart';
import '../../data/mock_stock_repository.dart';
import '../../data/real_stock_repository.dart';
import '../../data/stock_repository.dart';
import '../../domain/stock_inputs.dart';
import '../../domain/stock_models.dart';
import '../../domain/stock_movement.dart';

/// Feature flag controlling whether stock module uses the real
/// backend repository or the in-memory mock.
///
/// Defaults to true (mock) until chunk 10-D ships and the dual-write
/// gap is closed. The real repo reads on_hand_quantity from the
/// backend, which only reflects restock/adjust mutations — order-
/// driven changes still update the stock_quantity legacy column
/// until 10-D wires the orders module to write stock_movements.
///
/// Mock repo is opt-in only — defaults to false so production builds
/// do NOT ship the in-memory mock catalog (Sac cuir noir, Salma /
/// Yasmine / Amira customer names, etc.) to real users (C5).
///
/// To use the mock repo locally:
///   flutter run --dart-define=USE_MOCK_STOCK=true
const bool kUseMockStock = bool.fromEnvironment(
  'USE_MOCK_STOCK',
  defaultValue: false,
);

// ── Repository ────────────────────────────────────────────────
final stockRepositoryProvider = Provider<StockRepository>((ref) {
  if (kUseMockStock) {
    return MockStockRepository();
  }
  return RealStockRepository(ref);
});

// ── Stock state per variant ───────────────────────────────────
// NOT autoDispose: mutations elsewhere (restock / adjust) call
// `ref.invalidate(stockStateProvider(variantId))` to push fresh data,
// but with autoDispose the provider gets disposed between sheet opens
// and the invalidation has no live listener — the next open then
// rebuilds and (correctly) re-reads from the repo, but the in-memory
// repo mutation is still there. Keeping the provider alive lets
// invalidation actually surface the new value to any listener that
// resubscribes.
final stockStateProvider =
    FutureProvider.family<StockState, String>((ref, variantId) async {
  return ref.watch(stockRepositoryProvider).getStockState(variantId);
});

// ── Movements per variant (with filter) ───────────────────────
class MovementsQuery {
  const MovementsQuery({required this.variantId, this.filter});
  final String variantId;
  final StockHistoryFilter? filter;

  @override
  bool operator ==(Object other) =>
      other is MovementsQuery &&
      other.variantId == variantId &&
      other.filter == filter;

  @override
  int get hashCode => Object.hash(variantId, filter);
}

// NOT autoDispose: mutations elsewhere call
// `ref.invalidate(stockMovementsProvider)` to push fresh data, but with
// autoDispose the provider gets disposed between screens and the
// invalidation has no live listener.
final stockMovementsProvider = FutureProvider.family<
    PaginatedResponse<StockMovement>, MovementsQuery>((ref, query) async {
  return ref.watch(stockRepositoryProvider).getMovements(
        variantId: query.variantId,
        filter: query.filter,
      );
});

// ── Reports ───────────────────────────────────────────────────
final stockValueProvider =
    FutureProvider.autoDispose<StockValueReport>((ref) {
  return ref.watch(stockRepositoryProvider).getStockValue();
});

final deadStockProvider =
    FutureProvider.autoDispose<List<DeadStockEntry>>((ref) {
  return ref.watch(stockRepositoryProvider).getDeadStock();
});

final lowStockProvider =
    FutureProvider.autoDispose<List<LowStockEntry>>((ref) {
  return ref.watch(stockRepositoryProvider).getLowStockVariants();
});

final shrinkageProvider =
    FutureProvider.autoDispose<ShrinkageBreakdown>((ref) {
  return ref.watch(stockRepositoryProvider).getShrinkage();
});

final offSaleOutflowProvider =
    FutureProvider.autoDispose<OffSaleOutflowBreakdown>((ref) {
  return ref.watch(stockRepositoryProvider).getOffSaleOutflow();
});

final bestSellersProvider =
    FutureProvider.autoDispose<List<BestSellerEntry>>((ref) {
  return ref.watch(stockRepositoryProvider).getBestSellers();
});

final slowMoversProvider =
    FutureProvider.autoDispose<List<SlowMoverEntry>>((ref) {
  return ref.watch(stockRepositoryProvider).getSlowMovers();
});

// ── Categories ────────────────────────────────────────────────
final categoriesProvider =
    FutureProvider.autoDispose<List<Category>>((ref) {
  return ref.watch(stockRepositoryProvider).getCategories();
});

// ── Settings ──────────────────────────────────────────────────
final stockSettingsProvider =
    FutureProvider.autoDispose<BoutiqueStockSettings>((ref) {
  return ref.watch(stockRepositoryProvider).getStockSettings();
});

// ── Mutation notifiers ────────────────────────────────────────
class RestockController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<StockMovement> submit(RestockInput input) async {
    state = const AsyncValue.loading();
    try {
      final mv = await ref.read(stockRepositoryProvider).restock(input);
      state = const AsyncValue.data(null);
      ref.invalidate(stockStateProvider(input.variantId));
      ref.invalidate(stockMovementsProvider);
      ref.invalidate(lowStockProvider);
      return mv;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final restockControllerProvider =
    AutoDisposeAsyncNotifierProvider<RestockController, void>(
  RestockController.new,
);

class AdjustmentController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<StockMovement> submit(AdjustmentInput input) async {
    state = const AsyncValue.loading();
    try {
      final mv = await ref.read(stockRepositoryProvider).adjust(input);
      state = const AsyncValue.data(null);
      ref.invalidate(stockStateProvider(input.variantId));
      ref.invalidate(stockMovementsProvider);
      ref.invalidate(lowStockProvider);
      return mv;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final adjustmentControllerProvider =
    AutoDisposeAsyncNotifierProvider<AdjustmentController, void>(
  AdjustmentController.new,
);
