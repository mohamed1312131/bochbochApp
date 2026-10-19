import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../../../shared/widgets/dido_card.dart';
import '../../../../shared/widgets/dido_toggle.dart';
import '../../domain/stock_models.dart';
import '../providers/stock_provider.dart';
import '../widgets/stock_quantity_stepper.dart';
import '../widgets/stock_settings_backorder_card.dart';

/// Stock & alertes — boutique-level stock settings.
class StockSettingsScreen extends ConsumerStatefulWidget {
  const StockSettingsScreen({super.key});

  @override
  ConsumerState<StockSettingsScreen> createState() =>
      _StockSettingsScreenState();
}

class _StockSettingsScreenState
    extends ConsumerState<StockSettingsScreen> {
  BoutiqueStockSettings? _settings;
  bool _saving = false;

  Future<void> _save() async {
    if (_settings == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(stockRepositoryProvider)
          .updateStockSettings(_settings!);
      ref.invalidate(stockSettingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paramètres enregistrés')),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur. Réessaye.')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final asyncSettings = ref.watch(stockSettingsProvider);

    return Scaffold(
      backgroundColor: c.surface0,
      appBar: AppBar(
        title: Text(
          'Stock & alertes',
          style: context.typography.h3.copyWith(color: c.fg1),
        ),
        backgroundColor: c.surface0,
        foregroundColor: c.fg1,
        elevation: 0,
      ),
      body: SafeArea(
        child: asyncSettings.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Impossible de charger les paramètres',
                style: context.typography.bodyMd.copyWith(color: c.redFg),
              ),
            ),
          ),
          data: (loaded) {
            _settings ??= loaded;
            final s = _settings!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionHeader(label: 'Seuils par défaut'),
                  const SizedBox(height: 8),
                  DidoCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                "Seuil d'alerte stock bas",
                                style: context.typography.bodyMd
                                    .copyWith(color: c.fg1),
                              ),
                            ),
                            const SizedBox(width: 12),
                            StockQuantityStepper(
                              value: s.defaultLowStockThreshold,
                              min: 1,
                              max: 99,
                              compact: true,
                              onChanged: (v) => setState(() => _settings =
                                  s.copyWith(defaultLowStockThreshold: v)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tu seras alerté(e) quand le stock disponible '
                          'tombe à ce niveau ou en dessous.',
                          style: context.typography.caption
                              .copyWith(color: c.fg3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  DidoCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                'Stock dormant — jours',
                                style: context.typography.bodyMd
                                    .copyWith(color: c.fg1),
                              ),
                            ),
                            const SizedBox(width: 12),
                            StockQuantityStepper(
                              value: s.dormantDays,
                              min: 7,
                              max: 365,
                              compact: true,
                              onChanged: (v) => setState(() => _settings =
                                  s.copyWith(dormantDays: v)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Un produit sans vente depuis ce nombre de '
                          'jours est considéré comme dormant.',
                          style: context.typography.caption
                              .copyWith(color: c.fg3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(label: 'Backorders par défaut'),
                  const SizedBox(height: 8),
                  StockSettingsBackorderCard(
                    title: 'Accepter backorders par défaut',
                    subtitle: 'Vendre même en rupture',
                    value: s.defaultBackorderEnabled,
                    onChanged: (v) => setState(() => _settings =
                        s.copyWith(defaultBackorderEnabled: v)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Quand activé, les nouveaux produits peuvent être "
                    "commandés même s'ils sont en rupture. Tu pourras "
                    "toujours désactiver par variant.",
                    style:
                        context.typography.caption.copyWith(color: c.fg3),
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(label: 'Notifications stock'),
                  const SizedBox(height: 8),
                  DidoCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _NotifRow(
                          title: 'Stock bas',
                          subtitle: 'Quand un variant atteint le seuil',
                          value: s.pushNotifLowStock,
                          onChanged: (v) => setState(() => _settings =
                              s.copyWith(pushNotifLowStock: v)),
                        ),
                        Container(height: 1, color: c.border1),
                        _NotifRow(
                          title: 'Rupture',
                          subtitle: 'Quand un variant tombe à 0',
                          value: s.pushNotifRupture,
                          onChanged: (v) => setState(() => _settings =
                              s.copyWith(pushNotifRupture: v)),
                        ),
                        Container(height: 1, color: c.border1),
                        _NotifRow(
                          title: 'Restock confirmé',
                          subtitle:
                              'Confirmation après chaque réapprovisionnement',
                          value: s.pushNotifRestockConfirmed,
                          onChanged: (v) => setState(() => _settings =
                              s.copyWith(pushNotifRestockConfirmed: v)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  DidoButton.primary(
                    label: 'Enregistrer',
                    fullWidth: true,
                    loading: _saving,
                    onPressed: _save,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Text(
      label.toUpperCase(),
      style: context.typography.label.copyWith(
        color: c.fg3,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _NotifRow extends StatelessWidget {
  const _NotifRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      context.typography.bodyMd.copyWith(color: c.fg1),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style:
                      context.typography.caption.copyWith(color: c.fg3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          DidoToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
