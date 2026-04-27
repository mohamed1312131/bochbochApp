import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/api/dio_client.dart';
import 'core/observability/sentry_bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'router.dart';
import 'shared/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DioClient.getInstance();

  await initSentryAndRunApp(() => const ProviderScope(child: DidoApp()));
}

class DidoApp extends ConsumerWidget {
  const DidoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'DIDO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}