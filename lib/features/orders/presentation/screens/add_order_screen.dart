import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_border_radius.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../../../../core/api/dio_client.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../../../products/domain/product_models.dart';
import '../providers/order_provider.dart';
import '../../domain/order_models.dart';

class AddOrderScreen extends ConsumerStatefulWidget {
  const AddOrderScreen({super.key});

  @override
  ConsumerState<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends ConsumerState<AddOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _shippingController = TextEditingController(text: '0');
  final _discountController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  final List<_OrderItemDraft> _items = [];
  bool _showAdvanced = false;
  bool _isLoadingProducts = false;
  List<Map<String, dynamic>> _customerSuggestions = [];
  bool _isSearchingCustomer = false;
  // ignore: unused_field
  String? _selectedCustomerId;

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _shippingController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int _parseTnd(String value) {
    final tnd = double.tryParse(value.replaceAll(',', '.')) ?? 0;
    return MillimesFormatter.toMillimes(tnd);
  }

  // ── Calculated totals ──────────────────────────────────
  int get _grossRevenue =>
      _items.fold(0, (sum, i) => sum + i.unitPrice * i.quantity);
  int get _totalCost =>
      _items.fold(0, (sum, i) => sum + i.unitCost * i.quantity);
  int get _shippingCost => _parseTnd(_shippingController.text);
  int get _discountAmount => _parseTnd(_discountController.text);
  int get _netRevenue => _grossRevenue - _discountAmount;
  int get _profit => _netRevenue - _totalCost - _shippingCost;

  Future<void> _addProduct() async {
    // Load products fresh — don't rely on cached provider
    setState(() => _isLoadingProducts = true);
    try {
      final result = await ref
          .read(productRepositoryProvider)
          .getProducts(limit: 50);
      final products = result.data;

      if (!mounted) return;
      setState(() => _isLoadingProducts = false);

      if (products.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No products found. Add products first.'),
          ),
        );
        return;
      }

      await showModalBottomSheet(
        context: context,
        backgroundColor: context.appSurface,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        builder: (_) => _ProductPickerSheet(
          products: products,
          onSelected: (item) {
            setState(() => _items.add(item));
          },
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Add at least one product'),
          backgroundColor: AppColors.error,
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
    final addState = ref.watch(addOrderProvider);
    final isLoading = addState.status == AddOrderStatus.loading;

    ref.listen(addOrderProvider, (_, next) {
      if (next.status == AddOrderStatus.success) {
        ref.read(orderListProvider.notifier).refresh();
        context.pop();
      }
    });

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.xl,
                AppSpacing.screenHorizontal,
                AppSpacing.md,
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
                    'Log Sale',
                    style: AppTypography.h2.copyWith(
                      color: context.appTextPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // ── Form ─────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Customer ──────────────────────
                      _SectionTitle(title: 'Customer'),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: context.appSurface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: context.isDark
                              ? Border.all(color: context.appBorder)
                              : null,
                          boxShadow: context.appCardShadow,
                        ),
                        child: Column(
                          children: [
                            // Name with autocomplete
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _customerNameController,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization: TextCapitalization.words,
                                  style: AppTypography.body.copyWith(
                                    color: context.appTextPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Customer name',
                                    prefixIcon: const Icon(Icons.person_outline_rounded),
                                    suffixIcon: _isSearchingCustomer
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: Padding(
                                              padding: EdgeInsets.all(12),
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          )
                                        : null,
                                  ),
                                  onChanged: (value) async {
                                    _selectedCustomerId = null;
                                    if (value.length < 2) {
                                      setState(() => _customerSuggestions = []);
                                      return;
                                    }
                                    setState(() => _isSearchingCustomer = true);
                                    try {
                                      final dio = (await DioClient.getInstance()).dio;
                                      final response = await dio.post(
                                        '/customers/search',
                                        data: {'query': value},
                                      );
                                      final results = response.data as List;
                                      setState(() {
                                        _customerSuggestions = results
                                            .map((e) => e as Map<String, dynamic>)
                                            .toList();
                                      });
                                    } catch (_) {
                                      setState(() => _customerSuggestions = []);
                                    } finally {
                                      setState(() => _isSearchingCustomer = false);
                                    }
                                  },
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Name is required';
                                    }
                                    return null;
                                  },
                                ),
                                // Suggestions dropdown
                                if (_customerSuggestions.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    decoration: BoxDecoration(
                                      color: context.appSurface,
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                      border: Border.all(color: context.appBorder),
                                      boxShadow: context.appCardShadow,
                                    ),
                                    child: Column(
                                      children: _customerSuggestions.map((customer) {
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedCustomerId = customer['id'] as String;
                                              _customerNameController.text =
                                                  customer['name'] as String;
                                              _customerPhoneController.text =
                                                  customer['phone'] as String? ?? '';
                                              _customerSuggestions = [];
                                            });
                                          },
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
                                                    color: context.appBrandLight,
                                                    borderRadius:
                                                        BorderRadius.circular(AppRadius.full),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      (customer['name'] as String)[0]
                                                          .toUpperCase(),
                                                      style: AppTypography.body.copyWith(
                                                        color: context.appBrand,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: AppSpacing.sm),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        customer['name'] as String,
                                                        style: AppTypography.body.copyWith(
                                                          color: context.appTextPrimary,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                      Text(
                                                        customer['phone'] as String? ?? '',
                                                        style: AppTypography.caption.copyWith(
                                                          color: context.appTextSecondary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.north_west_rounded,
                                                  size: 14,
                                                  color: context.appTextTertiary,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            // Phone
                            TextFormField(
                              controller: _customerPhoneController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              style: AppTypography.body.copyWith(
                                color: context.appTextPrimary,
                              ),
                              decoration: const InputDecoration(
                                hintText: '+216 XX XXX XXX',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Phone is required';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Products ──────────────────────
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          _SectionTitle(title: 'Products'),
                          GestureDetector(
                            onTap: _addProduct,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: context.appBrand,
                                borderRadius: BorderRadius.circular(
                                    AppRadius.full),
                              ),
                              child: _isLoadingProducts
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.white,
                                      ),
                                    )
                                  : Row(
                                      children: [
                                        const Icon(Icons.add_rounded,
                                            color: AppColors.white, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Add Product',
                                          style: AppTypography.label.copyWith(
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Items list
                      if (_items.isEmpty)
                        GestureDetector(
                          onTap: _addProduct,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            decoration: BoxDecoration(
                              color: context.appSurface,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg),
                              border: Border.all(
                                color: context.appBorder,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.add_shopping_cart_rounded,
                                  color: context.appTextTertiary,
                                  size: 32,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Tap to add products',
                                  style: AppTypography.body.copyWith(
                                    color: context.appTextTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: context.appSurface,
                            borderRadius:
                                BorderRadius.circular(AppRadius.lg),
                            border: context.isDark
                                ? Border.all(color: context.appBorder)
                                : null,
                            boxShadow: context.appCardShadow,
                          ),
                          child: Column(
                            children: _items.asMap().entries.map((entry) {
                              final i = entry.key;
                              final item = entry.value;
                              final isLast = i == _items.length - 1;

                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(
                                        AppSpacing.md),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.productName,
                                                style: AppTypography.body
                                                    .copyWith(
                                                  color:
                                                      context.appTextPrimary,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                '${MillimesFormatter.format(item.unitPrice)} × ${item.quantity}',
                                                style: AppTypography.caption
                                                    .copyWith(
                                                  color:
                                                      context.appTextSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Quantity controls
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  if (item.quantity > 1) {
                                                    _items[i] = item
                                                        .copyWith(
                                                            quantity: item
                                                                    .quantity -
                                                                1);
                                                  } else {
                                                    _items.removeAt(i);
                                                  }
                                                });
                                              },
                                              child: Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color:
                                                      context.appSurfaceL2,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          AppRadius.full),
                                                ),
                                                child: Icon(
                                                  item.quantity == 1
                                                      ? Icons
                                                          .delete_outline_rounded
                                                      : Icons.remove_rounded,
                                                  size: 16,
                                                  color: item.quantity == 1
                                                      ? AppColors.error
                                                      : context.appTextPrimary,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal:
                                                          AppSpacing.sm),
                                              child: Text(
                                                '${item.quantity}',
                                                style: AppTypography.h4
                                                    .copyWith(
                                                  color:
                                                      context.appTextPrimary,
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _items[i] = item.copyWith(
                                                      quantity:
                                                          item.quantity + 1);
                                                });
                                              },
                                              child: Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color: context.appBrand,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          AppRadius.full),
                                                ),
                                                child: const Icon(
                                                  Icons.add_rounded,
                                                  size: 16,
                                                  color: AppColors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isLast)
                                    Divider(
                                      height: 1,
                                      color: context.appBorder,
                                    ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Shipping ──────────────────────
                      _SectionTitle(title: 'Shipping Cost'),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _shippingController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                        style: AppTypography.body.copyWith(
                          color: context.appTextPrimary,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d,.]')),
                        ],
                        decoration: const InputDecoration(
                          hintText: '0',
                          suffixText: 'TND',
                          prefixIcon:
                              Icon(Icons.local_shipping_outlined),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // ── Advanced ──────────────────────
                      GestureDetector(
                        onTap: () => setState(
                            () => _showAdvanced = !_showAdvanced),
                        child: Row(
                          children: [
                            Icon(
                              _showAdvanced
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: context.appBrand,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _showAdvanced
                                  ? 'Hide advanced'
                                  : 'Discount',
                              style: AppTypography.body.copyWith(
                                color: context.appBrand,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_showAdvanced) ...[
                        const SizedBox(height: AppSpacing.md),
                        // Discount full width
                        Text(
                          'Discount',
                          style: AppTypography.body.copyWith(
                            color: context.appTextPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _discountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: AppTypography.body.copyWith(
                            color: context.appTextPrimary,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                          ],
                          decoration: const InputDecoration(
                            hintText: '0',
                            suffixText: 'TND',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 2,
                          style: AppTypography.body.copyWith(
                            color: context.appTextPrimary,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Notes (optional)...',
                            prefixIcon: Icon(Icons.notes_rounded),
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.xl),

                      // ── Profit Summary ────────────────
                      if (_items.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _profit >= 0
                                    ? AppColors.success
                                    : AppColors.error,
                                _profit >= 0
                                    ? const Color(0xFF16A34A)
                                    : AppColors.errorBg,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius:
                                BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Revenue',
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.white
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                                  Text(
                                    MillimesFormatter.format(_netRevenue),
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Cost',
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.white
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                                  Text(
                                    '- ${MillimesFormatter.format(_totalCost + _shippingCost)}',
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.sm),
                                height: 1,
                                color:
                                    AppColors.white.withValues(alpha: 0.3),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Real Profit',
                                    style: AppTypography.h4.copyWith(
                                      color: AppColors.white,
                                    ),
                                  ),
                                  Text(
                                    MillimesFormatter.format(_profit),
                                    style: AppTypography.h3.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],

                      // ── Error ─────────────────────────
                      if (addState.error != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.errorBg,
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            addState.error!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // ── Save button ───────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.appBrand,
                            foregroundColor: AppColors.white,
                            disabledBackgroundColor:
                                context.appBrand.withValues(alpha: 0.3),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : Text(
                                  'Save Order',
                                  style: AppTypography.bodyLarge.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Product Picker Sheet ───────────────────────────────────
class _ProductPickerSheet extends ConsumerStatefulWidget {
  const _ProductPickerSheet({
    required this.products,
    required this.onSelected,
  });

  final List<ProductLean> products;
  final Function(_OrderItemDraft) onSelected;

  @override
  ConsumerState<_ProductPickerSheet> createState() =>
      _ProductPickerSheetState();
}

class _ProductPickerSheetState
    extends ConsumerState<_ProductPickerSheet> {
  ProductLean? _selectedProduct;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppRadius.xl),
              topRight: Radius.circular(AppRadius.xl),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appBorder,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  _selectedProduct == null
                      ? 'Select Product'
                      : 'Select Variant',
                  style: AppTypography.h4.copyWith(
                    color: context.appTextPrimary,
                  ),
                ),
              ),

              Divider(height: 1, color: context.appBorder),

              // Product list
              if (_selectedProduct == null)
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: widget.products.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final product = widget.products[index];
                      return GestureDetector(
                        onTap: () async {
                          if (product.isMultiVariant) {
                            // Load full product to get variants
                            setState(
                                () => _selectedProduct = product);
                          } else {
                            // Load full product for variant info
                            final full = await ref
                                .read(productRepositoryProvider)
                                .getProduct(product.id);
                            if (full.variants.isNotEmpty &&
                                context.mounted) {
                              final variant = full.variants.first;
                              widget.onSelected(_OrderItemDraft(
                                productId: product.id,
                                variantId: variant.id,
                                productName: product.name,
                                unitPrice: variant.effectiveSellPrice,
                                unitCost: variant.effectiveCostPrice,
                                quantity: 1,
                              ));
                              Navigator.pop(context);
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: context.appSurfaceL2,
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                          child: Row(
                            children: [
                              // Image
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: product.primaryImageUrl != null
                                      ? Image.network(
                                          product.primaryImageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) => Container(
                                            color: context.appSurfaceL2,
                                            child: Icon(
                                              Icons.inventory_2_outlined,
                                              color:
                                                  context.appTextTertiary,
                                              size: 24,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: context.appSurfaceL2,
                                          child: Icon(
                                            Icons.inventory_2_outlined,
                                            color: context.appTextTertiary,
                                            size: 24,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: AppTypography.body.copyWith(
                                        color: context.appTextPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      MillimesFormatter.format(
                                          product.baseSellPrice),
                                      style:
                                          AppTypography.caption.copyWith(
                                        color: context.appBrand,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (product.isMultiVariant)
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: context.appTextTertiary,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                // Variant picker
                _VariantPicker(
                  product: _selectedProduct!,
                  onSelected: (variant) {
                    widget.onSelected(_OrderItemDraft(
                      productId: _selectedProduct!.id,
                      variantId: variant.id,
                      productName: _selectedProduct!.name,
                      unitPrice: variant.effectiveSellPrice,
                      unitCost: variant.effectiveCostPrice,
                      quantity: 1,
                    ));
                    Navigator.pop(context);
                  },
                  onBack: () =>
                      setState(() => _selectedProduct = null),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Variant Picker ─────────────────────────────────────────
class _VariantPicker extends ConsumerWidget {
  const _VariantPicker({
    required this.product,
    required this.onSelected,
    required this.onBack,
  });

  final ProductLean product;
  final Function(ProductVariant) onSelected;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync =
        ref.watch(productDetailProvider(product.id));

    return Expanded(
      child: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(
            'Could not load variants',
            style: AppTypography.body
                .copyWith(color: context.appTextSecondary),
          ),
        ),
        data: (full) => Column(
          children: [
            // Back button
            GestureDetector(
              onTap: onBack,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(Icons.arrow_back_ios_new_rounded,
                        size: 14, color: context.appBrand),
                    const SizedBox(width: 4),
                    Text(
                      'Back to products',
                      style: AppTypography.body.copyWith(
                        color: context.appBrand,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: full.variants
                    .where((v) => v.isActive)
                    .length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final variant = full.variants
                      .where((v) => v.isActive)
                      .toList()[index];

                  return GestureDetector(
                    onTap: () => onSelected(variant),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: context.appSurfaceL2,
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                variant.isSimple
                                    ? 'Default'
                                    : variant.attributeLabel,
                                style: AppTypography.body.copyWith(
                                  color: context.appTextPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                variant.sku,
                                style: AppTypography.caption.copyWith(
                                  color: context.appTextTertiary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                MillimesFormatter.format(
                                    variant.effectiveSellPrice),
                                style: AppTypography.body.copyWith(
                                  color: context.appBrand,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: variant.stockQuantity > 0
                                      ? AppColors.successBg
                                      : AppColors.errorBg,
                                  borderRadius: BorderRadius.circular(
                                      AppRadius.full),
                                ),
                                child: Text(
                                  '${variant.stockQuantity} left',
                                  style: AppTypography.caption.copyWith(
                                    color: variant.stockQuantity > 0
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Draft model ────────────────────────────────────────────
class _OrderItemDraft {
  const _OrderItemDraft({
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.unitPrice,
    required this.unitCost,
    required this.quantity,
  });

  final String productId;
  final String variantId;
  final String productName;
  final int unitPrice;
  final int unitCost;
  final int quantity;

  _OrderItemDraft copyWith({int? quantity}) => _OrderItemDraft(
        productId: productId,
        variantId: variantId,
        productName: productName,
        unitPrice: unitPrice,
        unitCost: unitCost,
        quantity: quantity ?? this.quantity,
      );
}

// ── Reusable ───────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.h4.copyWith(
        color: context.appTextPrimary,
      ),
    );
  }
}