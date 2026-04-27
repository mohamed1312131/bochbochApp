import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'shared/providers/auth_state_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/verify_email_screen.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';
import 'features/auth/presentation/screens/verify_otp_screen.dart';
import 'features/auth/presentation/screens/new_password_screen.dart';
import 'features/profit/presentation/screens/home_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_typography.dart';
import 'core/constants/app_border_radius.dart';
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
import 'features/ai_studio/presentation/screens/ai_studio_hub_screen.dart';
import 'features/ai_studio/presentation/screens/create_post_screen.dart';
import 'features/ai_studio/presentation/screens/analysis_result_screen.dart';
import 'features/ai_studio/domain/ai_studio_models.dart';
import 'core/config/feature_flags.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/home',
    // Feed navigation breadcrumbs into Sentry. The bootstrap's
    // beforeBreadcrumb strips the `extra` payload (which carries OTP/email
    // for the password-reset flow) so we don't leak PII into events.
    observers: [SentryNavigatorObserver()],
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final isUnknown = authState.status == AuthStatus.unknown;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (isUnknown) return null;
      if (!isAuth && !isAuthRoute) return '/auth/login';
      if (isAuth && isAuthRoute) return '/home';
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

      // Full-screen AI Studio flow (no bottom nav)
      if (FeatureFlags.aiEnabled)
        GoRoute(
          path: '/ai-studio/create-post',
          name: 'create-post',
          builder: (_, __) => const CreatePostScreen(),
          routes: [
            GoRoute(
              path: 'result',
              name: 'analysis-result',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>;
                return AnalysisResultScreen(
                  result: extra['result'] as AiAnalysisResult,
                  photoUrls: List<String>.from(extra['photoUrls'] as List),
                  sessionId: extra['sessionId'] as String? ?? '',
                );
              },
            ),
          ],
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
            routes: [
              GoRoute(
                path: 'add',
                name: 'add-product',
                builder: (_, __) => const AddProductScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'product-detail',
                builder: (_, state) => ProductDetailScreen(
                  productId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'edit-product',
                    builder: (context, state) => EditProductScreen(
                      product: state.extra as Product,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder: (_, __) => const OrderListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'add-order',
                builder: (_, __) => const AddOrderScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'order-detail',
                builder: (_, state) => OrderDetailScreen(
                  orderId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          if (FeatureFlags.aiEnabled)
            GoRoute(
              path: '/ai-studio',
              name: 'ai-studio',
              builder: (_, __) => const AiStudioHubScreen(),
            ),
          GoRoute(
            path: '/customers',
            name: 'customers',
            builder: (_, __) => const CustomerListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'customer-detail',
                builder: (_, state) => CustomerDetailScreen(
                  customerId: state.pathParameters['id']!,
                ),
              ),
            ],
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

  int _locationToIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/orders')) return 1;
    if (location.startsWith('/products')) return 3;
    if (location.startsWith('/customers')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);

    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(
          top: BorderSide(color: context.appBorder, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () => context.go('/home'),
              ),
              _NavItem(
                icon: Icons.receipt_long_rounded,
                label: 'Orders',
                isActive: currentIndex == 1,
                onTap: () => context.go('/orders'),
              ),

              // Center + FAB
              if (FeatureFlags.aiEnabled)
                GestureDetector(
                  onTap: () => context.go('/ai-studio'),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x3305687B),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                )
              else
                const SizedBox(width: 52, height: 52),

              _NavItem(
                icon: Icons.grid_view_rounded,
                label: 'Products',
                isActive: currentIndex == 3,
                onTap: () => context.go('/products'),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Clients',
                isActive: currentIndex == 4,
                onTap: () => context.go('/customers'),
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
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? AppColors.brand : AppColors.textTertiary,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isActive ? AppColors.brand : AppColors.textTertiary,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}