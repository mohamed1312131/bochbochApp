import '../domain/stock_enums.dart';
import '../domain/stock_models.dart';
import '../domain/stock_movement.dart';

// ── Product/variant ID constants ────────────────────────────────────
const _pSac = 'prod_sac_cuir_noir';
const _vSac = 'var_sac_cuir_noir_tm';
const _pSneakers = 'prod_sneakers_blanches';
const _vSneakers = 'var_sneakers_blanches_42';
const _pRobe = 'prod_robe_ete';
const _vRobe = 'var_robe_ete_m';
const _pFoulard = 'prod_foulard_soie';
const _vFoulard = 'var_foulard_soie_uniq';
const _pTrousse = 'prod_trousse_maquillage';
const _vTrousse = 'var_trousse_maquillage_std';
const _pManteau = 'prod_manteau_hiver';
const _vManteau = 'var_manteau_hiver_l';

DateTime _ago(int days, {int hours = 0, int minutes = 0}) =>
    DateTime.now().subtract(
      Duration(days: days, hours: hours, minutes: minutes),
    );

class StockMockData {
  StockMockData._();

  static List<StockMovement> get allMovements => List.unmodifiable(_movements);
  static List<Category> get categories => List.unmodifiable(_categories);
  static BoutiqueStockSettings get defaultSettings => _settings;
  static StockValueReport get stockValueReport => _stockValueReport;
  static List<DeadStockEntry> get deadStock => List.unmodifiable(_deadStock);
  static ShrinkageBreakdown get shrinkage => _shrinkage;
  static OffSaleOutflowBreakdown get offSaleOutflow => _offSaleOutflow;
  static List<BestSellerEntry> get bestSellers =>
      List.unmodifiable(_bestSellers);
  static List<SlowMoverEntry> get slowMovers =>
      List.unmodifiable(_slowMovers);
  static StockState stockStateFor(String variantId) =>
      _stockStates[variantId]!;
  static Map<String, StockState> get stockStatesByVariant =>
      Map.from(_stockStates);
  static StockBundle get sampleBundle => _bundle;

  // ── Movements ───────────────────────────────────────────────
  // Per variant — chronological, aggregated. Final qtyAfter must equal
  // the corresponding StockState.onHand below.
  static final List<StockMovement> _movements = [
    // var_sac_cuir_noir_tm — final onHand: 10
    StockMovement(
      id: 'mov_sac_001',
      productId: _pSac,
      variantId: _vSac,
      type: StockMovementType.initial,
      qtyDelta: 5,
      qtyBefore: 0,
      qtyAfter: 5,
      unitCostAtTime: 850000,
      referenceType: StockReferenceType.initialStock,
      referenceLabel: 'Stock initial',
      createdAt: _ago(60),
    ),
    StockMovement(
      id: 'mov_sac_002',
      productId: _pSac,
      variantId: _vSac,
      type: StockMovementType.restock,
      qtyDelta: 10,
      qtyBefore: 5,
      qtyAfter: 15,
      unitCostAtTime: 870000,
      referenceType: StockReferenceType.restock,
      referenceLabel: 'Tunis Fashion · 870 TND/u',
      createdAt: _ago(45),
    ),
    StockMovement(
      id: 'mov_sac_003',
      productId: _pSac,
      variantId: _vSac,
      type: StockMovementType.sale,
      qtyDelta: -1,
      qtyBefore: 15,
      qtyAfter: 14,
      unitCostAtTime: 870000,
      referenceType: StockReferenceType.order,
      referenceId: 'ord_198',
      referenceLabel: 'Commande #198 — Salma',
      createdAt: _ago(30),
    ),
    StockMovement(
      id: 'mov_sac_004',
      productId: _pSac,
      variantId: _vSac,
      type: StockMovementType.sale,
      qtyDelta: -2,
      qtyBefore: 14,
      qtyAfter: 12,
      unitCostAtTime: 870000,
      referenceType: StockReferenceType.order,
      referenceId: 'ord_210',
      referenceLabel: 'Commande #210 — Yasmine',
      createdAt: _ago(20),
    ),
    StockMovement(
      id: 'mov_sac_005',
      productId: _pSac,
      variantId: _vSac,
      type: StockMovementType.marketingGift,
      reasonCode: StockAdjustmentReason.marketingGift,
      qtyDelta: -2,
      qtyBefore: 12,
      qtyAfter: 10,
      unitCostAtTime: 0,
      referenceType: StockReferenceType.manualAdjustment,
      referenceLabel: 'Cadeau influenceur / promo',
      notes: 'Cadeau influenceur',
      createdAt: _ago(1),
    ),

    // var_sneakers_blanches_42 — final onHand: 7
    StockMovement(
      id: 'mov_sneakers_001',
      productId: _pSneakers,
      variantId: _vSneakers,
      type: StockMovementType.initial,
      qtyDelta: 5,
      qtyBefore: 0,
      qtyAfter: 5,
      unitCostAtTime: 320000,
      referenceType: StockReferenceType.initialStock,
      referenceLabel: 'Stock initial',
      createdAt: _ago(60),
    ),
    StockMovement(
      id: 'mov_sneakers_002',
      productId: _pSneakers,
      variantId: _vSneakers,
      type: StockMovementType.restock,
      qtyDelta: 5,
      qtyBefore: 5,
      qtyAfter: 10,
      unitCostAtTime: 320000,
      referenceType: StockReferenceType.restock,
      referenceLabel: 'Tunis Fashion · 320 TND/u',
      createdAt: _ago(50),
    ),
    StockMovement(
      id: 'mov_sneakers_003',
      productId: _pSneakers,
      variantId: _vSneakers,
      type: StockMovementType.sale,
      qtyDelta: -2,
      qtyBefore: 10,
      qtyAfter: 8,
      unitCostAtTime: 320000,
      referenceType: StockReferenceType.order,
      referenceId: 'ord_215',
      referenceLabel: 'Commande #215 — Amira',
      createdAt: _ago(25),
    ),
    StockMovement(
      id: 'mov_sneakers_004',
      productId: _pSneakers,
      variantId: _vSneakers,
      type: StockMovementType.sale,
      qtyDelta: -1,
      qtyBefore: 8,
      qtyAfter: 7,
      unitCostAtTime: 320000,
      referenceType: StockReferenceType.order,
      referenceId: 'ord_267',
      referenceLabel: 'Commande #267 — Rania',
      createdAt: _ago(3),
    ),

    // var_robe_ete_m — final onHand: 9
    StockMovement(
      id: 'mov_robe_001',
      productId: _pRobe,
      variantId: _vRobe,
      type: StockMovementType.initial,
      qtyDelta: 9,
      qtyBefore: 0,
      qtyAfter: 9,
      unitCostAtTime: 180000,
      referenceType: StockReferenceType.initialStock,
      referenceLabel: 'Stock initial',
      createdAt: _ago(55),
    ),

    // var_foulard_soie_uniq — final onHand: 3
    StockMovement(
      id: 'mov_foulard_001',
      productId: _pFoulard,
      variantId: _vFoulard,
      type: StockMovementType.initial,
      qtyDelta: 5,
      qtyBefore: 0,
      qtyAfter: 5,
      unitCostAtTime: 260000,
      referenceType: StockReferenceType.initialStock,
      referenceLabel: 'Stock initial',
      createdAt: _ago(55),
    ),
    StockMovement(
      id: 'mov_foulard_002',
      productId: _pFoulard,
      variantId: _vFoulard,
      type: StockMovementType.sale,
      qtyDelta: -1,
      qtyBefore: 5,
      qtyAfter: 4,
      unitCostAtTime: 260000,
      referenceType: StockReferenceType.order,
      referenceId: 'ord_201',
      referenceLabel: 'Commande #201 — Salma',
      createdAt: _ago(10),
    ),
    StockMovement(
      id: 'mov_foulard_003',
      productId: _pFoulard,
      variantId: _vFoulard,
      type: StockMovementType.damage,
      reasonCode: StockAdjustmentReason.damage,
      qtyDelta: -1,
      qtyBefore: 4,
      qtyAfter: 3,
      unitCostAtTime: 0,
      referenceType: StockReferenceType.manualAdjustment,
      referenceLabel: 'Cassé / endommagé',
      notes: 'Bouteille tombée',
      createdAt: _ago(1),
    ),

    // var_trousse_maquillage_std — final onHand: 2 (LOW)
    StockMovement(
      id: 'mov_trousse_001',
      productId: _pTrousse,
      variantId: _vTrousse,
      type: StockMovementType.initial,
      qtyDelta: 6,
      qtyBefore: 0,
      qtyAfter: 6,
      unitCostAtTime: 60000,
      referenceType: StockReferenceType.initialStock,
      referenceLabel: 'Stock initial',
      createdAt: _ago(55),
    ),
    StockMovement(
      id: 'mov_trousse_002',
      productId: _pTrousse,
      variantId: _vTrousse,
      type: StockMovementType.sale,
      qtyDelta: -2,
      qtyBefore: 6,
      qtyAfter: 4,
      unitCostAtTime: 60000,
      referenceType: StockReferenceType.order,
      referenceId: 'ord_220',
      referenceLabel: 'Commande #220 — Imen',
      createdAt: _ago(15),
    ),
    StockMovement(
      id: 'mov_trousse_003',
      productId: _pTrousse,
      variantId: _vTrousse,
      type: StockMovementType.sale,
      qtyDelta: -2,
      qtyBefore: 4,
      qtyAfter: 2,
      unitCostAtTime: 60000,
      referenceType: StockReferenceType.order,
      referenceId: 'ord_240',
      referenceLabel: 'Commande #240 — Sami',
      createdAt: _ago(8),
    ),

    // var_manteau_hiver_l — final onHand: 6 (DEAD STOCK)
    StockMovement(
      id: 'mov_manteau_001',
      productId: _pManteau,
      variantId: _vManteau,
      type: StockMovementType.initial,
      qtyDelta: 8,
      qtyBefore: 0,
      qtyAfter: 8,
      unitCostAtTime: 120000,
      referenceType: StockReferenceType.initialStock,
      referenceLabel: 'Stock initial',
      createdAt: _ago(100),
    ),
    StockMovement(
      id: 'mov_manteau_002',
      productId: _pManteau,
      variantId: _vManteau,
      type: StockMovementType.sale,
      qtyDelta: -1,
      qtyBefore: 8,
      qtyAfter: 7,
      unitCostAtTime: 120000,
      referenceType: StockReferenceType.order,
      referenceId: 'ord_150',
      referenceLabel: 'Commande #150 — Nour',
      createdAt: _ago(95),
    ),
    StockMovement(
      id: 'mov_manteau_003',
      productId: _pManteau,
      variantId: _vManteau,
      type: StockMovementType.sale,
      qtyDelta: -1,
      qtyBefore: 7,
      qtyAfter: 6,
      unitCostAtTime: 120000,
      referenceType: StockReferenceType.order,
      referenceId: 'ord_155',
      referenceLabel: 'Commande #155 — Leila',
      createdAt: _ago(90),
    ),
  ];

  // ── Stock states (must match sum of movement qtyDelta per variant) ──
  static final Map<String, StockState> _stockStates = {
    _vSac: const StockState(
      variantId: _vSac,
      onHand: 10,
      available: 7,
      committed: 3,
      backordered: 0,
      committedOrders: [
        CommittedOrderRef(
          orderId: 'ord_234',
          orderNumber: '#234',
          customerName: 'Amira',
          qty: 1,
        ),
        CommittedOrderRef(
          orderId: 'ord_267',
          orderNumber: '#267',
          customerName: 'Rania',
          qty: 2,
        ),
      ],
    ),
    _vSneakers: const StockState(
      variantId: _vSneakers,
      onHand: 7,
      available: 7,
      committed: 0,
      backordered: 0,
      committedOrders: [],
    ),
    _vRobe: const StockState(
      variantId: _vRobe,
      onHand: 9,
      available: 9,
      committed: 0,
      backordered: 0,
      committedOrders: [],
    ),
    _vFoulard: const StockState(
      variantId: _vFoulard,
      onHand: 3,
      available: 3,
      committed: 0,
      backordered: 0,
      committedOrders: [],
    ),
    _vTrousse: const StockState(
      variantId: _vTrousse,
      onHand: 2,
      available: 2,
      committed: 0,
      backordered: 0,
      committedOrders: [],
    ),
    _vManteau: const StockState(
      variantId: _vManteau,
      onHand: 6,
      available: 6,
      committed: 0,
      backordered: 0,
      committedOrders: [],
    ),
  };

  // ── Categories ──────────────────────────────────────────────
  static final List<Category> _categories = const [
    Category(id: 'cat_robes', name: 'Robes', productCount: 18),
    Category(id: 'cat_sacs', name: 'Sacs', productCount: 8),
    Category(id: 'cat_chaussures', name: 'Chaussures', productCount: 5),
    Category(id: 'cat_accessoires', name: 'Accessoires', productCount: 12),
    Category(id: 'cat_manteaux', name: 'Manteaux', productCount: 4),
  ];

  // ── Settings ────────────────────────────────────────────────
  static const BoutiqueStockSettings _settings = BoutiqueStockSettings(
    defaultLowStockThreshold: 3,
    dormantDays: 60,
    defaultBackorderEnabled: false,
    pushNotifLowStock: true,
    pushNotifRupture: true,
    pushNotifRestockConfirmed: false,
  );

  // ── Stock value report ──────────────────────────────────────
  static const StockValueReport _stockValueReport = StockValueReport(
    totalValue: 12400000,
    totalUnits: 235,
    totalProducts: 47,
    topByValue: [
      StockValueLineItem(
        productId: _pSac,
        productName: 'Sac cuir noir',
        units: 12,
        value: 4800000,
        thumbnailColor: 0xFF3F2A1F,
      ),
      StockValueLineItem(
        productId: _pSneakers,
        productName: 'Sneakers blanches',
        units: 7,
        value: 2240000,
        thumbnailColor: 0xFFE5E5E5,
      ),
      StockValueLineItem(
        productId: _pRobe,
        productName: 'Robe été',
        units: 9,
        value: 1620000,
        thumbnailColor: 0xFF7C8FA6,
      ),
      StockValueLineItem(
        productId: _pFoulard,
        productName: 'Foulard soie',
        units: 3,
        value: 1040000,
        thumbnailColor: 0xFF9B6B4A,
      ),
      StockValueLineItem(
        productId: _pTrousse,
        productName: 'Trousse maquillage',
        units: 12,
        value: 720000,
        thumbnailColor: 0xFFC9B59E,
      ),
    ],
  );

  // ── Dead stock ──────────────────────────────────────────────
  static const List<DeadStockEntry> _deadStock = [
    DeadStockEntry(
      productId: _pManteau,
      productName: 'Manteau hiver',
      units: 6,
      daysSinceLastSale: 90,
      value: 720000,
      category: 'manteaux',
      thumbnailColor: 0xFF1F1F1F,
    ),
    DeadStockEntry(
      productId: 'prod_sandales_rose',
      productName: 'Sandales rose',
      units: 4,
      daysSinceLastSale: 102,
      value: 380000,
      category: 'chaussures',
      thumbnailColor: 0xFFE8B4B8,
    ),
    DeadStockEntry(
      productId: 'prod_sac_plage_paillette',
      productName: 'Sac plage paillette',
      units: 8,
      daysSinceLastSale: 71,
      value: 480000,
      category: 'sacs',
      thumbnailColor: 0xFFD4AF37,
    ),
  ];

  // ── Shrinkage (Pertes) ──────────────────────────────────────
  static const ShrinkageBreakdown _shrinkage = ShrinkageBreakdown(
    byReason: [
      StockBreakdownByReason(
        reasonLabel: 'Cassé / endommagé',
        units: 3,
        amount: 120000,
      ),
      StockBreakdownByReason(
        reasonLabel: 'Perdu',
        units: 1,
        amount: 40000,
      ),
      StockBreakdownByReason(
        reasonLabel: 'Vol',
        units: 2,
        amount: 180000,
      ),
      StockBreakdownByReason(
        reasonLabel: 'Écart de comptage',
        units: 1,
        amount: 35000,
      ),
    ],
    byProduct: [
      StockBreakdownByProduct(
        productId: 'prod_bouteille_parfum',
        productName: 'Bouteille parfum',
        reasonLabel: 'Cassé · 1 unité',
        units: 1,
        amount: 85000,
        thumbnailColor: 0xFFB8A88C,
      ),
      StockBreakdownByProduct(
        productId: _pFoulard,
        productName: 'Foulard soie',
        reasonLabel: 'Vol · 2 unités',
        units: 2,
        amount: 180000,
        thumbnailColor: 0xFF9B6B4A,
      ),
    ],
    totalAmount: 375000,
    totalUnits: 7,
  );

  // ── Off-sale outflow (Sortie hors-vente) ────────────────────
  static const OffSaleOutflowBreakdown _offSaleOutflow =
      OffSaleOutflowBreakdown(
    byReason: [
      StockBreakdownByReason(
        reasonLabel: 'Cadeaux influenceurs',
        units: 4,
        amount: 180000,
      ),
      StockBreakdownByReason(
        reasonLabel: 'Usage personnel',
        units: 2,
        amount: 90000,
      ),
      StockBreakdownByReason(
        reasonLabel: 'Échantillons',
        units: 3,
        amount: 120000,
      ),
    ],
    byProduct: [],
    totalAmount: 390000,
    totalUnits: 9,
  );

  // ── Best sellers ────────────────────────────────────────────
  static const List<BestSellerEntry> _bestSellers = [
    BestSellerEntry(
      productId: _pSac,
      productName: 'Sac cuir noir',
      unitsSold: 8,
      revenue: 7840000,
      thumbnailColor: 0xFF3F2A1F,
    ),
    BestSellerEntry(
      productId: _pSneakers,
      productName: 'Sneakers blanches',
      unitsSold: 5,
      revenue: 1600000,
      thumbnailColor: 0xFFE5E5E5,
    ),
    BestSellerEntry(
      productId: _pRobe,
      productName: 'Robe été',
      unitsSold: 4,
      revenue: 1680000,
      thumbnailColor: 0xFF7C8FA6,
    ),
    BestSellerEntry(
      productId: _pFoulard,
      productName: 'Foulard soie',
      unitsSold: 3,
      revenue: 780000,
      thumbnailColor: 0xFF9B6B4A,
    ),
    BestSellerEntry(
      productId: _pTrousse,
      productName: 'Trousse maquillage',
      unitsSold: 3,
      revenue: 540000,
      thumbnailColor: 0xFFC9B59E,
    ),
  ];

  // ── Slow movers ─────────────────────────────────────────────
  static const List<SlowMoverEntry> _slowMovers = [
    SlowMoverEntry(
      productId: 'prod_bracelet_dore',
      productName: 'Bracelet doré',
      unitsSold: 1,
      unitsRemaining: 8,
      thumbnailColor: 0xFFD4AF37,
    ),
    SlowMoverEntry(
      productId: 'prod_ceinture_cuir',
      productName: 'Ceinture cuir',
      unitsSold: 1,
      unitsRemaining: 5,
      thumbnailColor: 0xFF6B4423,
    ),
    SlowMoverEntry(
      productId: 'prod_chapeau_paille',
      productName: 'Chapeau paille',
      unitsSold: 2,
      unitsRemaining: 6,
      thumbnailColor: 0xFFE8D5A8,
    ),
    SlowMoverEntry(
      productId: 'prod_lunettes_soleil',
      productName: 'Lunettes soleil',
      unitsSold: 2,
      unitsRemaining: 4,
      thumbnailColor: 0xFF2A2A2A,
    ),
    SlowMoverEntry(
      productId: 'prod_porte_cles',
      productName: 'Porte-clés cuir',
      unitsSold: 1,
      unitsRemaining: 7,
      thumbnailColor: 0xFF8B5A3C,
    ),
  ];

  // ── Sample bundle ───────────────────────────────────────────
  static const StockBundle _bundle = StockBundle(
    bundleProductId: 'prod_pack_saint_valentin',
    components: [
      BundleComponent(
        componentVariantId: 'var_parfum_50ml',
        componentProductName: 'Parfum 50ml',
        componentSku: 'PFM-50',
        qtyPerBundle: 1,
        componentCost: 85000,
      ),
      BundleComponent(
        componentVariantId: 'var_chocolats_box',
        componentProductName: 'Chocolats — boîte',
        componentSku: 'CHOC-BX',
        qtyPerBundle: 1,
        componentCost: 35000,
      ),
      BundleComponent(
        componentVariantId: 'var_rose_unite',
        componentProductName: 'Rose rouge',
        componentSku: 'RSE-1',
        qtyPerBundle: 3,
        componentCost: 8000,
      ),
    ],
    computedAvailability: 8,
  );
}
