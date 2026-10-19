
class ProductImage {
  const ProductImage({
    required this.id,
    required this.url,
    required this.cloudinaryPublicId,
    required this.isPrimary,
    required this.displayOrder,
    this.altText,
  });

  final String id;
  final String url;
  final String cloudinaryPublicId;
  final bool isPrimary;
  final int displayOrder;
  final String? altText;

  factory ProductImage.fromJson(Map<String, dynamic> json) => ProductImage(
        id: json['id'] as String,
        url: json['url'] as String,
        cloudinaryPublicId: json['cloudinaryPublicId'] as String,
        isPrimary: json['isPrimary'] as bool,
        displayOrder: json['displayOrder'] as int,
        altText: json['altText'] as String?,
      );
}

class ProductAttribute {
  const ProductAttribute({
    required this.name,
    required this.value,
    required this.type,
  });

  final String name;
  final String value;
  final String type;

  factory ProductAttribute.fromJson(Map<String, dynamic> json) =>
      ProductAttribute(
        name: json['name'] as String,
        value: json['value'] as String,
        type: json['type'] as String,
      );
}

class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.sku,
    required this.stockQuantity,
    required this.effectiveCostPrice,
    required this.effectiveSellPrice,
    required this.isActive,
    required this.updatedAt,
    required this.attributes,
    this.costPriceOverride,
    this.sellPriceOverride,
    this.imageId,
    this.availableQuantity,
    this.committedQuantity,
    this.backorderedQuantity,
    this.lowStockThreshold,
    this.backorderEnabled,
  });

  final String id;
  final String sku;
  final int stockQuantity;
  final int effectiveCostPrice;
  final int effectiveSellPrice;
  final bool isActive;
  final DateTime updatedAt;
  final List<ProductAttribute> attributes;
  final int? costPriceOverride;
  final int? sellPriceOverride;
  final String? imageId;

  // ── Stock-aware fields (chunk 8a) ──────────────────────────
  final int? availableQuantity;
  final int? committedQuantity;
  final int? backorderedQuantity;
  final int? lowStockThreshold;
  final bool? backorderEnabled;

  bool get isSimple => attributes.isEmpty;

  String get attributeLabel => attributes.isEmpty
      ? 'Default'
      : attributes.map((a) => a.value.toUpperCase()).join(' · ');

  /// Fall back to legacy `stockQuantity` when the structured
  /// `availableQuantity` field hasn't been populated yet.
  int get effectiveAvailableQuantity => availableQuantity ?? stockQuantity;

  /// Default 3 matches `BoutiqueStockSettings.defaultLowStockThreshold`.
  /// Wired to live settings in chunk 8b.
  int get effectiveLowStockThreshold => lowStockThreshold ?? 3;

  bool get isLowStock =>
      effectiveAvailableQuantity <= effectiveLowStockThreshold;
  bool get isOutOfStock => effectiveAvailableQuantity <= 0;

  ProductVariant copyWith({
    String? id,
    String? sku,
    int? stockQuantity,
    int? effectiveCostPrice,
    int? effectiveSellPrice,
    bool? isActive,
    DateTime? updatedAt,
    List<ProductAttribute>? attributes,
    int? costPriceOverride,
    int? sellPriceOverride,
    String? imageId,
    int? availableQuantity,
    int? committedQuantity,
    int? backorderedQuantity,
    int? lowStockThreshold,
    bool? backorderEnabled,
  }) =>
      ProductVariant(
        id: id ?? this.id,
        sku: sku ?? this.sku,
        stockQuantity: stockQuantity ?? this.stockQuantity,
        effectiveCostPrice: effectiveCostPrice ?? this.effectiveCostPrice,
        effectiveSellPrice: effectiveSellPrice ?? this.effectiveSellPrice,
        isActive: isActive ?? this.isActive,
        updatedAt: updatedAt ?? this.updatedAt,
        attributes: attributes ?? this.attributes,
        costPriceOverride: costPriceOverride ?? this.costPriceOverride,
        sellPriceOverride: sellPriceOverride ?? this.sellPriceOverride,
        imageId: imageId ?? this.imageId,
        availableQuantity: availableQuantity ?? this.availableQuantity,
        committedQuantity: committedQuantity ?? this.committedQuantity,
        backorderedQuantity:
            backorderedQuantity ?? this.backorderedQuantity,
        lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
        backorderEnabled: backorderEnabled ?? this.backorderEnabled,
      );

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
        id: json['id'] as String,
        sku: json['sku'] as String,
        stockQuantity: json['stockQuantity'] as int,
        effectiveCostPrice: json['effectiveCostPrice'] as int,
        effectiveSellPrice: json['effectiveSellPrice'] as int,
        isActive: json['isActive'] as bool,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        attributes: (json['attributes'] as List)
            .map((e) => ProductAttribute.fromJson(e as Map<String, dynamic>))
            .toList(),
        costPriceOverride: json['costPriceOverride'] as int?,
        sellPriceOverride: json['sellPriceOverride'] as int?,
        imageId: json['imageId'] as String?,
        availableQuantity: json['availableQuantity'] as int?,
        committedQuantity: json['committedQuantity'] as int?,
        backorderedQuantity: json['backorderedQuantity'] as int?,
        lowStockThreshold: json['lowStockThreshold'] as int?,
        backorderEnabled: json['backorderEnabled'] as bool?,
      );
}

// Full product (detail screen)
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.baseCostPrice,
    required this.baseSellPrice,
    required this.isActive,
    required this.isMultiVariant,
    required this.images,
    required this.variants,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.category,
    this.categoryId,
    this.isBundle,
  });

  final String id;
  final String name;
  final String? description;
  final String? category;
  final String? categoryId;
  final bool? isBundle;
  final int baseCostPrice;
  final int baseSellPrice;
  final bool isActive;
  final bool isMultiVariant;
  final List<ProductImage> images;
  final List<ProductVariant> variants;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get effectiveIsBundle => isBundle ?? false;

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? categoryId,
    bool? isBundle,
    int? baseCostPrice,
    int? baseSellPrice,
    bool? isActive,
    bool? isMultiVariant,
    List<ProductImage>? images,
    List<ProductVariant>? variants,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        category: category ?? this.category,
        categoryId: categoryId ?? this.categoryId,
        isBundle: isBundle ?? this.isBundle,
        baseCostPrice: baseCostPrice ?? this.baseCostPrice,
        baseSellPrice: baseSellPrice ?? this.baseSellPrice,
        isActive: isActive ?? this.isActive,
        isMultiVariant: isMultiVariant ?? this.isMultiVariant,
        images: images ?? this.images,
        variants: variants ?? this.variants,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  String? get primaryImageUrl {
    try {
      return images.firstWhere((i) => i.isPrimary).url;
    } catch (_) {
      return images.isNotEmpty ? images.first.url : null;
    }
  }

  int get totalStock => variants
      .where((v) => v.isActive)
      .fold(0, (sum, v) => sum + v.stockQuantity);

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        category: json['category'] as String?,
        categoryId: json['categoryId'] as String?,
        isBundle: json['isBundle'] as bool?,
        baseCostPrice: json['baseCostPrice'] as int,
        baseSellPrice: json['baseSellPrice'] as int,
        isActive: json['isActive'] as bool,
        isMultiVariant: json['isMultiVariant'] as bool,
        images: (json['images'] as List)
            .map((e) => ProductImage.fromJson(e as Map<String, dynamic>))
            .toList(),
        variants: (json['variants'] as List)
            .map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

// Lean product (list screen)
class ProductLean {
  const ProductLean({
    required this.id,
    required this.name,
    required this.baseCostPrice,
    required this.baseSellPrice,
    required this.totalStock,
    required this.hasLowStock,
    required this.isActive,
    required this.isMultiVariant,
    required this.createdAt,
    this.category,
    this.primaryImageUrl,
  });

  final String id;
  final String name;
  final String? category;
  final int baseCostPrice;
  final int baseSellPrice;
  final int totalStock;
  final bool hasLowStock;
  final bool isActive;
  final bool isMultiVariant;
  final DateTime createdAt;
  final String? primaryImageUrl;

  int get profitMargin => baseSellPrice - baseCostPrice;

  factory ProductLean.fromJson(Map<String, dynamic> json) => ProductLean(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String?,
        baseCostPrice: json['baseCostPrice'] as int,
        baseSellPrice: json['baseSellPrice'] as int,
        totalStock: json['totalStock'] as int,
        hasLowStock: json['hasLowStock'] as bool,
        isActive: json['isActive'] as bool,
        isMultiVariant: json['isMultiVariant'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
        primaryImageUrl: json['primaryImageUrl'] as String?,
      );
}