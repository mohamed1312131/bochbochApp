import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/french_plural.dart';
import '../../../../shared/widgets/dido_bottom_sheet.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../../../shared/widgets/dido_card.dart';
import '../../../../shared/widgets/dido_dropdown.dart';
import '../../../../shared/widgets/dido_input.dart';
import '../../../../shared/widgets/dido_scale_tap.dart';
import '../../domain/stock_inputs.dart';
import '../../domain/stock_models.dart';
import '../providers/stock_provider.dart';

/// Catégories — list + create/edit/delete categories.
class CategoriesManagementScreen extends ConsumerStatefulWidget {
  const CategoriesManagementScreen({super.key});

  @override
  ConsumerState<CategoriesManagementScreen> createState() =>
      _CategoriesManagementScreenState();
}

class _CategoriesManagementScreenState
    extends ConsumerState<CategoriesManagementScreen> {
  Future<void> _showCreateModal() => _showEditModal();

  Future<void> _showEditModal({Category? existing}) async {
    final isEdit = existing != null;
    await showDidoBottomSheet<void>(
      context: context,
      title: isEdit ? 'Modifier la catégorie' : 'Nouvelle catégorie',
      child: _CategoryForm(
        initialName: existing?.name ?? '',
        confirmLabel: isEdit ? 'Enregistrer' : 'Créer',
        onConfirm: (name) async {
          if (name.isEmpty) return;
          final repo = ref.read(stockRepositoryProvider);
          if (isEdit) {
            await repo.updateCategory(existing.id, CategoryInput(name: name));
          } else {
            await repo.createCategory(CategoryInput(name: name));
          }
          ref.invalidate(categoriesProvider);
          if (mounted) Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _confirmDelete(Category category) async {
    final c = context.colors;
    final categories = ref.read(categoriesProvider).valueOrNull ?? const [];
    final others =
        categories.where((cat) => cat.id != category.id).toList();
    String? moveTargetId;
    if (category.productCount > 0 && others.isNotEmpty) {
      moveTargetId = others.first.id;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setLocal) => AlertDialog(
          backgroundColor: c.surface1,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(context.radius.radiusSheet),
          ),
          title: Text(
            'Supprimer ${category.name} ?',
            style: context.typography.h4.copyWith(color: c.fg1),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cette catégorie sera supprimée.',
                style: context.typography.bodyMd.copyWith(color: c.fg2),
              ),
              if (category.productCount > 0 && others.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '${frenchPlural(category.productCount, 'produit', 'produits')} '
                  'utiliseront la catégorie que tu choisis ci-dessous :',
                  style: context.typography.caption.copyWith(color: c.fg3),
                ),
                const SizedBox(height: 8),
                DidoDropdown<String>(
                  value: moveTargetId,
                  hint: 'Choisir une catégorie',
                  sheetTitle: 'Déplacer vers',
                  items: [
                    for (final cat in others)
                      DidoDropdownItem(value: cat.id, label: cat.name),
                  ],
                  onChanged: (v) => setLocal(() => moveTargetId = v),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text(
                'Annuler',
                style:
                    context.typography.button.copyWith(color: c.fg2),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: Text(
                category.productCount > 0 && others.isNotEmpty
                    ? 'Supprimer et déplacer'
                    : 'Supprimer',
                style:
                    context.typography.button.copyWith(color: c.coralFg),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm != true || !mounted) return;
    try {
      await ref.read(stockRepositoryProvider).deleteCategory(
            category.id,
            moveProductsToId: moveTargetId,
          );
      ref.invalidate(categoriesProvider);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur. Réessaye.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final asyncList = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: c.surface0,
      appBar: AppBar(
        title: Text(
          'Catégories',
          style: context.typography.h3.copyWith(color: c.fg1),
        ),
        backgroundColor: c.surface0,
        foregroundColor: c.fg1,
        elevation: 0,
      ),
      body: SafeArea(
        child: asyncList.when(
          loading: () => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, __) => Container(
              height: 56,
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius:
                    BorderRadius.circular(context.radius.radiusCard),
              ),
            ),
          ),
          error: (_, __) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 48, color: c.fg3),
                  const SizedBox(height: 12),
                  Text(
                    'Impossible de charger',
                    style: context.typography.h4.copyWith(color: c.fg1),
                  ),
                  const SizedBox(height: 16),
                  DidoButton.secondary(
                    label: 'Réessayer',
                    fullWidth: false,
                    onPressed: () =>
                        ref.invalidate(categoriesProvider),
                  ),
                ],
              ),
            ),
          ),
          data: (categories) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (categories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_off_outlined,
                              size: 48, color: c.fg3),
                          const SizedBox(height: 12),
                          Text(
                            'Aucune catégorie',
                            style:
                                context.typography.h4.copyWith(color: c.fg1),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Crée une catégorie pour organiser tes produits.',
                            textAlign: TextAlign.center,
                            style: context.typography.body
                                .copyWith(color: c.fg3),
                          ),
                          const SizedBox(height: 16),
                          DidoButton.primary(
                            label: 'Nouvelle catégorie',
                            fullWidth: false,
                            onPressed: _showCreateModal,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  for (var i = 0; i < categories.length; i++) ...[
                    _CategoryRow(
                      category: categories[i],
                      onEdit: () =>
                          _showEditModal(existing: categories[i]),
                      onDelete: () => _confirmDelete(categories[i]),
                    ),
                    if (i < categories.length - 1)
                      const SizedBox(height: 8),
                  ],
                const SizedBox(height: 24),
                DidoButton.secondary(
                  label: 'Nouvelle catégorie',
                  icon: Icons.add_rounded,
                  fullWidth: true,
                  onPressed: _showCreateModal,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DidoCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: context.typography.bodyMd.copyWith(color: c.fg1),
                ),
                const SizedBox(height: 2),
                Text(
                  '${category.productCount} produits',
                  style: context.typography.caption.copyWith(color: c.fg3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _IconButton(icon: Icons.edit_outlined, onTap: onEdit),
          const SizedBox(width: 8),
          _IconButton(
            icon: Icons.delete_outline_rounded,
            iconColor: c.coralFg,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap, this.iconColor});

  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DidoScaleTap(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(context.radius.radiusInput),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: iconColor ?? c.fg2),
      ),
    );
  }
}

class _CategoryForm extends StatefulWidget {
  const _CategoryForm({
    required this.initialName,
    required this.confirmLabel,
    required this.onConfirm,
  });

  final String initialName;
  final String confirmLabel;
  final Future<void> Function(String name) onConfirm;

  @override
  State<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<_CategoryForm> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DidoInput(
          controller: _ctrl,
          label: 'NOM',
          hintText: 'Robes, Sacs, ...',
          autofocus: true,
        ),
        const SizedBox(height: 16),
        DidoButton.primary(
          label: widget.confirmLabel,
          fullWidth: true,
          onPressed: () => widget.onConfirm(_ctrl.text.trim()),
        ),
        const SizedBox(height: 8),
        DidoButton.secondary(
          label: 'Annuler',
          fullWidth: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
