import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_border_radius.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/i18n/l10n_context.dart';
import '../../../../features/boutiques/presentation/boutique_providers.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../../../shared/providers/theme_provider.dart';

// ── User info provider ─────────────────────────────────────
final _userInfoProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  return {
    'fullName': await storage.read(key: 'user_full_name') ?? 'User',
    'email': await storage.read(key: 'user_email') ?? '',
    'tier': await storage.read(key: 'user_subscription_tier') ?? 'TRIAL',
  };
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfoAsync = ref.watch(_userInfoProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.xl,
                  AppSpacing.screenHorizontal,
                  AppSpacing.xl,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.appSurfaceL2,
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: context.appTextPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      'Settings',
                      style: AppTypography.h2.copyWith(
                        color: context.appTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Profile Card ─────────────────────────
                  userInfoAsync.when(
                    loading: () => _SkeletonBox(height: 100),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (info) {
                      final fullName = info['fullName'] ?? 'User';
                      final email = info['email'] ?? '';
                      final tier = info['tier'] ?? 'TRIAL';
                      final initial = fullName.isNotEmpty
                          ? fullName[0].toUpperCase()
                          : 'U';

                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF05687B), Color(0xFF023D49)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF05687B)
                                  .withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: context.isDark ? Border.all(color: context.appBorder) : null,
                        ),
                        child: Row(
                          children: [
                            // Avatar — boutique logo (or initial-letter fallback)
                            _BoutiqueAvatar(initial: initial),
                            const SizedBox(width: AppSpacing.md),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName,
                                    style: AppTypography.h4.copyWith(
                                      color: AppColors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    email,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.white
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.white
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(
                                          AppRadius.full),
                                    ),
                                    child: Text(
                                      tier == 'PRO'
                                          ? '⭐ PRO'
                                          : '🕐 TRIAL',
                                      style: AppTypography.label.copyWith(
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Boutique ──────────────────────────────
                  _SectionLabel(label: 'Boutique'),
                  const SizedBox(height: AppSpacing.xs),
                  _SettingsCard(
                    children: [
                      _SettingsRow(
                        icon: Icons.store_outlined,
                        iconColor: context.appBrand,
                        label: 'Modifier ma boutique',
                        showChevron: true,
                        onTap: () => context.push('/boutiques/edit'),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Preferences ───────────────────────────
                  _SectionLabel(label: 'Preferences'),
                  const SizedBox(height: AppSpacing.xs),

                  _SettingsCard(
                    children: [
                      _SettingsRow(
                        icon: isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        iconColor: context.appBrand,
                        label: 'Dark Mode',
                        trailing: CupertinoSwitch(
                          value: isDark,
                          activeTrackColor: context.appBrand,
                          onChanged: (_) =>
                              ref.read(themeModeProvider.notifier).toggle(),
                        ),
                      ),
                      _Divider(),
                      // Language picker — only French active in v1; Arabic/English greyed.
                      // Activation in v1.x by adding ARB files + persisting choice.
                      _SettingsRow(
                        icon: Icons.language_rounded,
                        iconColor: AppColors.info,
                        label: 'Language',
                        trailing: Text(
                          context.l10n.settingsLanguageFrench,
                          style: AppTypography.body.copyWith(
                            color: context.appTextSecondary,
                          ),
                        ),
                        showChevron: true,
                        onTap: () => _showLanguagePicker(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // TODO Phase 3: wire notification preferences (replace this placeholder)

                  // ── Account ───────────────────────────────
                  _SectionLabel(label: 'Account'),
                  const SizedBox(height: AppSpacing.xs),

                  _SettingsCard(
                    children: [
                      // TODO Phase 12: wire Privacy Policy page
                      _SettingsRow(
                        icon: Icons.shield_outlined,
                        iconColor: AppColors.success,
                        label: 'Privacy Policy',
                        showChevron: true,
                        onTap: () => _showComingSoon(context),
                      ),
                      _Divider(),
                      // TODO Phase 12: wire Terms of Service page
                      _SettingsRow(
                        icon: Icons.description_outlined,
                        iconColor: AppColors.info,
                        label: 'Terms of Service',
                        showChevron: true,
                        onTap: () => _showComingSoon(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Logout ────────────────────────────────
                  _SettingsCard(
                    children: [
                      const _LogoutRow(),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Version
                  Center(
                    child: Text(
                      'DIDO v1.0.0',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Bientôt disponible')),
  );
}

void _showLanguagePicker(BuildContext context) {
  final l10n = context.l10n;
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              l10n.settingsLanguageTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          // French — active
          ListTile(
            leading: Icon(Icons.check_circle, color: context.appBrand),
            title: Text(l10n.settingsLanguageFrench),
            onTap: () => Navigator.of(sheetContext).pop(),
          ),
          // Arabic — coming soon
          ListTile(
            enabled: false,
            leading: const Icon(Icons.lock_outline, color: Colors.grey),
            title: Text(
              l10n.settingsLanguageArabic,
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: Text(
              l10n.settingsComingSoon,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            onTap: () {
              Navigator.of(sheetContext).pop();
              _showComingSoon(context);
            },
          ),
          // English — coming soon
          ListTile(
            enabled: false,
            leading: const Icon(Icons.lock_outline, color: Colors.grey),
            title: Text(
              l10n.settingsLanguageEnglish,
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: Text(
              l10n.settingsComingSoon,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            onTap: () {
              Navigator.of(sheetContext).pop();
              _showComingSoon(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

// ── Reusable components ────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.label.copyWith(
          color: AppColors.textTertiary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: context.appCardShadow,
        border: context.isDark ? Border.all(color: context.appBorder) : null,
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    this.iconColor = AppColors.brand,
    this.trailing,
    this.showChevron = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.body.copyWith(
                  color: context.appTextPrimary,
                ),
              ),
            ),
            if (trailing != null) trailing!,
            if (showChevron) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: context.appTextTertiary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 68),
      child: Divider(height: 1, color: AppColors.border),
    );
  }
}

class _LogoutRow extends ConsumerWidget {
  const _LogoutRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            title: Text('Logout', style: AppTypography.h4),
            content: Text(
              'Are you sure you want to logout?',
              style: AppTypography.body.copyWith(
                color: context.appTextSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: AppTypography.body.copyWith(
                    color: context.appTextSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Logout',
                  style: AppTypography.body.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          await ref.read(authStateProvider.notifier).logout();
          if (context.mounted) context.go('/auth/login');
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                Icons.logout_rounded,
                size: 18,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              'Logout',
              style: AppTypography.body.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceL1,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    );
  }
}
class _BoutiqueAvatar extends ConsumerWidget {
  const _BoutiqueAvatar({required this.initial});
  final String initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boutique = ref.watch(currentBoutiqueProvider).valueOrNull;
    final logoUrl = boutique?.logoUrl;

    final fallback = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: context.appSurface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: context.appSurface.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: AppTypography.h2.copyWith(color: AppColors.white),
        ),
      ),
    );

    if (logoUrl == null || logoUrl.isEmpty) return fallback;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: context.appSurface.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: CachedNetworkImage(
          imageUrl: logoUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) => const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.white,
              ),
            ),
          ),
          errorWidget: (_, __, ___) => fallback,
        ),
      ),
    );
  }
}
