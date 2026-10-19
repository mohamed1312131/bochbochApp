/// Stateful, backend-free data source used by the investor demo.
///
/// Values use the same wire shape as the production API. Keeping the demo
/// data in API-shaped maps lets the normal domain parsers exercise the same
/// contracts as production while every mutation stays inside the browser.
class DemoStore {
  DemoStore() {
    reset();
  }

  late Map<String, dynamic> boutique;
  final Map<String, Map<String, dynamic>> products = {};
  final Map<String, Map<String, dynamic>> orders = {};
  final Map<String, Map<String, dynamic>> customers = {};
  final Map<String, List<Map<String, dynamic>>> notes = {};
  final Map<String, List<Map<String, dynamic>>> addresses = {};
  final Map<String, List<Map<String, dynamic>>> exchanges = {};
  final Map<String, List<Map<String, dynamic>>> issues = {};
  Map<String, dynamic>? activeGoal;

  int _sequence = 400;
  int nextId() => ++_sequence;

  void reset() {
    final now = DateTime.now();
    _sequence = 400;
    products.clear();
    orders.clear();
    customers.clear();
    notes.clear();
    addresses.clear();
    exchanges.clear();
    issues.clear();

    boutique = {
      'id': 'boutique_sania',
      'name': 'Boutique Sania',
      'category': 'Mode & accessoires',
      'city': 'Tunis',
      'address': '12, avenue Habib Bourguiba',
      'email': 'contact@boutiquesania.tn',
      'mf': '1827364/A/M/000',
      'brandColor': '#05687B',
      'logoUrl': null,
      'archivedAt': null,
      'createdAt': now.subtract(const Duration(days: 420)).toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };

    final catalog = [
      _product(
        id: 'prod_sac_cuir_noir',
        name: 'Sac cuir noir',
        imageUrl:
            'https://images.pexels.com/photos/6538433/pexels-photo-6538433.jpeg?auto=compress&cs=tinysrgb&w=900&h=900&fit=crop',
        category: 'Sacs',
        sku: 'SCN-TM',
        cost: 92000,
        price: 189000,
        stock: 10,
        threshold: 3,
        createdAt: now.subtract(const Duration(days: 120)),
        description: 'Sac élégant en cuir, finition premium.',
      ),
      _product(
        id: 'prod_sneakers_blanches',
        name: 'Sneakers blanches',
        imageUrl:
            'https://images.pexels.com/photos/4252968/pexels-photo-4252968.jpeg?auto=compress&cs=tinysrgb&w=900&h=900&fit=crop',
        category: 'Chaussures',
        sku: 'SNK-42',
        cost: 65000,
        price: 129000,
        stock: 7,
        threshold: 3,
        createdAt: now.subtract(const Duration(days: 90)),
        attributeName: 'Pointure',
        attributeValue: '42',
      ),
      _product(
        id: 'prod_robe_ete',
        name: 'Robe lin été',
        imageUrl:
            'https://images.pexels.com/photos/12108706/pexels-photo-12108706.jpeg?auto=compress&cs=tinysrgb&w=900&h=900&fit=crop',
        category: 'Vêtements',
        sku: 'RBE-M',
        cost: 72000,
        price: 149000,
        stock: 9,
        threshold: 3,
        createdAt: now.subtract(const Duration(days: 72)),
        attributeName: 'Taille',
        attributeValue: 'M',
      ),
      _product(
        id: 'prod_foulard_soie',
        name: 'Foulard en soie',
        imageUrl:
            'https://images.pexels.com/photos/18661799/pexels-photo-18661799.jpeg?auto=compress&cs=tinysrgb&w=900&h=900&fit=crop',
        category: 'Accessoires',
        sku: 'FS-UNI',
        cost: 28000,
        price: 69000,
        stock: 3,
        threshold: 4,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      _product(
        id: 'prod_trousse_maquillage',
        name: 'Trousse maquillage',
        imageUrl:
            'https://images.pexels.com/photos/27685202/pexels-photo-27685202.jpeg?auto=compress&cs=tinysrgb&w=900&h=900&fit=crop',
        category: 'Accessoires',
        sku: 'TRS-STD',
        cost: 18000,
        price: 45000,
        stock: 2,
        threshold: 3,
        createdAt: now.subtract(const Duration(days: 55)),
      ),
      _product(
        id: 'prod_manteau_hiver',
        name: 'Manteau hiver',
        imageUrl:
            'https://images.pexels.com/photos/10815473/pexels-photo-10815473.jpeg?auto=compress&cs=tinysrgb&w=900&h=900&fit=crop',
        category: 'Vêtements',
        sku: 'MNT-L',
        cost: 120000,
        price: 239000,
        stock: 6,
        threshold: 2,
        createdAt: now.subtract(const Duration(days: 180)),
        attributeName: 'Taille',
        attributeValue: 'L',
      ),
    ];
    for (final product in catalog) {
      products[product['id'] as String] = product;
    }

    final clientData = [
      _customer(
        id: 'cust_salma',
        name: 'Salma Ben Amor',
        phone: '+216 22 145 870',
        city: 'La Marsa',
        governorate: 'Tunis',
        totalOrders: 8,
        totalSpent: 986000,
        segment: 'VIP',
        rfm: 'CHAMPION',
        risk: 'GREEN',
        tags: const ['VIP', 'Instagram'],
        now: now,
      ),
      _customer(
        id: 'cust_yasmine',
        name: 'Yasmine Trabelsi',
        phone: '+216 55 238 419',
        city: 'Ariana',
        governorate: 'Ariana',
        totalOrders: 5,
        totalSpent: 547000,
        segment: 'Fidèle',
        rfm: 'LOYAL',
        risk: 'GREEN',
        tags: const ['Fidèle'],
        now: now,
      ),
      _customer(
        id: 'cust_imen',
        name: 'Imen Gharbi',
        phone: '+216 98 713 205',
        city: 'Sousse',
        governorate: 'Sousse',
        totalOrders: 3,
        totalSpent: 321000,
        segment: 'Prometteur',
        rfm: 'PROMISING',
        risk: 'YELLOW',
        riskReason: 'Une livraison refusée récemment',
        tags: const ['Facebook'],
        now: now,
      ),
      _customer(
        id: 'cust_rania',
        name: 'Rania Mansouri',
        phone: '+216 29 441 806',
        city: 'Nabeul',
        governorate: 'Nabeul',
        totalOrders: 6,
        totalSpent: 674000,
        segment: 'À risque',
        rfm: 'AT_RISK',
        risk: 'RED',
        riskReason: 'Deux refus COD sur les trois dernières commandes',
        tags: const ['À relancer'],
        codEnabled: false,
        codRefusalCount: 2,
        now: now,
      ),
      _customer(
        id: 'cust_nour',
        name: 'Nour Chaabane',
        phone: '+216 26 901 337',
        city: 'Monastir',
        governorate: 'Monastir',
        totalOrders: 1,
        totalSpent: 149000,
        segment: 'Nouveau',
        rfm: 'NEW',
        risk: 'GREEN',
        tags: const ['Nouveau'],
        now: now,
      ),
      _customer(
        id: 'cust_amira',
        name: 'Amira Khelifi',
        phone: '+216 53 671 922',
        city: 'Sfax',
        governorate: 'Sfax',
        totalOrders: 4,
        totalSpent: 456000,
        segment: 'Fidèle',
        rfm: 'LOYAL',
        risk: 'GREEN',
        tags: const ['WhatsApp'],
        now: now,
      ),
    ];
    for (final customer in clientData) {
      final id = customer['id'] as String;
      customers[id] = customer;
      notes[id] = [
        {
          'id': 'note_$id',
          'customerId': id,
          'content': id == 'cust_rania'
              ? 'Confirmer la commande par téléphone avant expédition.'
              : 'Cliente contactée via WhatsApp.',
          'isPinned': id == 'cust_rania',
          'createdAt': now.subtract(const Duration(days: 7)).toIso8601String(),
          'updatedAt': now.subtract(const Duration(days: 7)).toIso8601String(),
        },
      ];
      addresses[id] = [
        {
          'id': 'addr_$id',
          'customerId': id,
          'label': 'Domicile',
          'addressLine': customer['address'],
          'city': customer['city'],
          'governorate': customer['governorate'],
          'deliveryNotes': 'Appeler avant la livraison',
          'isDefault': true,
          'createdAt': now
              .subtract(const Duration(days: 100))
              .toIso8601String(),
          'updatedAt': now.subtract(const Duration(days: 10)).toIso8601String(),
        },
      ];
    }

    final orderData = [
      _order(
        'ord_401',
        '#401',
        'PENDING',
        customers['cust_salma']!,
        products['prod_sac_cuir_noir']!,
        1,
        now.subtract(const Duration(minutes: 35)),
      ),
      _order(
        'ord_400',
        '#400',
        'CONFIRMED',
        customers['cust_yasmine']!,
        products['prod_robe_ete']!,
        2,
        now.subtract(const Duration(hours: 2)),
      ),
      _order(
        'ord_399',
        '#399',
        'SHIPPED',
        customers['cust_amira']!,
        products['prod_sneakers_blanches']!,
        1,
        now.subtract(const Duration(hours: 5)),
      ),
      _order(
        'ord_398',
        '#398',
        'DELIVERED',
        customers['cust_imen']!,
        products['prod_foulard_soie']!,
        2,
        now.subtract(const Duration(days: 1)),
      ),
      _order(
        'ord_397',
        '#397',
        'RTO_IN_TRANSIT',
        customers['cust_rania']!,
        products['prod_trousse_maquillage']!,
        1,
        now.subtract(const Duration(days: 2)),
        rtoReason: 'REFUSED',
      ),
      _order(
        'ord_396',
        '#396',
        'DELIVERED',
        customers['cust_salma']!,
        products['prod_robe_ete']!,
        1,
        now.subtract(const Duration(days: 3)),
      ),
      _order(
        'ord_395',
        '#395',
        'CANCELLED',
        customers['cust_nour']!,
        products['prod_manteau_hiver']!,
        1,
        now.subtract(const Duration(days: 4)),
      ),
      _order(
        'ord_394',
        '#394',
        'CONFIRMED',
        customers['cust_yasmine']!,
        products['prod_sac_cuir_noir']!,
        2,
        now.subtract(const Duration(days: 5)),
      ),
    ];
    for (final order in orderData) {
      orders[order['id'] as String] = order;
    }

    activeGoal = {
      'id': 'goal_october',
      'kind': 'TRACKED',
      'goalType': 'REVENUE',
      'label': 'Objectif mensuel',
      'targetValue': 12000000,
      'currentValue': 8340000,
      'progressPercent': 69.5,
      'daysRemaining': 12,
      'dailyPaceRequired': 305000,
      'status': 'ACTIVE',
      'periodStart': DateTime(now.year, now.month, 1).toIso8601String(),
      'periodEnd': DateTime(now.year, now.month + 1, 0).toIso8601String(),
    };
  }

  static Map<String, dynamic> _product({
    required String id,
    required String name,
    required String imageUrl,
    required String category,
    required String sku,
    required int cost,
    required int price,
    required int stock,
    required int threshold,
    required DateTime createdAt,
    String? description,
    String? attributeName,
    String? attributeValue,
  }) {
    final variantId =
        'var_${id.substring(5)}_${attributeValue?.toLowerCase() ?? 'std'}';
    return {
      'id': id,
      'name': name,
      'description': description ?? '$name sélectionné par Boutique Sania.',
      'category': category,
      'categoryId': 'cat_${category.toLowerCase().replaceAll(' ', '_')}',
      'isBundle': false,
      'baseCostPrice': cost,
      'baseSellPrice': price,
      'isActive': true,
      'isMultiVariant': attributeName != null,
      'images': [
        {
          'id': 'image_$id',
          'url': imageUrl,
          'cloudinaryPublicId': 'demo_$id',
          'isPrimary': true,
          'displayOrder': 0,
          'altText': name,
        },
      ],
      'variants': [
        {
          'id': variantId,
          'sku': sku,
          'stockQuantity': stock,
          'availableQuantity': stock,
          'committedQuantity': 0,
          'backorderedQuantity': 0,
          'lowStockThreshold': threshold,
          'backorderEnabled': false,
          'effectiveCostPrice': cost,
          'effectiveSellPrice': price,
          'costPriceOverride': null,
          'sellPriceOverride': null,
          'imageId': null,
          'isActive': true,
          'updatedAt': DateTime.now().toIso8601String(),
          'attributes': attributeName == null
              ? <Map<String, dynamic>>[]
              : [
                  {
                    'name': attributeName,
                    'value': attributeValue,
                    'type': 'TEXT',
                  },
                ],
        },
      ],
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> _customer({
    required String id,
    required String name,
    required String phone,
    required String city,
    required String governorate,
    required int totalOrders,
    required int totalSpent,
    required String segment,
    required String rfm,
    required String risk,
    required List<String> tags,
    required DateTime now,
    String? riskReason,
    bool codEnabled = true,
    int codRefusalCount = 0,
  }) {
    final lastOrder = now.subtract(Duration(days: risk == 'RED' ? 48 : 4));
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': '24, rue des Jasmins',
      'city': city,
      'governorate': governorate,
      'notes': null,
      'tags': tags,
      'segment': segment,
      'defaultDiscountAmount': tags.contains('VIP') ? 10000 : 0,
      'defaultDiscountExpiresAt': null,
      'isBlocked': false,
      'blockReason': null,
      'blockedAt': null,
      'requirePrepayment': risk == 'RED',
      'birthday': DateTime(
        now.year - 28,
        now.month,
        now.day + 3,
      ).toIso8601String(),
      'preferredContactChannel': 'WHATSAPP',
      'codEnabled': codEnabled,
      'codRefusalCount': codRefusalCount,
      'riskLevel': risk,
      'riskReason': riskReason,
      'riskUpdatedAt': now.subtract(const Duration(days: 2)).toIso8601String(),
      'rfmSegment': rfm,
      'rfmUpdatedAt': now.subtract(const Duration(days: 1)).toIso8601String(),
      'createdAt': now
          .subtract(Duration(days: totalOrders * 42))
          .toIso8601String(),
      'stats': {
        'totalOrders': totalOrders,
        'totalSpent': totalSpent,
        'avgOrderValue': totalSpent ~/ totalOrders,
        'daysSinceLastOrder': now.difference(lastOrder).inDays,
        'hasHighReturnRate': risk == 'RED',
        'codAccepted': (totalOrders - codRefusalCount).clamp(0, totalOrders),
        'codTotal': totalOrders,
        'firstOrderDate': now
            .subtract(Duration(days: totalOrders * 42))
            .toIso8601String(),
        'lastOrderDate': lastOrder.toIso8601String(),
        'returnRate': risk == 'RED' ? 0.34 : 0.05,
        'avgDaysBetweenOrders': 24.0,
        'predictedNextOrderDate': lastOrder
            .add(const Duration(days: 24))
            .toIso8601String(),
      },
      'lastProducts': [
        {
          'productId': 'prod_sac_cuir_noir',
          'productName': 'Sac cuir noir',
          'lastOrderedAt': lastOrder.toIso8601String(),
          'inStock': true,
        },
      ],
      'totalOrders': totalOrders,
      'totalSpent': totalSpent,
      'lastOrderDate': lastOrder.toIso8601String(),
      'hasHighReturnRate': risk == 'RED',
    };
  }

  static Map<String, dynamic> _order(
    String id,
    String number,
    String status,
    Map<String, dynamic> customer,
    Map<String, dynamic> product,
    int quantity,
    DateTime createdAt, {
    String? rtoReason,
  }) {
    final unitPrice = product['baseSellPrice'] as int;
    final unitCost = product['baseCostPrice'] as int;
    final gross = unitPrice * quantity;
    const shipping = 8000;
    const adSpend = 5000;
    final profit = gross - unitCost * quantity - shipping - adSpend;
    final variant = (product['variants'] as List).first as Map<String, dynamic>;
    return {
      'id': id,
      'orderNumber': number,
      'status': status,
      'customer': {
        'id': customer['id'],
        'name': customer['name'],
        'phone': customer['phone'],
        'address': customer['address'],
        'city': customer['city'],
        'governorate': customer['governorate'],
      },
      'items': [
        {
          'id': 'item_$id',
          'productName': product['name'],
          'quantity': quantity,
          'unitPrice': unitPrice,
          'unitCost': unitCost,
          'subtotal': gross,
          'returnedQuantity': 0,
          'isBackorder': false,
          'fulfillmentStatus': status == 'SHIPPED' || status == 'DELIVERED'
              ? 'SHIPPED'
              : 'PENDING',
          'estimatedRestockDate': null,
          'variantId': variant['id'],
          'variantAttributes': {
            for (final attr in variant['attributes'] as List)
              (attr as Map<String, dynamic>)['name'] as String: attr['value'],
          },
          'primaryImageUrl':
              ((product['images'] as List).first
                  as Map<String, dynamic>)['url'],
        },
      ],
      'grossRevenue': gross,
      'discountAmount': 0,
      'netRevenue': gross,
      'totalCost': unitCost * quantity,
      'shippingCost': shipping,
      'adSpend': adSpend,
      'orderProfit': profit,
      'realProfit': profit,
      'profitBreakdown': {
        'salePrice': gross,
        'productCost': unitCost * quantity,
        'shippingCost': shipping,
        'discountApplied': 0,
        'exchangeCost': 0,
        'netProfit': profit,
        'marginPercent': gross == 0 ? 0.0 : profit * 100 / gross,
      },
      'notes': null,
      'adCampaignId': null,
      'rtoReason': rtoReason,
      'rtoReceivedAt': null,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': createdAt.toIso8601String(),
    };
  }
}
