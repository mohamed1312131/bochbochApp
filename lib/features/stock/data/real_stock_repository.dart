import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/errors/error_handler.dart';
import '../../../shared/models/paginated_response.dart';
import '../../boutiques/presentation/boutique_providers.dart';
import '../domain/stock_enums.dart';
import '../domain/stock_inputs.dart';
import '../domain/stock_models.dart';
import '../domain/stock_movement.dart';
import 'stock_repository.dart';

/// Real Dio-backed implementation of [StockRepository].
///
/// Cross-cutting behavior:
/// - boutiqueId is read once via [currentBoutiqueProvider] and cached.
///   All boutique-scoped requests embed it in the URL and the
///   `X-Boutique-Id` header. Switching boutique invalidates this
///   provider, which reconstructs the repo (Riverpod handles teardown).
/// - The shared `DioClient` singleton is used; the AuthInterceptor
///   attaches the bearer token automatically.
/// - Backend error messages are already in French — surface
///   `e.response?.data['message']` directly via [ErrorHandler.handle]
///   (no client-side translation).
/// - `input.idempotencyKey` is forwarded as-is on restock/adjust;
///   the repo never regenerates it.
class RealStockRepository implements StockRepository {
  RealStockRepository(this._ref);

  final Ref _ref;

  Dio? _dio;
  String? _boutiqueId;

  Future<Dio> _getDio() async {
    return _dio ??= (await DioClient.getInstance()).dio;
  }

  Future<String> _getBoutiqueId() async {
    return _boutiqueId ??=
        (await _ref.read(currentBoutiqueProvider.future)).id;
  }

  Future<Options> _options() async {
    final boutiqueId = await _getBoutiqueId();
    return Options(headers: {'X-Boutique-Id': boutiqueId});
  }

  // ── Mappers ──────────────────────────────────────────────────────

  StockState _mapStockState(Map<String, dynamic> json) => StockState(
        variantId: json['variantId'] as String,
        onHand: json['onHandQuantity'] as int,
        available: json['availableQuantity'] as int,
        committed: json['committedQuantity'] as int,
        backordered: json['backorderedQuantity'] as int? ?? 0,
        backorderEnabled: json['backorderEnabled'] as bool? ?? false,
        currentAvgCostMillimes: json['currentAvgCostMillimes'] as int?,
        // TODO(chunk 11): committedOrders breakdown not in /stock-state
        // response. Add lazy-load via
        // GET /variants/:id/committed-orders when the user expands the
        // RÉSERVÉ row in stock_state_sheet.
        committedOrders: const [],
      );

  StockMovement _mapMovement(Map<String, dynamic> json) {
    final reasonRaw = json['reasonCode'] as String?;
    final reason = reasonRaw == null
        ? null
        : StockAdjustmentReason.fromApi(reasonRaw);
    return StockMovement(
      id: json['id'] as String,
      productId: json['productId'] as String,
      variantId: json['variantId'] as String,
      type: StockMovementType.fromApi(json['type'] as String),
      reasonCode: reason,
      qtyDelta: json['quantityChange'] as int,
      qtyBefore: json['stockBefore'] as int,
      qtyAfter: json['stockAfter'] as int,
      unitCostAtTime: json['costPerUnitMillimes'] as int? ?? 0,
      referenceType: StockReferenceType.fromApi(
        json['referenceType'] as String? ?? 'MANUAL_ADJUSTMENT',
      ),
      referenceId: json['referenceId'] as String?,
      referenceLabel: reason?.label,
      actorUserId: json['createdByUserId'] as String?,
      photoUrl: json['photoUrl'] as String?,
      notes: json['notes'] as String?,
      idempotencyKey: json['idempotencyKey'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // ── Movements ────────────────────────────────────────────────────

  @override
  Future<PaginatedResponse<StockMovement>> getMovements({
    required String variantId,
    StockHistoryFilter? filter,
    String? cursor,
    int limit = 50,
  }) async {
    try {
      final dio = await _getDio();
      final qp = <String, dynamic>{
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
        if (filter?.types != null && filter!.types!.isNotEmpty)
          'types': filter.types!.map((t) => t.apiValue).join(','),
        if (filter?.reasons != null && filter!.reasons!.isNotEmpty)
          'reasonCodes': filter.reasons!.map((r) => r.apiValue).join(','),
        if (filter?.fromDate != null)
          'from': filter!.fromDate!.toUtc().toIso8601String(),
        if (filter?.toDate != null)
          'to': filter!.toDate!.toUtc().toIso8601String(),
      };
      final response = await dio.get(
        '/variants/$variantId/movements',
        queryParameters: qp,
        options: await _options(),
      );
      final body = response.data as Map<String, dynamic>;
      final list = (body['data'] as List<dynamic>)
          .map((e) => _mapMovement(e as Map<String, dynamic>))
          .toList();
      return PaginatedResponse<StockMovement>(
        data: list,
        hasMore: body['hasMore'] as bool? ?? false,
        nextCursor: body['nextCursor'] as String?,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Stock state ──────────────────────────────────────────────────

  @override
  Future<StockState> getStockState(String variantId) async {
    try {
      final dio = await _getDio();
      final response = await dio.get(
        '/variants/$variantId/stock-state',
        options: await _options(),
      );
      return _mapStockState(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Mutations ────────────────────────────────────────────────────

  @override
  Future<StockMovement> restock(RestockInput input) async {
    try {
      final dio = await _getDio();
      final response = await dio.post(
        '/variants/${input.variantId}/restock',
        data: {
          'quantity': input.quantity,
          'costPerUnitMillimes': input.unitCost,
          if (input.supplierName != null) 'supplierName': input.supplierName,
          if (input.notes != null) 'notes': input.notes,
          'idempotencyKey': input.idempotencyKey,
        },
        options: await _options(),
      );
      final body = response.data as Map<String, dynamic>;
      // Backend returns { idempotent, movement } on both fresh and
      // idempotent retries — same shape, single mapping path.
      return _mapMovement(body['movement'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<StockMovement> adjust(AdjustmentInput input) async {
    try {
      final dio = await _getDio();
      final response = await dio.post(
        '/variants/${input.variantId}/adjust',
        data: input.toJson(),
        options: await _options(),
      );
      final body = response.data as Map<String, dynamic>;
      return _mapMovement(body['movement'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<String> uploadAdjustmentPhoto(String filePath) async {
    // No dedicated stock-photo endpoint yet — falls back to the
    // generic image upload. TODO(chunk 11): split if image policy
    // diverges (e.g. no Cloudinary transformations on adjustment photos).
    try {
      final dio = await _getDio();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await dio.post(
        '/images/upload',
        data: formData,
        options: await _options(),
      );
      final body = response.data as Map<String, dynamic>;
      return body['url'] as String;
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Reports ──────────────────────────────────────────────────────

  @override
  Future<StockValueReport> getStockValue() async {
    try {
      final dio = await _getDio();
      final boutiqueId = await _getBoutiqueId();
      final response = await dio.get(
        '/boutiques/$boutiqueId/stock/value',
        options: await _options(),
      );
      final body = response.data as Map<String, dynamic>;
      final top = (body['topProducts'] as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .map((j) => StockValueLineItem(
                productId: j['productId'] as String,
                productName: j['productName'] as String,
                units: j['totalUnits'] as int? ?? 0,
                value: j['totalValueMillimes'] as int? ?? 0,
                // TODO(chunk 11): backend select doesn't return thumbnails.
              ))
          .toList();
      return StockValueReport(
        totalValue: body['grandTotalValueMillimes'] as int? ?? 0,
        totalUnits: body['grandTotalUnits'] as int? ?? 0,
        totalProducts: top.length,
        topByValue: top,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<DeadStockEntry>> getDeadStock({int? dormantDays}) async {
    try {
      final dio = await _getDio();
      final boutiqueId = await _getBoutiqueId();
      final response = await dio.get(
        '/boutiques/$boutiqueId/stock/dead',
        queryParameters: {
          if (dormantDays != null) 'dormantDays': dormantDays,
        },
        options: await _options(),
      );
      final body = response.data as Map<String, dynamic>;
      final dormant = body['dormantDays'] as int? ?? dormantDays ?? 60;
      return (body['data'] as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .map((j) {
        final lastSaleAt = j['lastSaleAt'] as String?;
        final since = lastSaleAt != null
            ? DateTime.now().difference(DateTime.parse(lastSaleAt)).inDays
            : (j['dormantDays'] as int? ?? dormant);
        return DeadStockEntry(
          // TODO(chunk 11): backend returns variantId; productId not in
          // /stock/dead select. Use variantId as a stable key for now.
          productId: j['variantId'] as String,
          productName: j['productName'] as String,
          units: j['onHandQuantity'] as int? ?? 0,
          daysSinceLastSale: since,
          // TODO(chunk 11): value (units × WAC) not in backend select.
          value: 0,
        );
      }).toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  ShrinkageBreakdown _mapBreakdown(Map<String, dynamic> body) {
    final byReason = (body['byReason'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .map((j) => StockBreakdownByReason(
              reasonLabel: j['reasonLabel'] as String? ?? '',
              units: j['units'] as int? ?? 0,
              amount: j['amount'] as int? ?? 0,
            ))
        .toList();
    final byProduct = (body['byProduct'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .map((j) => StockBreakdownByProduct(
              productId: j['productId'] as String,
              productName: j['productName'] as String,
              reasonLabel: j['reasonLabel'] as String? ?? '',
              units: j['units'] as int? ?? 0,
              amount: j['amount'] as int? ?? 0,
            ))
        .toList();
    return ShrinkageBreakdown(
      byReason: byReason,
      byProduct: byProduct,
      totalAmount: body['totalAmount'] as int? ?? 0,
      totalUnits: body['totalUnits'] as int? ?? 0,
    );
  }

  @override
  Future<ShrinkageBreakdown> getShrinkage({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final dio = await _getDio();
      final boutiqueId = await _getBoutiqueId();
      final response = await dio.get(
        '/boutiques/$boutiqueId/stock/shrinkage',
        queryParameters: {
          if (from != null) 'from': from.toUtc().toIso8601String(),
          if (to != null) 'to': to.toUtc().toIso8601String(),
        },
        options: await _options(),
      );
      return _mapBreakdown(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<OffSaleOutflowBreakdown> getOffSaleOutflow({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final dio = await _getDio();
      final boutiqueId = await _getBoutiqueId();
      final response = await dio.get(
        '/boutiques/$boutiqueId/stock/off-sale-outflow',
        queryParameters: {
          if (from != null) 'from': from.toUtc().toIso8601String(),
          if (to != null) 'to': to.toUtc().toIso8601String(),
        },
        options: await _options(),
      );
      // Backend now returns the same shape as shrinkage; reuse mapper
      // and re-wrap as OffSaleOutflowBreakdown (different domain class,
      // identical fields).
      final s = _mapBreakdown(response.data as Map<String, dynamic>);
      return OffSaleOutflowBreakdown(
        byReason: s.byReason,
        byProduct: s.byProduct,
        totalAmount: s.totalAmount,
        totalUnits: s.totalUnits,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<BestSellerEntry>> getBestSellers({
    DateTime? from,
    DateTime? to,
    int limit = 5,
  }) async {
    try {
      final dio = await _getDio();
      final boutiqueId = await _getBoutiqueId();
      final response = await dio.get(
        '/boutiques/$boutiqueId/stock/best-sellers',
        queryParameters: {
          if (from != null) 'from': from.toUtc().toIso8601String(),
          if (to != null) 'to': to.toUtc().toIso8601String(),
          'limit': limit,
        },
        options: await _options(),
      );
      return (response.data as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .map((j) => BestSellerEntry(
                productId: j['productId'] as String,
                productName: j['productName'] as String,
                unitsSold: j['unitsSold'] as int? ?? 0,
                revenue: j['revenue'] as int? ?? 0,
              ))
          .toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<SlowMoverEntry>> getSlowMovers({
    DateTime? from,
    DateTime? to,
    int limit = 5,
  }) async {
    try {
      final dio = await _getDio();
      final boutiqueId = await _getBoutiqueId();
      final response = await dio.get(
        '/boutiques/$boutiqueId/stock/slow-movers',
        queryParameters: {
          if (from != null) 'from': from.toUtc().toIso8601String(),
          if (to != null) 'to': to.toUtc().toIso8601String(),
          'limit': limit,
        },
        options: await _options(),
      );
      return (response.data as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .map((j) => SlowMoverEntry(
                productId: j['productId'] as String,
                productName: j['productName'] as String,
                unitsSold: j['unitsSold'] as int? ?? 0,
                unitsRemaining: j['unitsRemaining'] as int? ?? 0,
              ))
          .toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<StockMovement>> getLowStockMovements() async {
    try {
      final dio = await _getDio();
      final boutiqueId = await _getBoutiqueId();
      final response = await dio.get(
        '/boutiques/$boutiqueId/stock/low-movements',
        options: await _options(),
      );
      return (response.data as List<dynamic>)
          .map((e) => _mapMovement(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<LowStockEntry>> getLowStockVariants() async {
    try {
      final dio = await _getDio();
      final boutiqueId = await _getBoutiqueId();
      final response = await dio.get(
        '/boutiques/$boutiqueId/stock/low',
        options: await _options(),
      );
      return (response.data as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .map((j) => LowStockEntry(
                // TODO(chunk 11): backend select doesn't include
                // productId / variantLabel / currentWacMillimes.
                // Use variantId as productId surrogate; label '—'.
                productId: j['variantId'] as String,
                productName: j['productName'] as String,
                variantId: j['variantId'] as String,
                variantLabel: '—',
                sku: j['sku'] as String,
                currentAvailable: j['availableQuantity'] as int? ?? 0,
                threshold: j['threshold'] as int? ?? 0,
              ))
          .toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Categories ───────────────────────────────────────────────────

  @override
  Future<List<Category>> getCategories() async {
    try {
      final dio = await _getDio();
      final boutiqueId = await _getBoutiqueId();
      final response = await dio.get(
        '/boutiques/$boutiqueId/categories',
        options: await _options(),
      );
      return (response.data as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .map((j) => Category(
                id: j['id'] as String,
                name: j['name'] as String,
                productCount: (j['_count'] as Map<String, dynamic>?)
                            ?['products'] as int? ??
                        0,
              ))
          .toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<Category> createCategory(CategoryInput input) async {
    try {
      final dio = await _getDio();
      final boutiqueId = await _getBoutiqueId();
      final response = await dio.post(
        '/boutiques/$boutiqueId/categories',
        data: input.toJson(),
        options: await _options(),
      );
      final j = response.data as Map<String, dynamic>;
      return Category(
        id: j['id'] as String,
        name: j['name'] as String,
        productCount: 0,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<Category> updateCategory(String id, CategoryInput input) async {
    try {
      final dio = await _getDio();
      final boutiqueId = await _getBoutiqueId();
      final response = await dio.patch(
        '/boutiques/$boutiqueId/categories/$id',
        data: input.toJson(),
        options: await _options(),
      );
      final j = response.data as Map<String, dynamic>;
      return Category(
        id: j['id'] as String,
        name: j['name'] as String,
        productCount: 0,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> deleteCategory(
    String id, {
    String? moveProductsToId,
  }) async {
    // TODO(chunk 11): moveProductsToId is silently ignored; backend
    // soft-delete only. See CHUNK_11_POLISH.md for the migration plan.
    try {
      final dio = await _getDio();
      final boutiqueId = await _getBoutiqueId();
      await dio.delete(
        '/boutiques/$boutiqueId/categories/$id',
        options: await _options(),
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Stock settings ───────────────────────────────────────────────

  @override
  Future<BoutiqueStockSettings> getStockSettings() async {
    try {
      final dio = await _getDio();
      final boutiqueId = await _getBoutiqueId();
      final response = await dio.get(
        '/boutiques/$boutiqueId/stock/settings',
        options: await _options(),
      );
      final j = response.data as Map<String, dynamic>;
      // TODO(chunk 11): pushNotif* fields are not yet stored on the
      // backend boutique_stock_settings row. Default to false until
      // the column migration ships.
      return BoutiqueStockSettings(
        defaultLowStockThreshold:
            j['defaultLowStockThreshold'] as int? ?? 5,
        dormantDays: j['deadStockDays'] as int? ?? 60,
        defaultBackorderEnabled:
            j['backorderEnabledDefault'] as bool? ?? false,
        pushNotifLowStock: false,
        pushNotifRupture: false,
        pushNotifRestockConfirmed: false,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<BoutiqueStockSettings> updateStockSettings(
    BoutiqueStockSettings settings,
  ) async {
    try {
      final dio = await _getDio();
      final boutiqueId = await _getBoutiqueId();
      final response = await dio.patch(
        '/boutiques/$boutiqueId/stock/settings',
        data: {
          'defaultLowStockThreshold': settings.defaultLowStockThreshold,
          'deadStockDays': settings.dormantDays,
          'backorderEnabledDefault': settings.defaultBackorderEnabled,
          // pushNotif* intentionally omitted — backend has no column.
        },
        options: await _options(),
      );
      final j = response.data as Map<String, dynamic>;
      return BoutiqueStockSettings(
        defaultLowStockThreshold:
            j['defaultLowStockThreshold'] as int? ?? settings.defaultLowStockThreshold,
        dormantDays: j['deadStockDays'] as int? ?? settings.dormantDays,
        defaultBackorderEnabled: j['backorderEnabledDefault'] as bool? ??
            settings.defaultBackorderEnabled,
        pushNotifLowStock: settings.pushNotifLowStock,
        pushNotifRupture: settings.pushNotifRupture,
        pushNotifRestockConfirmed: settings.pushNotifRestockConfirmed,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Bundles ──────────────────────────────────────────────────────

  @override
  Future<StockBundle> getBundle(String productId) async {
    try {
      final dio = await _getDio();
      final response = await dio.get(
        '/products/$productId/components',
        options: await _options(),
      );
      final list = (response.data as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      final components = list.map((row) {
        final comp = row['component'] as Map<String, dynamic>;
        final product = comp['product'] as Map<String, dynamic>;
        final attrs =
            (comp['variantAttributeValues'] as List<dynamic>? ?? [])
                .map((e) => e as Map<String, dynamic>)
                .map((a) => '${(a['attributeDefinition']
                    as Map<String, dynamic>)['name']}: ${a['value']}')
                .join(', ');
        return _BundleComponentWithStock(
          component: BundleComponent(
            componentVariantId: comp['id'] as String,
            componentProductName: product['name'] as String,
            componentSku: comp['sku'] as String,
            qtyPerBundle: row['quantity'] as int? ?? 1,
            componentCost: comp['currentAvgCostMillimes'] as int? ?? 0,
            // TODO(chunk 11): backend select doesn't join to product_images;
            // thumbnail support comes via the bundle.service select extension.
            componentThumbnailUrl: null,
          ),
          onHand: comp['onHandQuantity'] as int? ?? 0,
          committed: comp['committedQuantity'] as int? ?? 0,
          attributesLabel: attrs,
        );
      }).toList();

      // computedAvailability = min(onHand_i / qtyPerBundle_i)
      // Treats committed as already-reserved (subtracts) so the
      // number reflects what can be sold today, not theoretical max.
      var minAvail = components.isEmpty ? 0 : (1 << 30);
      for (final c in components) {
        final available = (c.onHand - c.committed).clamp(0, 1 << 30);
        final per = c.component.qtyPerBundle == 0 ? 1 : c.component.qtyPerBundle;
        final candidate = available ~/ per;
        if (candidate < minAvail) minAvail = candidate;
      }
      if (minAvail == (1 << 30)) minAvail = 0;

      return StockBundle(
        bundleProductId: productId,
        components: components.map((c) => c.component).toList(),
        computedAvailability: minAvail,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<StockBundle> upsertBundle(
    String productId,
    List<BundleComponent> components,
  ) async {
    try {
      final dio = await _getDio();
      await dio.post(
        '/products/$productId/components',
        data: {
          'components': components
              .map((c) => {
                    'variantId': c.componentVariantId,
                    'quantity': c.qtyPerBundle,
                  })
              .toList(),
        },
        options: await _options(),
      );
      // Backend returns the freshly-stored components; re-read via
      // getBundle to recompute availability with the same mapper.
      return getBundle(productId);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}

/// Internal aggregate used while computing bundle availability —
/// keeps onHand/committed alongside the public BundleComponent so the
/// availability calculation has access without leaking those fields
/// to consumers (BundleComponent stays the wire-facing shape).
class _BundleComponentWithStock {
  const _BundleComponentWithStock({
    required this.component,
    required this.onHand,
    required this.committed,
    required this.attributesLabel,
  });

  final BundleComponent component;
  final int onHand;
  final int committed;
  final String attributesLabel;
}
