import '../../../shared/models/paginated_response.dart';
import '../domain/stock_enums.dart';
import '../domain/stock_inputs.dart';
import '../domain/stock_models.dart';
import '../domain/stock_movement.dart';
import 'mock_data.dart';
import 'stock_repository.dart';

/// In-memory mock implementation of [StockRepository].
/// Mock latency: 300ms via Future.delayed to simulate network.
class MockStockRepository implements StockRepository {
  static const _latency = Duration(milliseconds: 300);

  final Map<String, StockState> _stockStates =
      Map.from(StockMockData.stockStatesByVariant);
  final List<StockMovement> _movements =
      List.from(StockMockData.allMovements);
  final List<Category> _categories = List.from(StockMockData.categories);
  BoutiqueStockSettings _settings = StockMockData.defaultSettings;

  /// Per-product bundle persistence so add-product → edit-product
  /// round-trip works against the mock. Keyed by productId. The
  /// chunk 2 sample bundle (`prod_pack_saint_valentin`) is served
  /// from `StockMockData.sampleBundle` when this map has no entry.
  final Map<String, List<BundleComponent>> _bundleComponents = {};

  int _computeBundleAvailability(List<BundleComponent> components) {
    if (components.isEmpty) return 0;
    var minAvail = 1 << 30;
    for (final comp in components) {
      final state = _stockStates[comp.componentVariantId];
      final hasReal = state != null &&
          (state.onHand > 0 ||
              state.committedOrders.isNotEmpty ||
              state.backordered > 0);
      final available = hasReal ? state.available : 0;
      final per = comp.qtyPerBundle == 0 ? 1 : comp.qtyPerBundle;
      final candidate = available ~/ per;
      if (candidate < minAvail) minAvail = candidate;
    }
    return minAvail < (1 << 30) ? minAvail : 0;
  }

  @override
  Future<PaginatedResponse<StockMovement>> getMovements({
    required String variantId,
    StockHistoryFilter? filter,
    String? cursor,
    int limit = 50,
  }) async {
    await Future.delayed(_latency);
    var filtered =
        _movements.where((m) => m.variantId == variantId).toList();
    if (filter != null) {
      if (filter.types != null && filter.types!.isNotEmpty) {
        filtered =
            filtered.where((m) => filter.types!.contains(m.type)).toList();
      }
      if (filter.reasons != null && filter.reasons!.isNotEmpty) {
        filtered = filtered
            .where((m) =>
                m.reasonCode != null &&
                filter.reasons!.contains(m.reasonCode))
            .toList();
      }
      if (filter.fromDate != null) {
        filtered = filtered
            .where((m) => !m.createdAt.isBefore(filter.fromDate!))
            .toList();
      }
      if (filter.toDate != null) {
        filtered = filtered
            .where((m) => !m.createdAt.isAfter(filter.toDate!))
            .toList();
      }
    }
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final page = filtered.take(limit).toList();
    return PaginatedResponse<StockMovement>(
      data: page,
      hasMore: false,
      nextCursor: null,
    );
  }

  @override
  Future<StockState> getStockState(String variantId) async {
    await Future.delayed(_latency);
    return _stockStates[variantId] ??
        StockState(
          variantId: variantId,
          onHand: 0,
          available: 0,
          committed: 0,
          backordered: 0,
          committedOrders: const [],
        );
  }

  @override
  Future<StockMovement> restock(RestockInput input) async {
    await Future.delayed(_latency);
    final current = _stockStates[input.variantId]!;
    _stockStates[input.variantId] = StockState(
      variantId: input.variantId,
      onHand: current.onHand + input.quantity,
      available: current.available + input.quantity,
      committed: current.committed,
      backordered: current.backordered,
      committedOrders: current.committedOrders,
    );
    final movement = StockMovement(
      id: 'mov_${DateTime.now().millisecondsSinceEpoch}',
      productId: 'prod_unknown',
      variantId: input.variantId,
      type: StockMovementType.restock,
      qtyDelta: input.quantity,
      qtyBefore: current.onHand,
      qtyAfter: current.onHand + input.quantity,
      unitCostAtTime: input.unitCost,
      referenceType: StockReferenceType.restock,
      referenceLabel: input.supplierName != null
          ? '${input.supplierName} · ${input.unitCost ~/ 1000} TND/u'
          : '${input.unitCost ~/ 1000} TND/u',
      notes: input.notes,
      idempotencyKey: input.idempotencyKey,
      createdAt: DateTime.now(),
    );
    _movements.insert(0, movement);
    return movement;
  }

  @override
  Future<StockMovement> adjust(AdjustmentInput input) async {
    await Future.delayed(_latency);
    final current = _stockStates[input.variantId]!;
    final qtyDelta = input.newOnHandQuantity - current.onHand;
    final newOnHand = input.newOnHandQuantity;
    final newAvailable = (current.available + qtyDelta).clamp(0, 1 << 30);
    _stockStates[input.variantId] = StockState(
      variantId: input.variantId,
      onHand: newOnHand,
      available: newAvailable,
      committed: current.committed,
      backordered: current.backordered,
      committedOrders: current.committedOrders,
    );
    final type = switch (input.reason) {
      StockAdjustmentReason.damage => StockMovementType.damage,
      StockAdjustmentReason.theft => StockMovementType.theft,
      StockAdjustmentReason.recount => StockMovementType.recount,
      StockAdjustmentReason.lost => StockMovementType.adjustment,
      StockAdjustmentReason.marketingGift => StockMovementType.marketingGift,
      StockAdjustmentReason.personalUse => StockMovementType.personalUse,
      StockAdjustmentReason.sample => StockMovementType.sample,
      StockAdjustmentReason.other => StockMovementType.adjustment,
    };
    final movement = StockMovement(
      id: 'mov_${DateTime.now().millisecondsSinceEpoch}',
      productId: 'prod_unknown',
      variantId: input.variantId,
      type: type,
      reasonCode: input.reason,
      qtyDelta: qtyDelta,
      qtyBefore: current.onHand,
      qtyAfter: newOnHand,
      unitCostAtTime: 0,
      referenceType: StockReferenceType.manualAdjustment,
      referenceLabel: input.reason.label,
      notes: input.notes,
      photoUrl: input.photoUrl,
      idempotencyKey: input.idempotencyKey,
      createdAt: DateTime.now(),
    );
    _movements.insert(0, movement);
    return movement;
  }

  @override
  Future<String> uploadAdjustmentPhoto(String filePath) async {
    await Future.delayed(_latency);
    return 'https://mock-cdn.dido.local/adjustments/${DateTime.now().millisecondsSinceEpoch}.jpg';
  }

  @override
  Future<StockValueReport> getStockValue() async {
    await Future.delayed(_latency);
    return StockMockData.stockValueReport;
  }

  @override
  Future<List<DeadStockEntry>> getDeadStock({int? dormantDays}) async {
    await Future.delayed(_latency);
    return StockMockData.deadStock;
  }

  @override
  Future<ShrinkageBreakdown> getShrinkage(
      {DateTime? from, DateTime? to}) async {
    await Future.delayed(_latency);
    return StockMockData.shrinkage;
  }

  @override
  Future<OffSaleOutflowBreakdown> getOffSaleOutflow(
      {DateTime? from, DateTime? to}) async {
    await Future.delayed(_latency);
    return StockMockData.offSaleOutflow;
  }

  @override
  Future<List<BestSellerEntry>> getBestSellers(
      {DateTime? from, DateTime? to, int limit = 5}) async {
    await Future.delayed(_latency);
    return StockMockData.bestSellers.take(limit).toList();
  }

  @override
  Future<List<SlowMoverEntry>> getSlowMovers(
      {DateTime? from, DateTime? to, int limit = 5}) async {
    await Future.delayed(_latency);
    return StockMockData.slowMovers.take(limit).toList();
  }

  @override
  Future<List<StockMovement>> getLowStockMovements() async {
    await Future.delayed(_latency);
    return _movements.take(5).toList();
  }

  @override
  Future<List<LowStockEntry>> getLowStockVariants() async {
    await Future.delayed(_latency);
    final threshold = _settings.defaultLowStockThreshold;
    final entries = <LowStockEntry>[
      // Trousse maquillage — derived from real mutable state.
      if ((_stockStates['var_trousse_maquillage_std']?.available ??
              0) <=
          threshold)
        LowStockEntry(
          productId: 'prod_trousse_maquillage',
          productName: 'Trousse maquillage',
          variantId: 'var_trousse_maquillage_std',
          variantLabel: 'Std',
          sku: 'TRS-STD',
          currentAvailable:
              _stockStates['var_trousse_maquillage_std']!.available,
          threshold: threshold,
          thumbnailColor: 0xFFC9B59E,
          currentWacMillimes: 35000,
        ),
      // Fictional entries to make the list interesting.
      LowStockEntry(
        productId: 'prod_sac_plage_paillette',
        productName: 'Sac plage paillette',
        variantId: 'var_sac_plage_paillette_uniq',
        variantLabel: 'Uniq',
        sku: 'SPP-UNI',
        currentAvailable: 1,
        threshold: threshold,
        thumbnailColor: 0xFFD4AF37,
        currentWacMillimes: 12000,
      ),
      LowStockEntry(
        productId: 'prod_foulard_soie_le',
        productName: 'Foulard soie limited edition',
        variantId: 'var_foulard_soie_le_uniq',
        variantLabel: 'Uniq',
        sku: 'FSL-UNI',
        currentAvailable: 2,
        threshold: threshold,
        thumbnailColor: 0xFF9B6B4A,
        currentWacMillimes: 28000,
      ),
    ];
    return entries;
  }

  @override
  Future<List<Category>> getCategories() async {
    await Future.delayed(_latency);
    return List.from(_categories);
  }

  @override
  Future<Category> createCategory(CategoryInput input) async {
    await Future.delayed(_latency);
    final cat = Category(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: input.name,
      productCount: 0,
    );
    _categories.add(cat);
    return cat;
  }

  @override
  Future<Category> updateCategory(String id, CategoryInput input) async {
    await Future.delayed(_latency);
    final idx = _categories.indexWhere((c) => c.id == id);
    if (idx < 0) throw StateError('Category not found: $id');
    final updated = Category(
      id: id,
      name: input.name,
      productCount: _categories[idx].productCount,
    );
    _categories[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteCategory(String id, {String? moveProductsToId}) async {
    await Future.delayed(_latency);
    _categories.removeWhere((c) => c.id == id);
  }

  @override
  Future<BoutiqueStockSettings> getStockSettings() async {
    await Future.delayed(_latency);
    return _settings;
  }

  @override
  Future<BoutiqueStockSettings> updateStockSettings(
      BoutiqueStockSettings settings) async {
    await Future.delayed(_latency);
    _settings = settings;
    return _settings;
  }

  @override
  Future<StockBundle> getBundle(String productId) async {
    await Future.delayed(_latency);
    final upserted = _bundleComponents[productId];
    if (upserted != null) {
      return StockBundle(
        bundleProductId: productId,
        components: List.unmodifiable(upserted),
        computedAvailability: _computeBundleAvailability(upserted),
      );
    }
    if (productId == StockMockData.sampleBundle.bundleProductId) {
      return StockMockData.sampleBundle;
    }
    return StockBundle(
      bundleProductId: productId,
      components: const [],
      computedAvailability: 0,
    );
  }

  @override
  Future<StockBundle> upsertBundle(
      String productId, List<BundleComponent> components) async {
    await Future.delayed(_latency);
    _bundleComponents[productId] = List.from(components);
    return StockBundle(
      bundleProductId: productId,
      components: List.unmodifiable(components),
      computedAvailability: _computeBundleAvailability(components),
    );
  }
}
