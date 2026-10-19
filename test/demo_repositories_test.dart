import 'package:flutter_test/flutter_test.dart';

import 'package:dido/demo/demo_repositories.dart';
import 'package:dido/demo/demo_store.dart';
import 'package:dido/features/customers/domain/customer_models.dart';
import 'package:dido/features/orders/domain/order_models.dart';

void main() {
  late DemoStore store;

  setUp(() {
    store = DemoStore();
  });

  test('seed scenario is coherent and parseable', () async {
    final products = await DemoProductRepository(store).getProducts();
    final orderRepository = DemoOrderRepository(store);
    final orders = await orderRepository.getOrders();
    final sampleOrder = await orderRepository.getOrder('ord_401');
    final customers = await DemoCustomerRepository(store).getCustomers();

    expect(products.data, hasLength(6));
    expect(
      products.data.map((product) => product.primaryImageUrl),
      everyElement(startsWith('https://images.pexels.com/')),
    );
    expect(products.data.where((p) => p.hasLowStock), isNotEmpty);
    expect(orders.data, hasLength(8));
    expect(
      sampleOrder.items.map((item) => item.primaryImageUrl),
      everyElement(startsWith('https://images.pexels.com/')),
    );
    expect(customers.data, hasLength(6));
    expect(customers.data.first.totalSpent, greaterThan(0));
  });

  test('product creation is kept in local demo state', () async {
    final repository = DemoProductRepository(store);
    final created = await repository.createProduct(
      name: 'Produit présentation',
      baseCostPrice: 20000,
      baseSellPrice: 49000,
      initialStock: 12,
    );

    expect(created.name, 'Produit présentation');
    expect(created.totalStock, 12);
    expect((await repository.getProducts()).data.first.id, created.id);
  });

  test('order status changes immediately without a backend', () async {
    final repository = DemoOrderRepository(store);

    await repository.updateStatus('ord_401', 'CONFIRMED');

    expect((await repository.getOrder('ord_401')).status, 'CONFIRMED');
  });

  test('new order appears in the demo list', () async {
    final products = DemoProductRepository(store);
    final product = await products.getProduct('prod_sac_cuir_noir');
    final repository = DemoOrderRepository(store);

    final created = await repository.createOrder(
      customerName: 'Salma Ben Amor',
      customerPhone: '+216 22 145 870',
      items: [
        OrderItemInput(
          productId: product.id,
          variantId: product.variants.first.id,
          quantity: 1,
          unitPrice: product.baseSellPrice,
          productName: product.name,
        ),
      ],
      shippingCost: 8000,
    );

    expect(created.status, 'PENDING');
    expect(
      created.items.single.primaryImageUrl,
      startsWith('https://images.pexels.com/photos/6538433/'),
    );
    expect((await repository.getOrders()).data.first.id, created.id);
  });

  test('customer risk and toggles mutate the shared scenario', () async {
    final repository = DemoCustomerRepository(store);

    await repository.updateRisk(
      'cust_imen',
      riskLevel: RiskLevel.red,
      riskReason: 'Validation de démonstration',
    );
    await repository.updateToggles(
      'cust_imen',
      requirePrepayment: true,
      codEnabled: false,
    );

    final customer = await repository.getCustomer('cust_imen');
    expect(customer.riskLevel, RiskLevel.red);
    expect(customer.requirePrepayment, isTrue);
    expect(customer.codEnabled, isFalse);
  });

  test('reset restores the curated initial scenario', () async {
    await DemoOrderRepository(store).deleteOrder('ord_401');
    expect(store.orders.containsKey('ord_401'), isFalse);

    store.reset();

    expect(store.orders.containsKey('ord_401'), isTrue);
    expect(store.products, hasLength(6));
  });
}
