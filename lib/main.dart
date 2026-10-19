import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/api/dio_client.dart';
import 'core/db/app_database.dart';
import 'core/deep_links/deep_link_provider.dart';
import 'core/observability/posthog_service.dart';
import 'core/observability/sentry_bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'router.dart';
import 'shared/providers/theme_provider.dart';

/// Set DIDO_DEV_RESET=true via --dart-define when you want every launch
/// to wipe secure storage + onboarding drafts. Defaults to false so
/// release/profile builds NEVER nuke real user state on cold start
/// (the previous behaviour signed users out on every relaunch — C1).
const _devReset =
    bool.fromEnvironment('DIDO_DEV_RESET', defaultValue: false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dev-only state reset. Active only when explicitly opted in via
  // --dart-define=DIDO_DEV_RESET=true AND the build is not release.
  // Skips silently otherwise.
  if (_devReset && !kReleaseMode) {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    await storage.deleteAll();

    final db = AppDatabase();
    await db.customStatement('DELETE FROM onboarding_drafts');
    await db.close();
  }

  await DioClient.getInstance();
  await PostHogService.initialize();

  await initSentryAndRunApp(() => const ProviderScope(child: DidoApp()));
}

class DidoApp extends ConsumerStatefulWidget {
  const DidoApp({super.key});

  @override
  ConsumerState<DidoApp> createState() => _DidoAppState();
}

class _DidoAppState extends ConsumerState<DidoApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deepLinkServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'DIDO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,

      // i18n — v1 locked to French; device locale ignored.
      // Adding Arabic/English in v1.x is a drop-in ARB file + unlock here.
      locale: const Locale('fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    );
  }
}