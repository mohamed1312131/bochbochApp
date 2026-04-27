
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

  bool get isSimple => attributes.isEmpty;

  String get attributeLabel => attributes.isEmpty
      ? 'Default'
      : attributes.map((a) => a.value.toUpperCase()).join(' · ');

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
  });

  final String id;
  final String name;
  final String? description;
  final String? category;
  final int baseCostPrice;
  final int baseSellPrice;
  final bool isActive;
  final bool isMultiVariant;
  final List<ProductImage> images;
  final List<ProductVariant> variants;
  final DateTime createdAt;
  final DateTime updatedAt;

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