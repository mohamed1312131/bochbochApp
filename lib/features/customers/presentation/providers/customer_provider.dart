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

final customerDetailProvider =
    FutureProvider.autoDispose.family<CustomerDetail, String>((ref, id) async {
  return ref.read(customerRepositoryProvider).getCustomer(id);
});
