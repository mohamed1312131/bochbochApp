import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/product_repository.dart';
import '../../domain/product_models.dart';

// ── Repository ─────────────────────────────────────────────
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

// ── Product List ───────────────────────────────────────────
final productListProvider =
    AsyncNotifierProvider.autoDispose<ProductListNotifier, List<ProductLean>>(
  ProductListNotifier.new,
);

class ProductListNotifier extends AutoDisposeAsyncNotifier<List<ProductLean>> {
  String? _nextCursor;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  Future<List<ProductLean>> build() async {
    _nextCursor = null;
    _hasMore = true;
    return _fetch();
  }

  Future<List<ProductLean>> _fetch({String? cursor}) async {
    final repo = ref.read(productRepositoryProvider);
    final result = await repo.getProducts(cursor: cursor);
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
      // Don't replace state on load more error — keep existing data
    } finally {
      _isLoadingMore = false;
    }
  }

  // Optimistic add after create
  void addProduct(ProductLean product) {
    final current = state.valueOrNull ?? [];
    state = AsyncData([product, ...current]);
  }

  // Optimistic remove after delete
  void removeProduct(String productId) {
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((p) => p.id != productId).toList());
  }
}

// ── Single Product Detail ──────────────────────────────────
final productDetailProvider =
    FutureProvider.autoDispose.family<Product, String>((ref, id) async {
  return ref.read(productRepositoryProvider).getProduct(id);
});

// ── Add Product State ──────────────────────────────────────
enum AddProductStatus { idle, loading, success, error }

class AddProductState {
  const AddProductState({
    this.status = AddProductStatus.idle,
    this.error,
    this.createdProduct,
  });

  final AddProductStatus status;
  final String? error;
  final Product? createdProduct;

  AddProductState copyWith({
    AddProductStatus? status,
    String? error,
    Product? createdProduct,
  }) =>
      AddProductState(
        status: status ?? this.status,
        error: error,
        createdProduct: createdProduct ?? this.createdProduct,
      );
}

class AddProductNotifier extends AutoDisposeNotifier<AddProductState> {
  @override
  AddProductState build() => const AddProductState();

  Future<void> createProduct({
    required String name,
    required int baseCostPrice,
    required int baseSellPrice,
    required int initialStock,
    String? description,
    String? category,
    String? imagePath,
  }) async {
    state = state.copyWith(status: AddProductStatus.loading, error: null);

    try {
      final repo = ref.read(productRepositoryProvider);

      // 1. Create product
      final product = await repo.createProduct(
        name: name,
        baseCostPrice: baseCostPrice,
        baseSellPrice: baseSellPrice,
        initialStock: initialStock,
        description: description,
        category: category,
      );

      // 2. Upload + attach image if provided
      if (imagePath != null) {
        try {
          final imageData = await repo.uploadImage(imagePath);
          await repo.attachImage(
            product.id,
            cloudinaryPublicId: imageData['cloudinaryPublicId']!,
            url: imageData['url']!,
            isPrimary: true,
            altText: name,
          );
        } catch (_) {
          // Image upload failure is non-fatal
          // Product was created successfully
        }
      }

      state = state.copyWith(
        status: AddProductStatus.success,
        createdProduct: product,
      );
    } catch (e) {
      state = state.copyWith(
        status: AddProductStatus.error,
        error: e.toString(),
      );
    }
  }

  void reset() => state = const AddProductState();
}

final addProductProvider =
    NotifierProvider.autoDispose<AddProductNotifier, AddProductState>(
  AddProductNotifier.new,
);