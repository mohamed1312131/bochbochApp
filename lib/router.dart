import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'shared/providers/auth_state_provider.dart';
import 'features/boutiques/presentation/boutique_providers.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/onboarding/presentation/screens/onboarding_success_screen.dart';
import 'features/boutiques/presentation/screens/edit_boutique_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/verify_email_screen.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';
import 'features/auth/presentation/screens/verify_otp_screen.dart';
import 'features/auth/presentation/screens/new_password_screen.dart';
import 'features/profit/presentation/screens/home_screen.dart';
import 'features/stats/presentation/screens/stats_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'core/theme/app_theme_extension.dart';
import 'features/products/presentation/screens/product_list_screen.dart';
import 'features/products/presentation/screens/add_product_screen.dart';
import 'features/products/presentation/screens/product_detail_screen.dart';
import 'features/products/presentation/screens/edit_product_screen.dart';
import 'features/products/domain/product_models.dart';
import 'features/orders/presentation/screens/order_list_screen.dart';
import 'features/orders/presentation/screens/add_order_screen.dart';
import 'features/orders/presentation/screens/order_detail_screen.dart';
import 'features/customers/presentation/screens/customer_list_screen.dart';
import 'features/customers/presentation/screens/customer_detail_screen.dart';
import 'features/customers/presentation/screens/customer_edit_screen.dart';
import 'features/stock/presentation/screens/categories_management_screen.dart';
import 'features/stock/presentation/screens/dead_stock_list_screen.dart';
import 'features/stock/presentation/screens/low_stock_list_screen.dart';
import 'features/stock/presentation/screens/shrinkage_screen.dart';
import 'features/stock/presentation/screens/stock_settings_screen.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Build GoRouter ONCE. Use a ValueNotifier as refreshListenable so
  // redirect re-runs reactively to auth/boutique changes without
  // recreating the router (which would reset navigation to
  // initialLocation and yank users off in-flight screens).
  final notifier = ValueNotifier(0);
  ref.onDispose(notifier.dispose);
  ref.listen(authStateProvider, (_, __) => notifier.value++);
  ref.listen(currentBoutiqueProvider, (_, __) => notifier.value++);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: notifier,
    // Feed navigation breadcrumbs into Sentry. The bootstrap's
    // beforeBreadcrumb strips the `extra` payload (which carries OTP/email
    // for the password-reset flow) so we don't leak PII into events.
    observers: [SentryNavigatorObserver()],
    redirect: (context, state) {
      // ref.read inside redirect — we're no longer watching at the
      // provider level. refreshListenable ticks force redirect to re-run.
      final authState = ref.read(authStateProvider);
      final boutiqueAsync = ref.read(currentBoutiqueProvider);
      final isAuth = authState.isAuthenticated;
      final isUnknown = authState.status == AuthStatus.unknown;
      final loc = state.matchedLocation;

      if (isUnknown) return null;

      final isAuthRoute = loc.startsWith('/auth');

      if (!isAuth && !isAuthRoute) return '/auth/login';
      if (isAuth && isAuthRoute) return '/home';

      // While boutique is loading, hold authenticated users on /loading
      // so we can redirect correctly once data arrives. Without this,
      // the redirect fires with valueOrNull == null and the user lands
      // on /home before the onboarding gate has a chance to fire.
      if (isAuth && !isAuthRoute) {
        // Only mask /home behind /loading on cold start. Don't kick users
        // off in-flight screens (like /onboarding) when their action
        // invalidates currentBoutiqueProvider mid-flow.
        if (boutiqueAsync.isLoading && (loc == '/home' || loc == '/loading')) {
          return loc == '/loading' ? null : '/loading';
        }
        if (boutiqueAsync.hasError && loc == '/home') {
          return '/onboarding';
        }
      }

      // Soft-gate model: authenticated users can freely visit /home and
      // /onboarding. Home shows a "Configure ta boutique" CTA when the
      // boutique isn't onboarded yet. The boutique watch is still needed
      // to know when to release users from /loading.
      final boutique = boutiqueAsync.valueOrNull;
      if (isAuth && loc == '/loading' && boutique != null) {
        return '/home';
      }
      return null;
    },
    routes: [
      // Auth
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        name: 'register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/verify-email',
        name: 'verify-email',
        builder: (_, __) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        name: 'forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/verify-otp',
        name: 'verify-otp',
        builder: (context, state) => VerifyOtpScreen(
          email: state.extra as String? ?? '',
        ),
      ),
      GoRoute(
        path: '/auth/new-password',
        name: 'new-password',
        builder: (context, state) {
          final extra = state.extra as Map<String, String>? ?? {};
          return NewPasswordScreen(
            email: extra['email'] ?? '',
            otp: extra['otp'] ?? '',
          );
        },
      ),

      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (_, __) => const SettingsScreen(),
      ),

      // Loading placeholder while boutique data resolves post-login.
      GoRoute(
        path: '/loading',
        name: 'loading',
        builder: (_, __) => const Scaffold(
          backgroundColor: Colors.white,
          body: Center(child: CircularProgressIndicator()),
        ),
      ),

      // Onboarding (Stage 5E)
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/onboarding/success',
        name: 'onboarding-success',
        builder: (_, __) => const OnboardingSuccessScreen(),
      ),

      // Stock module sub-screens (chunk 6)
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
          initialTab: int.tryParse(
                  state.uri.queryParameters['tab'] ?? '0') ??
              0,
        ),
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

      // Boutique edit (Stage 5F)
      GoRoute(
        path: '/boutiques/edit',
        name: 'boutique-edit',
        builder: (_, __) => const EditBoutiqueScreen(),
      ),

      // Full-screen Add Order flow (no bottom nav)
      GoRoute(
        path: '/orders/add',
        name: 'add-order',
        builder: (_, __) => const AddOrderScreen(),
      ),

      // Full-screen Products flows (no bottom nav)
      GoRoute(
        path: '/products/add',
        name: 'add-product',
        builder: (_, __) => const AddProductScreen(),
      ),
      GoRoute(
        path: '/products/:id',
        name: 'product-detail',
        builder: (_, state) => ProductDetailScreen(
          productId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/products/:id/edit',
        name: 'product-edit',
        builder: (_, state) => EditProductScreen(
          product: state.extra as Product,
        ),
      ),

      // Full-screen Order detail (no bottom nav)
      GoRoute(
        path: '/orders/:id',
        name: 'order-detail',
        builder: (_, state) => OrderDetailScreen(
          orderId: state.pathParameters['id']!,
        ),
      ),

      // Full-screen Customers flows (no bottom nav)
      GoRoute(
        path: '/customers/:id',
        name: 'customer-detail',
        builder: (_, state) => CustomerDetailScreen(
          customerId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/customers/:id/edit',
        name: 'customer-edit',
        builder: (_, state) => CustomerEditScreen(
          customerId: state.pathParameters['id']!,
        ),
      ),

      // Main shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => _MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/products',
            name: 'products',
            builder: (_, __) => const ProductListScreen(),
          ),
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder: (_, __) => const OrderListScreen(),
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
});

class _MainShell extends StatelessWidget {
  const _MainShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const _DidoBottomNav(),
    );
  }
}

class _DidoBottomNav extends StatelessWidget {
  const _DidoBottomNav();

  int _locationToIndex(String loc) {
    if (loc.startsWith('/home')) return 0;
    if (loc.startsWith('/orders')) return 1;
    if (loc.startsWith('/products')) return 2;
    if (loc.startsWith('/customers')) return 3;
    if (loc.startsWith('/stats')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);

    return Container(
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border(top: BorderSide(color: c.border1, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Accueil',
                  isActive: currentIndex == 0,
                  onTap: () => context.go('/home'),
                ),
                _NavItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'Commandes',
                  isActive: currentIndex == 1,
                  onTap: () => context.go('/orders'),
                ),
                _NavItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Produits',
                  isActive: currentIndex == 2,
                  onTap: () => context.go('/products'),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Clients',
                  isActive: currentIndex == 3,
                  onTap: () => context.go('/customers'),
                ),
                _NavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Stats',
                  isActive: currentIndex == 4,
                  onTap: () => context.go('/stats'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = widget.isActive ? c.fg1 : c.fg3;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          setState(() => _pressed = true);
          HapticFeedback.lightImpact();
        },
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedOpacity(
          opacity: _pressed ? 0.6 : 1.0,
          duration: context.motion.tap,
          curve: context.motion.easeOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 22, color: color),
              SizedBox(height: context.spacing.space1),
              Text(
                widget.label,
                style: context.typography.tabPill.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}