import '../../../shared/models/paginated_response.dart';
import '../domain/stock_inputs.dart';
import '../domain/stock_models.dart';
import '../domain/stock_movement.dart';

abstract class StockRepository {
  // ── Movements ───────────────────────────────────────────────
  Future<PaginatedResponse<StockMovement>> getMovements({
    required String variantId,
    StockHistoryFilter? filter,
    String? cursor,
    int limit = 50,
  });

  // ── Stock state ─────────────────────────────────────────────
  Future<StockState> getStockState(String variantId);

  // ── Mutations ───────────────────────────────────────────────
  Future<StockMovement> restock(RestockInput input);
  Future<StockMovement> adjust(AdjustmentInput input);
  Future<String> uploadAdjustmentPhoto(String filePath);

  // ── Reports ─────────────────────────────────────────────────
  Future<StockValueReport> getStockValue();
  Future<List<DeadStockEntry>> getDeadStock({int? dormantDays});
  Future<ShrinkageBreakdown> getShrinkage({DateTime? from, DateTime? to});
  Future<OffSaleOutflowBreakdown> getOffSaleOutflow(
      {DateTime? from, DateTime? to});
  Future<List<BestSellerEntry>> getBestSellers(
      {DateTime? from, DateTime? to, int limit = 5});
  Future<List<SlowMoverEntry>> getSlowMovers(
      {DateTime? from, DateTime? to, int limit = 5});
  Future<List<StockMovement>> getLowStockMovements();
  Future<List<LowStockEntry>> getLowStockVariants();

  // ── Categories ──────────────────────────────────────────────
  Future<List<Category>> getCategories();
  Future<Category> createCategory(CategoryInput input);
  Future<Category> updateCategory(String id, CategoryInput input);
  Future<void> deleteCategory(String id, {String? moveProductsToId});

  // ── Stock settings ──────────────────────────────────────────
  Future<BoutiqueStockSettings> getStockSettings();
  Future<BoutiqueStockSettings> updateStockSettings(
      BoutiqueStockSettings settings);

  // ── Bundles ─────────────────────────────────────────────────
  Future<StockBundle> getBundle(String productId);
  Future<StockBundle> upsertBundle(
      String productId, List<BundleComponent> components);
}
