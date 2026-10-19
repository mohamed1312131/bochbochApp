enum StockMovementType {
  sale('SALE'),
  saleCancelled('SALE_CANCELLED'),
  returnMovement('RETURN'),
  adjustment('ADJUSTMENT'),
  restock('RESTOCK'),
  damage('DAMAGE'),
  theft('THEFT'),
  recount('RECOUNT'),
  initial('INITIAL'),
  bundleAssembly('BUNDLE_ASSEMBLY'),
  marketingGift('MARKETING_GIFT'),
  personalUse('PERSONAL_USE'),
  sample('SAMPLE'),
  unknown('UNKNOWN');

  const StockMovementType(this.apiValue);
  final String apiValue;

  static StockMovementType fromApi(String value) =>
      values.firstWhere(
        (e) => e.apiValue == value,
        orElse: () => StockMovementType.unknown,
      );
}

enum StockAdjustmentReason {
  damage('DAMAGE'),
  lost('LOST'),
  theft('THEFT'),
  recount('RECOUNT'),
  marketingGift('MARKETING_GIFT'),
  personalUse('PERSONAL_USE'),
  sample('SAMPLE'),
  other('OTHER');

  const StockAdjustmentReason(this.apiValue);
  final String apiValue;

  String get label => switch (this) {
        StockAdjustmentReason.damage => 'Cassé / endommagé',
        StockAdjustmentReason.lost => 'Perdu',
        StockAdjustmentReason.theft => 'Vol',
        StockAdjustmentReason.recount => 'Recomptage',
        StockAdjustmentReason.marketingGift => 'Cadeau influenceur / promo',
        StockAdjustmentReason.personalUse => 'Cadeau personnel / famille',
        StockAdjustmentReason.sample => 'Échantillon',
        StockAdjustmentReason.other => 'Autre',
      };

  static StockAdjustmentReason fromApi(String value) =>
      values.firstWhere((e) => e.apiValue == value);
}

enum StockReferenceType {
  order('ORDER'),
  returnRef('RETURN'),
  restock('RESTOCK'),
  manualAdjustment('MANUAL_ADJUSTMENT'),
  bundleAssembly('BUNDLE_ASSEMBLY'),
  initialStock('INITIAL_STOCK');

  const StockReferenceType(this.apiValue);
  final String apiValue;

  static StockReferenceType fromApi(String value) =>
      values.firstWhere((e) => e.apiValue == value);
}

/// Maps backend movement types to the 4 visual kinds in StockHistoryRow.
enum StockHistoryDisplayKind { sold, restock, broken, gift }

extension StockMovementTypeUI on StockMovementType {
  StockHistoryDisplayKind get displayKind => switch (this) {
        StockMovementType.sale => StockHistoryDisplayKind.sold,
        StockMovementType.saleCancelled => StockHistoryDisplayKind.restock,
        StockMovementType.returnMovement => StockHistoryDisplayKind.sold,
        StockMovementType.restock => StockHistoryDisplayKind.restock,
        StockMovementType.initial => StockHistoryDisplayKind.restock,
        StockMovementType.bundleAssembly => StockHistoryDisplayKind.restock,
        StockMovementType.damage => StockHistoryDisplayKind.broken,
        StockMovementType.theft => StockHistoryDisplayKind.broken,
        StockMovementType.recount => StockHistoryDisplayKind.broken,
        StockMovementType.adjustment => StockHistoryDisplayKind.broken,
        StockMovementType.marketingGift => StockHistoryDisplayKind.gift,
        StockMovementType.personalUse => StockHistoryDisplayKind.gift,
        StockMovementType.sample => StockHistoryDisplayKind.gift,
        StockMovementType.unknown => StockHistoryDisplayKind.broken,
      };

  String get displayLabel => switch (this) {
        StockMovementType.sale => 'Vendu',
        StockMovementType.saleCancelled => 'Vente annulée',
        StockMovementType.returnMovement => 'Retour',
        StockMovementType.adjustment => 'Ajustement',
        StockMovementType.restock => 'Restock',
        StockMovementType.damage => 'Cassé',
        StockMovementType.theft => 'Vol',
        StockMovementType.recount => 'Recomptage',
        StockMovementType.initial => 'Stock initial',
        StockMovementType.bundleAssembly => 'Assemblage pack',
        StockMovementType.marketingGift => 'Cadeau influenceur',
        StockMovementType.personalUse => 'Usage personnel',
        StockMovementType.sample => 'Échantillon',
        StockMovementType.unknown => 'Mouvement',
      };
}
