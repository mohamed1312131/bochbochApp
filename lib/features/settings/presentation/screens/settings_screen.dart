import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/demo_mode.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../demo/demo_providers.dart';
import '../../../../features/boutiques/presentation/boutique_providers.dart';
import '../../../../features/customers/presentation/providers/customer_provider.dart';
import '../../../../features/goals/presentation/goal_providers.dart';
import '../../../../features/orders/presentation/providers/order_provider.dart';
import '../../../../features/products/presentation/providers/product_provider.dart';
import '../../../../features/profit/presentation/providers/dashboard_provider.dart';
import '../../../../features/profit/presentation/providers/profit_provider.dart';
import '../../../../features/stock/presentation/providers/stock_provider.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../../../shared/providers/package_info_provider.dart';
import '../../../../shared/providers/theme_provider.dart';

final _userInfoProvider = FutureProvider.autoDispose<Map<String, String>>((
  ref,
) async {
  if (kDidoDemoMode) {
    return const {
      'fullName': 'Sania Ben Salah',
      'email': 'sania@boutiquesania.tn',
      'tier': 'DEMO PRO',
    };
  }
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
    final c = context.colors;
    final userInfoAsync = ref.watch(_userInfoProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor: c.surface0,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _Header()),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                context.spacing.space4,
                0,
                context.spacing.space4,
                context.spacing.space6,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  userInfoAsync.when(
                    loading: () => _SkeletonBox(height: 96),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (info) => _IdentityCard(
                      fullName: info['fullName'] ?? 'User',
                      email: info['email'] ?? '',
                      tier: info['tier'] ?? 'TRIAL',
                    ),
                  ),
                  SizedBox(height: context.spacing.space6),
                  const _SectionLabel('BOUTIQUE'),
                  _SettingsCard(
                    children: [
                      _SettingsRow(
                        icon: Icons.store_outlined,
                        label: 'Modifier ma boutique',
                        showChevron: true,
                        onTap: () => context.push('/boutiques/edit'),
                      ),
                    ],
                  ),
                  SizedBox(height: context.spacing.space6),
                  const _SectionLabel('STOCK'),
                  _SettingsCard(
                    children: [
                      _SettingsRow(
                        icon: Icons.inventory_2_outlined,
                        label: 'Stock & alertes',
                        showChevron: true,
                        onTap: () => context.push('/settings/stock'),
                      ),
                      const _Divider(),
                      _SettingsRow(
                        icon: Icons.category_outlined,
                        label: 'Catégories',
                        showChevron: true,
                        onTap: () => context.push('/settings/categories'),
                      ),
                    ],
                  ),
                  SizedBox(height: context.spacing.space6),
                  const _SectionLabel('PRÉFÉRENCES'),
                  _SettingsCard(
                    children: [
                      _SettingsRow(
                        icon: Icons.dark_mode_outlined,
                        label: 'Mode sombre',
                        trailing: CupertinoSwitch(
                          value: isDark,
                          activeTrackColor: c.fg1,
                          onChanged: (_) =>
                              ref.read(themeModeProvider.notifier).toggle(),
                        ),
                        onTap: () =>
                            ref.read(themeModeProvider.notifier).toggle(),
                      ),
                    ],
                  ),
                  // Privacy + Terms rows hidden until hosted URLs are
                  // wired (H22). Replace this comment with a
                  // _SettingsCard containing the two rows once
                  // PRIVACY_URL / TERMS_URL are added to dart_defines
                  // and a url_launcher dep is wired up. Shipping
                  // "Bientôt disponible" snackbars is a fast track to
                  // app-store rejection.
                  SizedBox(height: context.spacing.space6),
                  if (kDidoDemoMode) ...[
                    const _SectionLabel('MODE DÉMO'),
                    const _SettingsCard(children: [_DemoResetRow()]),
                  ] else
                    const _SettingsCard(children: [_LogoutRow()]),
                  SizedBox(height: context.spacing.space6),
                  const _VersionString(),
                  SizedBox(height: context.spacing.space6),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Header
// ════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.spacing.space4,
        context.spacing.space3,
        context.spacing.space4,
        context.spacing.space3,
      ),
      child: Row(
        children: [
          _ScaleTap(
            pressedScale: 0.92,
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.surface2,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: c.fg1,
              ),
            ),
          ),
          SizedBox(width: context.spacing.space3),
          Text('Réglages', style: context.typography.h1.copyWith(color: c.fg1)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Identity card
// ════════════════════════════════════════════════════════════
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.fullName,
    required this.email,
    required this.tier,
  });

  final String fullName;
  final String email;
  final String tier;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: EdgeInsets.all(context.spacing.space4),
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Row(
        children: [
          _BoutiqueAvatar(initial: _initialOf(fullName)),
          SizedBox(width: context.spacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typography.h4.copyWith(color: c.fg1),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.typography.bodySmall.copyWith(color: c.fg3),
                  ),
                ],
                SizedBox(height: context.spacing.space2),
                _TierChip(tier: tier),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initialOf(String name) =>
      name.isNotEmpty ? name[0].toUpperCase() : 'U';
}

class _TierChip extends StatelessWidget {
  const _TierChip({required this.tier});
  final String tier;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(context.radius.radiusChip),
      ),
      child: Text(
        tier == 'PRO' ? 'Pro' : 'Essai',
        style: context.typography.tabPill.copyWith(
          color: c.fg2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BoutiqueAvatar extends ConsumerWidget {
  const _BoutiqueAvatar({required this.initial});
  final String initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final boutique = ref.watch(currentBoutiqueProvider).valueOrNull;
    final logoUrl = boutique?.logoUrl;

    final fallback = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(color: c.brandTeal, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: context.typography.h2.copyWith(
          color: c.surface0,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (logoUrl == null || logoUrl.isEmpty) return fallback;

    return ClipOval(
      child: SizedBox(
        width: 64,
        height: 64,
        child: CachedNetworkImage(
          imageUrl: logoUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) => fallback,
          errorWidget: (_, __, ___) => fallback,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Section label + card + row
// ════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.spacing.space2,
        0,
        context.spacing.space2,
        context.spacing.space2,
      ),
      child: Text(
        label.toUpperCase(),
        style: context.typography.label.copyWith(
          color: context.colors.fg3,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
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
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.showChevron = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ScaleTap(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.space4,
          vertical: context.spacing.space3,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(context.radius.radiusInput),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: c.fg2),
            ),
            SizedBox(width: context.spacing.space3),
            Expanded(
              child: Text(
                label,
                style: context.typography.bodyMd.copyWith(color: c.fg1),
              ),
            ),
            if (trailing != null) ...[
              trailing!,
              SizedBox(width: context.spacing.space2),
            ],
            if (showChevron)
              Icon(Icons.chevron_right_rounded, size: 20, color: c.fg3),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 68),
      color: context.colors.border1,
    );
  }
}

// ════════════════════════════════════════════════════════════
// Logout
// ════════════════════════════════════════════════════════════
class _LogoutRow extends ConsumerWidget {
  const _LogoutRow();

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final c = context.colors;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Annuler',
              style: context.typography.bodyMd.copyWith(color: c.fg2),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Déconnexion',
              style: context.typography.bodyMd.copyWith(
                color: c.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    await ref.read(authStateProvider.notifier).logout();
    if (context.mounted) context.go('/auth/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return _ScaleTap(
      onTap: () => _confirm(context, ref),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.space4,
          vertical: context.spacing.space3,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c.coralTint12,
                borderRadius: BorderRadius.circular(context.radius.radiusInput),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.logout_rounded, size: 18, color: c.coralFg),
            ),
            SizedBox(width: context.spacing.space3),
            Text(
              'Déconnexion',
              style: context.typography.bodyMd.copyWith(
                color: c.coralFg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoResetRow extends ConsumerWidget {
  const _DemoResetRow();

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Réinitialiser la démo'),
        content: const Text(
          'Toutes les modifications locales seront remplacées par le scénario de présentation initial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    ref.read(demoStoreProvider).reset();
    ref.invalidate(productListProvider);
    ref.invalidate(orderListProvider);
    ref.invalidate(customerListProvider);
    ref.invalidate(currentBoutiqueProvider);
    ref.invalidate(activeGoalProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(profitSummaryProvider);
    ref.invalidate(productProfitProvider);
    ref.invalidate(profitTrendProvider);
    ref.invalidate(stockRepositoryProvider);

    if (context.mounted) {
      context.go('/home');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La démo a été réinitialisée.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return _ScaleTap(
      onTap: () => _reset(context, ref),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.space4,
          vertical: context.spacing.space3,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c.brandTealTint08,
                borderRadius: BorderRadius.circular(context.radius.radiusInput),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.restart_alt_rounded,
                size: 20,
                color: c.brandTeal,
              ),
            ),
            SizedBox(width: context.spacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Réinitialiser les données',
                    style: context.typography.bodyMd.copyWith(
                      color: c.fg1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Restaurer le scénario de présentation',
                    style: context.typography.caption.copyWith(color: c.fg3),
                  ),
                ],
              ),
            ),
            Icon(Icons.refresh_rounded, color: c.fg3),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Version + skeleton
// ════════════════════════════════════════════════════════════
class _VersionString extends ConsumerWidget {
  const _VersionString();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final info = ref.watch(packageInfoProvider);
    return Center(
      child: info.when(
        loading: () => const SizedBox(height: 18),
        error: (_, __) => Text(
          'DIDO',
          style: context.typography.bodySmall.copyWith(color: c.fg3),
        ),
        data: (pkg) => Text(
          'DIDO v${pkg.version}',
          style: context.typography.bodySmall.copyWith(color: c.fg3),
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
    final c = context.colors;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Tap feedback (TODO(extract))
// ════════════════════════════════════════════════════════════
class _ScaleTap extends StatefulWidget {
  const _ScaleTap({
    required this.child,
    required this.onTap,
    this.pressedScale = 0.98,
  });
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap> {
  bool _pressed = false;
  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null
          ? null
          : (_) {
              _set(true);
              HapticFeedback.lightImpact();
            },
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              _set(false);
              widget.onTap!();
            },
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: context.motion.tap,
        curve: context.motion.easeOut,
        child: widget.child,
      ),
    );
  }
}
