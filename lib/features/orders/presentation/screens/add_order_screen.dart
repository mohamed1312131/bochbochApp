import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../../../../shared/widgets/dido_attention_strip.dart';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../../domain/order_models.dart';
import '../providers/order_provider.dart';
import '../sheets/product_picker_sheet.dart';

class AddOrderScreen extends ConsumerStatefulWidget {
  const AddOrderScreen({super.key});

  @override
  ConsumerState<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends ConsumerState<AddOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _shippingController = TextEditingController();
  final _discountController = TextEditingController();
  final _notesController = TextEditingController();

  List<Map<String, dynamic>> _customerSuggestions = const [];
  bool _isSearchingCustomer = false;

  final List<OrderItemDraft> _items = [];

  // ── Money helpers ──────────────────────────────────────
  int _parseTnd(String s) {
    final cleaned = s.replaceAll(',', '.').trim();
    if (cleaned.isEmpty) return 0;
    final v = double.tryParse(cleaned) ?? 0;
    return (v * 1000).round();
  }

  int get _grossRevenue =>
      _items.fold(0, (sum, i) => sum + i.unitPrice * i.quantity);
  int get _totalCost =>
      _items.fold(0, (sum, i) => sum + i.unitCost * i.quantity);
  int get _shippingCost => _parseTnd(_shippingController.text);
  int get _discountAmount => _parseTnd(_discountController.text);
  int get _netRevenue => _grossRevenue - _discountAmount;
  int get _profit => _netRevenue - _totalCost - _shippingCost;

  bool get _canSave =>
      _items.isNotEmpty &&
      _customerNameController.text.trim().isNotEmpty &&
      _customerPhoneController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    // Rebuild profit summary live as the user types into fields.
    _customerNameController.addListener(_rebuild);
    _customerPhoneController.addListener(_rebuild);
    _shippingController.addListener(_rebuild);
    _discountController.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerAddressController.dispose();
    _shippingController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _searchCustomers(String query) async {
    if (query.trim().length < 2) {
      setState(() => _customerSuggestions = const []);
      return;
    }
    setState(() => _isSearchingCustomer = true);
    try {
      final results = await ref
          .read(customerRepositoryProvider)
          .searchCustomers(query.trim());
      if (!mounted) return;
      setState(() => _customerSuggestions = results);
    } catch (_) {
      if (!mounted) return;
      setState(() => _customerSuggestions = const []);
    } finally {
      if (mounted) setState(() => _isSearchingCustomer = false);
    }
  }

  void _selectSuggestion(Map<String, dynamic> customer) {
    setState(() {
      _customerNameController.text = customer['name'] as String? ?? '';
      _customerPhoneController.text = customer['phone'] as String? ?? '';
      _customerAddressController.text =
          customer['address'] as String? ?? '';
      _customerSuggestions = const [];
    });
  }

  Future<void> _openProductPicker() async {
    final result = await showProductPickerSheet(context);
    if (result != null && mounted) {
      setState(() => _items.add(result));
    }
  }

  void _adjustQty(int index, int delta) {
    setState(() {
      final item = _items[index];
      final newQty = item.quantity + delta;
      if (newQty <= 0) {
        _items.removeAt(index);
      } else {
        _items[index] = item.copyWith(quantity: newQty);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ajoute au moins un produit'),
          backgroundColor: context.colors.red,
        ),
      );
      return;
    }
    await ref.read(addOrderProvider.notifier).createOrder(
          customerName: _customerNameController.text.trim(),
          customerPhone: _customerPhoneController.text.trim(),
          items: _items
              .map((i) => OrderItemInput(
                    productId: i.productId,
                    variantId: i.variantId,
                    quantity: i.quantity,
                    unitPrice: i.unitPrice,
                    productName: i.productName,
                  ))
              .toList(),
          shippingCost: _shippingCost,
          discountAmount: _discountAmount,
          adSpend: 0,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final addState = ref.watch(addOrderProvider);
    final isLoading = addState.status == AddOrderStatus.loading;

    ref.listen(addOrderProvider, (_, next) {
      if (next.status == AddOrderStatus.success) {
        ref.read(orderListProvider.notifier).refresh();
        context.pop();
      }
    });

    return Scaffold(
      backgroundColor: c.surface0,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(onBack: () => context.pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  context.spacing.space4,
                  context.spacing.space3,
                  context.spacing.space4,
                  context.spacing.space4,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CustomerSection(
                        nameController: _customerNameController,
                        phoneController: _customerPhoneController,
                        addressController: _customerAddressController,
                        suggestions: _customerSuggestions,
                        isSearching: _isSearchingCustomer,
                        onNameChanged: _searchCustomers,
                        onSelectSuggestion: _selectSuggestion,
                      ),
                      SizedBox(height: context.spacing.space6),
                      _ProductsSection(
                        items: _items,
                        onAdd: _openProductPicker,
                        onAdjustQty: _adjustQty,
                      ),
                      SizedBox(height: context.spacing.space6),
                      _ShippingSection(controller: _shippingController),
                      SizedBox(height: context.spacing.space6),
                      _DiscountSection(controller: _discountController),
                      SizedBox(height: context.spacing.space6),
                      _NotesSection(controller: _notesController),
                      SizedBox(height: context.spacing.space6),
                      if (_items.isNotEmpty) ...[
                        if (_items.where((i) => i.isBackorder).isNotEmpty) ...[
                          DidoAttentionStrip(
                            title:
                                '${_items.where((i) => i.isBackorder).length} '
                                "${_items.where((i) => i.isBackorder).length == 1 ? 'article' : 'articles'} "
                                'en backorder',
                            subtitle: 'À commander à la prochaine livraison',
                          ),
                          SizedBox(height: context.spacing.space4),
                        ],
                        _ProfitSummary(
                          revenue: _netRevenue,
                          cost: _totalCost + _shippingCost,
                          profit: _profit,
                        ),
                        SizedBox(height: context.spacing.space4),
                      ],
                      if (addState.error != null) ...[
                        _ErrorBanner(message: addState.error!),
                        SizedBox(height: context.spacing.space4),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            _StickyFooter(
              loading: isLoading,
              enabled: _canSave,
              onSave: _submit,
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
  const _Header({required this.onBack});
  final VoidCallback onBack;

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
          _BackButton(onTap: onBack),
          SizedBox(width: context.spacing.space3),
          Expanded(
            child: Text(
              'Nouvelle commande',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.typography.h2.copyWith(color: c.fg1),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ScaleTap(
      pressedScale: 0.92,
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: c.surface2, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: c.fg1),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Customer section
// ════════════════════════════════════════════════════════════
class _CustomerSection extends StatelessWidget {
  const _CustomerSection({
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.suggestions,
    required this.isSearching,
    required this.onNameChanged,
    required this.onSelectSuggestion,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final List<Map<String, dynamic>> suggestions;
  final bool isSearching;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<Map<String, dynamic>> onSelectSuggestion;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Client'),
        SizedBox(height: context.spacing.space3),
        Container(
          decoration: BoxDecoration(
            color: c.surface1,
            border: Border.all(color: c.border1),
            borderRadius: BorderRadius.circular(context.radius.radiusCard),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _BorderedField(
                controller: nameController,
                hint: 'Nom du client',
                prefixIcon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                trailing: isSearching
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: c.fg2,
                          ),
                        ),
                      )
                    : null,
                onChanged: onNameChanged,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
              ),
              Container(height: 1, color: c.border1),
              _BorderedField(
                controller: phoneController,
                hint: 'Téléphone',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Téléphone requis' : null,
              ),
              Container(height: 1, color: c.border1),
              _BorderedField(
                controller: addressController,
                hint: 'Adresse (facultatif)',
                prefixIcon: Icons.location_on_outlined,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          SizedBox(height: context.spacing.space2),
          Container(
            decoration: BoxDecoration(
              color: c.surface1,
              border: Border.all(color: c.border1),
              borderRadius: BorderRadius.circular(context.radius.radiusCard),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < suggestions.length; i++) ...[
                  _SuggestionRow(
                    customer: suggestions[i],
                    onTap: () => onSelectSuggestion(suggestions[i]),
                  ),
                  if (i < suggestions.length - 1)
                    Container(height: 1, color: c.border1),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.customer, required this.onTap});
  final Map<String, dynamic> customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final name = (customer['name'] as String?) ?? '';
    final phone = (customer['phone'] as String?) ?? '';
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
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: context.typography.bodyMd.copyWith(
                  color: c.fg1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(width: context.spacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.typography.bodyMd.copyWith(color: c.fg1),
                  ),
                  if (phone.isNotEmpty)
                    Text(
                      phone,
                      style:
                          context.typography.bodySmall.copyWith(color: c.fg3),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Products section
// ════════════════════════════════════════════════════════════
class _ProductsSection extends StatelessWidget {
  const _ProductsSection({
    required this.items,
    required this.onAdd,
    required this.onAdjustQty,
  });

  final List<OrderItemDraft> items;
  final VoidCallback onAdd;
  final void Function(int index, int delta) onAdjustQty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionTitle('Produits'),
            _PillCta(
              label: 'Ajouter un produit',
              icon: Icons.add_rounded,
              onTap: onAdd,
            ),
          ],
        ),
        SizedBox(height: context.spacing.space3),
        if (items.isEmpty)
          _EmptyProductsState(onTap: onAdd)
        else
          _ProductsList(items: items, onAdjustQty: onAdjustQty),
      ],
    );
  }
}

class _EmptyProductsState extends StatelessWidget {
  const _EmptyProductsState({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ScaleTap(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.space4,
          vertical: context.spacing.space6,
        ),
        decoration: BoxDecoration(
          color: c.surface1,
          border: Border.all(color: c.border1),
          borderRadius: BorderRadius.circular(context.radius.radiusCard),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_shopping_cart_outlined, size: 32, color: c.fg3),
            SizedBox(height: context.spacing.space2),
            Text(
              'Toucher pour ajouter des produits',
              textAlign: TextAlign.center,
              style: context.typography.bodyMd.copyWith(color: c.fg3),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductsList extends StatelessWidget {
  const _ProductsList({required this.items, required this.onAdjustQty});
  final List<OrderItemDraft> items;
  final void Function(int index, int delta) onAdjustQty;

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
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _ProductRow(
              item: items[i],
              onDecrement: () => onAdjustQty(i, -1),
              onIncrement: () => onAdjustQty(i, 1),
            ),
            if (i < items.length - 1)
              Container(height: 1, color: c.border1),
          ],
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.item,
    required this.onDecrement,
    required this.onIncrement,
  });

  final OrderItemDraft item;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.space4,
        vertical: context.spacing.space3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typography.h4.copyWith(color: c.fg1),
                ),
                SizedBox(height: context.spacing.space1),
                Text(
                  '${MillimesFormatter.format(item.unitPrice)} × ${item.quantity}',
                  style: context.typography.bodySmall.copyWith(color: c.fg3),
                ),
              ],
            ),
          ),
          SizedBox(width: context.spacing.space3),
          _StepperButton(
            icon: item.quantity == 1
                ? Icons.delete_outline_rounded
                : Icons.remove_rounded,
            onTap: onDecrement,
          ),
          SizedBox(width: context.spacing.space2),
          SizedBox(
            width: 24,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: context.typography.h4.copyWith(color: c.fg1),
            ),
          ),
          SizedBox(width: context.spacing.space2),
          _StepperButton(icon: Icons.add_rounded, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ScaleTap(
      pressedScale: 0.92,
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: c.fg1,
          borderRadius: BorderRadius.circular(context.radius.radiusInput),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: c.surface0),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Shipping / Discount / Notes — single-field card sections
// ════════════════════════════════════════════════════════════
class _ShippingSection extends StatelessWidget {
  const _ShippingSection({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _SingleFieldSection(
      title: 'Livraison',
      controller: controller,
      hint: '0',
      prefixIcon: Icons.local_shipping_outlined,
      suffix: 'TND',
      isMoney: true,
    );
  }
}

class _DiscountSection extends StatelessWidget {
  const _DiscountSection({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _SingleFieldSection(
      title: 'Remise',
      controller: controller,
      hint: '0',
      prefixIcon: Icons.local_offer_outlined,
      suffix: 'TND',
      isMoney: true,
    );
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _SingleFieldSection(
      title: 'Notes (facultatif)',
      controller: controller,
      hint: 'Note interne…',
      maxLines: 2,
    );
  }
}

class _SingleFieldSection extends StatelessWidget {
  const _SingleFieldSection({
    required this.title,
    required this.controller,
    required this.hint,
    this.prefixIcon,
    this.suffix,
    this.isMoney = false,
    this.maxLines = 1,
  });

  final String title;
  final TextEditingController controller;
  final String hint;
  final IconData? prefixIcon;
  final String? suffix;
  final bool isMoney;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(title),
        SizedBox(height: context.spacing.space3),
        Container(
          decoration: BoxDecoration(
            color: c.surface1,
            border: Border.all(color: c.border1),
            borderRadius: BorderRadius.circular(context.radius.radiusCard),
          ),
          clipBehavior: Clip.antiAlias,
          child: _BorderedField(
            controller: controller,
            hint: hint,
            prefixIcon: prefixIcon,
            suffix: suffix,
            maxLines: maxLines,
            keyboardType: isMoney
                ? const TextInputType.numberWithOptions(decimal: true)
                : null,
            inputFormatters: isMoney
                ? [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))]
                : null,
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Profit summary (no gradient — flat tinted bg)
// ════════════════════════════════════════════════════════════
class _ProfitSummary extends StatelessWidget {
  const _ProfitSummary({
    required this.revenue,
    required this.cost,
    required this.profit,
  });

  final int revenue;
  final int cost;
  final int profit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final profitable = profit >= 0;
    final bg = profitable ? c.greenTint12 : c.coralTint12;
    final fg = profitable ? c.greenFg : c.coralFg;
    return Container(
      padding: EdgeInsets.all(context.spacing.space4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Chiffre', value: MillimesFormatter.format(revenue), fg: fg),
          SizedBox(height: context.spacing.space2),
          _SummaryRow(label: 'Coût', value: '- ${MillimesFormatter.format(cost)}', fg: fg),
          SizedBox(height: context.spacing.space3),
          Container(height: 1, color: c.border1),
          SizedBox(height: context.spacing.space3),
          _SummaryRow(
            label: 'Bénéfice réel',
            value: MillimesFormatter.format(profit),
            fg: fg,
            isPrimary: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.fg,
    this.isPrimary = false,
  });

  final String label;
  final String value;
  final Color fg;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final labelStyle = isPrimary
        ? context.typography.bodyMd.copyWith(color: fg, fontWeight: FontWeight.w600)
        : context.typography.body.copyWith(color: fg);
    final valueStyle = isPrimary
        ? context.typography.h3.copyWith(color: fg)
        : context.typography.bodyMd.copyWith(color: fg, fontWeight: FontWeight.w600);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),
        Text(value, style: valueStyle),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Error banner
// ════════════════════════════════════════════════════════════
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.spacing.space3),
      decoration: BoxDecoration(
        color: c.redTint12,
        borderRadius: BorderRadius.circular(context.radius.radiusInput),
      ),
      child: Text(
        message,
        style: context.typography.bodySmall.copyWith(color: c.redFg),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Sticky footer with primary save button
// ════════════════════════════════════════════════════════════
class _StickyFooter extends StatelessWidget {
  const _StickyFooter({
    required this.loading,
    required this.enabled,
    required this.onSave,
  });

  final bool loading;
  final bool enabled;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: c.surface0,
        border: Border(top: BorderSide(color: c.border1, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(
        context.spacing.space4,
        context.spacing.space3,
        context.spacing.space4,
        context.spacing.space3 + bottomInset,
      ),
      child: _PrimaryCta(
        label: 'Enregistrer',
        loading: loading,
        enabled: enabled && !loading,
        onTap: onSave,
        fullWidth: true,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Primary CTA (v1.1 §3.1) — replaces DidoButton.primary which is
// still teal-backed. Token-driven fg-1 bg / surface0 fg.
// ════════════════════════════════════════════════════════════
class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.label,
    required this.onTap,
    this.loading = false,
    this.enabled = true,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool loading;
  final bool enabled;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final interactive = enabled && !loading;
    final body = Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: interactive ? c.fg1 : c.fg4,
        borderRadius: BorderRadius.circular(context.radius.radiusInput),
      ),
      alignment: Alignment.center,
      child: loading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: c.surface0),
            )
          : Text(
              label,
              style: context.typography.button.copyWith(color: c.surface0),
            ),
    );
    final wrapped = fullWidth ? SizedBox(width: double.infinity, child: body) : body;
    return _ScaleTap(
      onTap: interactive ? onTap : null,
      child: wrapped,
    );
  }
}

// ════════════════════════════════════════════════════════════
// Pill CTA — small inline button (e.g. "+ Ajouter un produit"
// in the Products section header). v1.1 §3.1 fg-1 bg, 8px radius.
// ════════════════════════════════════════════════════════════
class _PillCta extends StatelessWidget {
  const _PillCta({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c.fg1,
          borderRadius: BorderRadius.circular(context.radius.radiusInput),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: c.surface0),
            SizedBox(width: context.spacing.space1),
            Text(
              label,
              style: context.typography.bodySmallMd.copyWith(color: c.surface0),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Reusable bordered field (TextFormField inside a card)
// ════════════════════════════════════════════════════════════
class _BorderedField extends StatelessWidget {
  const _BorderedField({
    required this.controller,
    required this.hint,
    this.prefixIcon,
    this.suffix,
    this.trailing,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.maxLines = 1,
    this.inputFormatters,
    this.onChanged,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final IconData? prefixIcon;
  final String? suffix;
  final Widget? trailing;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      validator: validator,
      style: context.typography.input.copyWith(color: c.fg1),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: context.typography.input.copyWith(color: c.fg3),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, size: 20, color: c.fg3),
        suffixText: suffix,
        suffixStyle: context.typography.bodyMd.copyWith(color: c.fg3),
        suffixIcon: trailing,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.spacing.space4,
          vertical: context.spacing.space3,
        ),
        isDense: true,
        errorStyle:
            context.typography.bodySmall.copyWith(color: c.redFg),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Section title
// ════════════════════════════════════════════════════════════
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: context.typography.label.copyWith(color: context.colors.fg3),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Tap feedback (duplicated — see TODO in product_picker_sheet)
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
