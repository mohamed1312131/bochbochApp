import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/order_repository.dart';
import '../../domain/order_models.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

// ── Order Detail ───────────────────────────────────────────
// Public so other features (exchange confirm, return flow, etc.) can
// invalidate after a mutation that should refresh the visible order.
final orderDetailProvider =
    FutureProvider.autoDispose.family<Order, String>((ref, id) async {
  return ref.read(orderRepositoryProvider).getOrder(id);
});

// ── Order List ─────────────────────────────────────────────
final orderListProvider =
    AsyncNotifierProvider.autoDispose<OrderListNotifier, List<OrderLean>>(
  OrderListNotifier.new,
);

class OrderListNotifier extends AutoDisposeAsyncNotifier<List<OrderLean>> {
  String? _nextCursor;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  Future<List<OrderLean>> build() async {
    _nextCursor = null;
    _hasMore = true;
    return _fetch();
  }

  Future<List<OrderLean>> _fetch({String? cursor, String? status}) async {
    final repo = ref.read(orderRepositoryProvider);
    final result = await repo.getOrders(cursor: cursor, status: status);
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
    if (!_hasMore || _isLoadingMore) return;
    if (_nextCursor == null) return;
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

  void addOrder(OrderLean order) {
    final current = state.valueOrNull ?? [];
    state = AsyncData([order, ...current]);
  }

  void removeOrder(String orderId) {
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((o) => o.id != orderId).toList());
  }
}

// ── Add Order State ────────────────────────────────────────
enum AddOrderStatus { idle, loading, success, error }

// Sentinel so copyWith can distinguish "not passed" from "explicitly
// null". Without this, `createdOrder ?? this.createdOrder` made it
// impossible to clear a stale order from a previous submit (H11) — the
// next failed submit would still see the old `createdOrder` set.
const Object _addOrderUnchanged = Object();

class AddOrderState {
  const AddOrderState({
    this.status = AddOrderStatus.idle,
    this.error,
    this.createdOrder,
  });

  final AddOrderStatus status;
  final String? error;
  final Order? createdOrder;

  AddOrderState copyWith({
    AddOrderStatus? status,
    String? error,
    Object? createdOrder = _addOrderUnchanged,
  }) =>
      AddOrderState(
        status: status ?? this.status,
        error: error,
        createdOrder: identical(createdOrder, _addOrderUnchanged)
            ? this.createdOrder
            : createdOrder as Order?,
      );
}

class AddOrderNotifier extends AutoDisposeNotifier<AddOrderState> {
  @override
  AddOrderState build() => const AddOrderState();

  Future<void> createOrder({
    required String customerName,
    required String customerPhone,
    required List<OrderItemInput> items,
    int shippingCost = 0,
    int discountAmount = 0,
    int adSpend = 0,
    String? notes,
  }) async {
    // Clear any stale createdOrder from a prior submit so failed
    // submissions don't leak the previous successful order through the
    // success listener.
    state = state.copyWith(
      status: AddOrderStatus.loading,
      error: null,
      createdOrder: null,
    );
    try {
      final order = await ref.read(orderRepositoryProvider).createOrder(
            customerName: customerName,
            customerPhone: customerPhone,
            items: items,
            shippingCost: shippingCost,
            discountAmount: discountAmount,
            adSpend: adSpend,
            notes: notes,
          );
      state = state.copyWith(
        status: AddOrderStatus.success,
        createdOrder: order,
      );
    } catch (e) {
      state = state.copyWith(
        status: AddOrderStatus.error,
        error: e.toString(),
      );
    }
  }

  void reset() => state = const AddOrderState();
}

final addOrderProvider =
    NotifierProvider.autoDispose<AddOrderNotifier, AddOrderState>(
  AddOrderNotifier.new,
);