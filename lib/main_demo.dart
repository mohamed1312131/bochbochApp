import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'demo/demo_providers.dart';
import 'demo/demo_repositories.dart';
import 'demo/demo_router.dart';
import 'features/boutiques/presentation/boutique_providers.dart';
import 'features/customers/presentation/providers/customer_provider.dart';
import 'features/goals/presentation/goal_providers.dart';
import 'features/orders/presentation/providers/order_provider.dart';
import 'features/products/presentation/providers/product_provider.dart';
import 'features/profit/presentation/providers/dashboard_provider.dart';
import 'features/profit/presentation/providers/profit_provider.dart';
import 'features/stock/data/mock_stock_repository.dart';
import 'features/stock/presentation/providers/stock_provider.dart';
import 'l10n/app_localizations.dart';
import 'shared/providers/theme_provider.dart';
import 'shared/providers/user_name_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        productRepositoryProvider.overrideWith(
          (ref) => DemoProductRepository(ref.read(demoStoreProvider)),
        ),
        orderRepositoryProvider.overrideWith(
          (ref) => DemoOrderRepository(ref.read(demoStoreProvider)),
        ),
        customerRepositoryProvider.overrideWith(
          (ref) => DemoCustomerRepository(ref.read(demoStoreProvider)),
        ),
        boutiqueRepositoryProvider.overrideWith(
          (ref) => DemoBoutiqueRepository(ref.read(demoStoreProvider)),
        ),
        goalRepositoryProvider.overrideWith(
          (ref) => DemoGoalRepository(ref.read(demoStoreProvider)),
        ),
        dashboardRepositoryProvider.overrideWith(
          (ref) => DemoDashboardRepository(ref.read(demoStoreProvider)),
        ),
        profitRepositoryProvider.overrideWith(
          (ref) => DemoProfitRepository(ref.read(demoStoreProvider)),
        ),
        stockRepositoryProvider.overrideWith((ref) => MockStockRepository()),
        userNameProvider.overrideWith((ref) async => 'Sania'),
      ],
      child: const DidoDemoApp(),
    ),
  );
}

class DidoDemoApp extends ConsumerStatefulWidget {
  const DidoDemoApp({super.key});

  @override
  ConsumerState<DidoDemoApp> createState() => _DidoDemoAppState();
}

class _DidoDemoAppState extends ConsumerState<DidoDemoApp> {
  late final _router = createDemoRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'DIDO — Démo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: _router,
      locale: const Locale('fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => ColoredBox(
        color: const Color(0xFFE9EEEF),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
