import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme_extension.dart';
import '../features/boutiques/presentation/screens/edit_boutique_screen.dart';
import '../features/customers/presentation/screens/customer_detail_screen.dart';
import '../features/customers/presentation/screens/customer_edit_screen.dart';
import '../features/customers/presentation/screens/customer_list_screen.dart';
import '../features/orders/presentation/screens/add_order_screen.dart';
import '../features/orders/presentation/screens/order_detail_screen.dart';
import '../features/orders/presentation/screens/order_list_screen.dart';
import '../features/products/domain/product_models.dart';
import '../features/products/presentation/screens/add_product_screen.dart';
import '../features/products/presentation/screens/edit_product_screen.dart';
import '../features/products/presentation/screens/product_detail_screen.dart';
import '../features/products/presentation/screens/product_list_screen.dart';
import '../features/profit/presentation/screens/home_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/stats/presentation/screens/stats_screen.dart';
import '../features/stock/presentation/screens/categories_management_screen.dart';
import '../features/stock/presentation/screens/dead_stock_list_screen.dart';
import '../features/stock/presentation/screens/low_stock_list_screen.dart';
import '../features/stock/presentation/screens/shrinkage_screen.dart';
import '../features/stock/presentation/screens/stock_settings_screen.dart';

GoRouter createDemoRouter() => GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (_, __) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/settings/stock',
      name: 'settings-stock',
      builder: (_, __) => const StockSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/categories',
      name: 'settings-categories',
      builder: (_, __) => const CategoriesManagementScreen(),
    ),
    GoRoute(
      path: '/boutiques/edit',
      name: 'boutique-edit',
      builder: (_, __) => const EditBoutiqueScreen(),
    ),
    GoRoute(
      path: '/stock/low',
      name: 'stock-low',
      builder: (_, __) => const LowStockListScreen(),
    ),
    GoRoute(
      path: '/stock/dead',
      name: 'stock-dead',
      builder: (_, __) => const DeadStockListScreen(),
    ),
    GoRoute(
      path: '/stock/shrinkage',
      name: 'stock-shrinkage',
      builder: (_, state) => ShrinkageScreen(
        initialTab: int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0,
      ),
    ),
    GoRoute(
      path: '/orders/add',
      name: 'add-order',
      builder: (_, __) => const AddOrderScreen(),
    ),
    GoRoute(
      path: '/orders/:id',
      name: 'order-detail',
      builder: (_, state) =>
          OrderDetailScreen(orderId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/products/add',
      name: 'add-product',
      builder: (_, __) => const AddProductScreen(),
    ),
    GoRoute(
      path: '/products/:id',
      name: 'product-detail',
      builder: (_, state) =>
          ProductDetailScreen(productId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/products/:id/edit',
      name: 'product-edit',
      builder: (_, state) => EditProductScreen(product: state.extra as Product),
    ),
    GoRoute(
      path: '/customers/:id',
      name: 'customer-detail',
      builder: (_, state) =>
          CustomerDetailScreen(customerId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/customers/:id/edit',
      name: 'customer-edit',
      builder: (_, state) =>
          CustomerEditScreen(customerId: state.pathParameters['id']!),
    ),
    ShellRoute(
      builder: (_, __, child) => _DemoShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (_, __) => const HomeScreen(),
        ),
        GoRoute(
          path: '/orders',
          name: 'orders',
          builder: (_, __) => const OrderListScreen(),
        ),
        GoRoute(
          path: '/products',
          name: 'products',
          builder: (_, __) => const ProductListScreen(),
        ),
        GoRoute(
          path: '/customers',
          name: 'customers',
          builder: (_, __) => const CustomerListScreen(),
        ),
        GoRoute(
          path: '/stats',
          name: 'stats',
          builder: (_, __) => const StatsScreen(),
        ),
      ],
    ),
  ],
);

class _DemoShell extends StatelessWidget {
  const _DemoShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: child, bottomNavigationBar: const _DemoBottomNav());
}

class _DemoBottomNav extends StatelessWidget {
  const _DemoBottomNav();

  int _indexFor(String location) {
    if (location.startsWith('/orders')) return 1;
    if (location.startsWith('/products')) return 2;
    if (location.startsWith('/customers')) return 3;
    if (location.startsWith('/stats')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final currentIndex = _indexFor(GoRouterState.of(context).matchedLocation);
    return Container(
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border(top: BorderSide(color: c.border1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Accueil',
                active: currentIndex == 0,
                onTap: () => context.go('/home'),
              ),
              _NavItem(
                icon: Icons.receipt_long_rounded,
                label: 'Commandes',
                active: currentIndex == 1,
                onTap: () => context.go('/orders'),
              ),
              _NavItem(
                icon: Icons.grid_view_rounded,
                label: 'Produits',
                active: currentIndex == 2,
                onTap: () => context.go('/products'),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Clients',
                active: currentIndex == 3,
                onTap: () => context.go('/customers'),
              ),
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Stats',
                active: currentIndex == 4,
                onTap: () => context.go('/stats'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = active ? c.fg1 : c.fg3;
    return Expanded(
      child: InkResponse(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            SizedBox(height: context.spacing.space1),
            Text(
              label,
              style: context.typography.tabPill.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
