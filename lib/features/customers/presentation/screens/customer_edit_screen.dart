import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../domain/customer_models.dart';
import '../providers/customer_provider.dart';

class CustomerEditScreen extends ConsumerStatefulWidget {
  const CustomerEditScreen({super.key, required this.customerId});
  final String customerId;

  @override
  ConsumerState<CustomerEditScreen> createState() =>
      _CustomerEditScreenState();
}

class _CustomerEditScreenState extends ConsumerState<CustomerEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _governorateController = TextEditingController();
  final _discountController = TextEditingController();
  final _notesController = TextEditingController();

  bool _hydrated = false;
  bool _saving = false;
  String? _error;

  void _hydrate(CustomerDetail customer) {
    if (_hydrated) return;
    _nameController.text = customer.name;
    _phoneController.text = customer.phone;
    _addressController.text = customer.address ?? '';
    _cityController.text = customer.city ?? '';
    _governorateController.text = customer.governorate ?? '';
    _discountController.text = customer.defaultDiscountAmount > 0
        ? MillimesFormatter.toTnd(customer.defaultDiscountAmount)
            .toStringAsFixed(0)
        : '';
    _notesController.text = customer.notes ?? '';
    _hydrated = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _governorateController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int _parseDiscountMillimes(String value) {
    final v = value.trim();
    if (v.isEmpty) return 0;
    final tnd = double.tryParse(v.replaceAll(',', '.')) ?? 0;
    return (tnd * 1000).round();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final input = CustomerUpdateInput(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      city: _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      governorate: _governorateController.text.trim().isEmpty
          ? null
          : _governorateController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      defaultDiscountAmount:
          _parseDiscountMillimes(_discountController.text),
    );

    try {
      await ref
          .read(customerRepositoryProvider)
          .updateCustomer(widget.customerId, input);
      ref.invalidate(customerDetailProvider(widget.customerId));
      ref.invalidate(customerListProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Échec de l\'enregistrement. Réessayer.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final detailAsync =
        ref.watch(customerDetailProvider(widget.customerId));

    return Scaffold(
      backgroundColor: c.surface0,
      body: SafeArea(
        bottom: false,
        child: detailAsync.when(
          loading: () => Column(
            children: [
              _Header(onBack: () => context.pop()),
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
          error: (_, __) => Column(
            children: [
              _Header(onBack: () => context.pop()),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(context.spacing.space8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off_rounded,
                            size: 48, color: c.fg3),
                        SizedBox(height: context.spacing.space3),
                        Text(
                          'Impossible de charger le client',
                          textAlign: TextAlign.center,
                          style: context.typography.h4
                              .copyWith(color: c.fg1),
                        ),
                        SizedBox(height: context.spacing.space4),
                        DidoButton.secondary(
                          label: 'Réessayer',
                          fullWidth: false,
                          onPressed: () => ref.invalidate(
                              customerDetailProvider(widget.customerId)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          data: (customer) {
            _hydrate(customer);
            return Column(
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
                          const _SectionTitle('Nom *'),
                          SizedBox(height: context.spacing.space2),
                          _CardField(
                            controller: _nameController,
                            hint: 'Nom du client',
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Nom requis'
                                    : null,
                          ),
                          SizedBox(height: context.spacing.space6),
                          const _SectionTitle('Téléphone *'),
                          SizedBox(height: context.spacing.space2),
                          _CardField(
                            controller: _phoneController,
                            hint: '+216 XX XXX XXX',
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Téléphone requis'
                                    : null,
                          ),
                          SizedBox(height: context.spacing.space6),
                          const _SectionTitle('Adresse'),
                          SizedBox(height: context.spacing.space2),
                          _CardField(
                            controller: _addressController,
                            hint: 'Rue, immeuble (optionnel)',
                            textInputAction: TextInputAction.next,
                          ),
                          SizedBox(height: context.spacing.space6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const _SectionTitle('Ville'),
                                    SizedBox(
                                        height: context.spacing.space2),
                                    _CardField(
                                      controller: _cityController,
                                      hint: 'Ville',
                                      textCapitalization:
                                          TextCapitalization.words,
                                      textInputAction:
                                          TextInputAction.next,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: context.spacing.space3),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const _SectionTitle('Gouvernorat'),
                                    SizedBox(
                                        height: context.spacing.space2),
                                    _CardField(
                                      controller: _governorateController,
                                      hint: 'Gouvernorat',
                                      textCapitalization:
                                          TextCapitalization.words,
                                      textInputAction:
                                          TextInputAction.next,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.spacing.space6),
                          const _SectionTitle('Remise par défaut'),
                          SizedBox(height: context.spacing.space2),
                          _CardField(
                            controller: _discountController,
                            hint: '0',
                            suffix: 'TND',
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[\d,.]')),
                            ],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return null;
                              }
                              if (double.tryParse(
                                      v.replaceAll(',', '.')) ==
                                  null) {
                                return 'Invalide';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: context.spacing.space6),
                          const _SectionTitle('Notes'),
                          SizedBox(height: context.spacing.space2),
                          _CardField(
                            controller: _notesController,
                            hint: 'Préférences, taille, remarques…',
                            textCapitalization:
                                TextCapitalization.sentences,
                            maxLines: 3,
                          ),
                          if (_error != null) ...[
                            SizedBox(height: context.spacing.space4),
                            _ErrorBanner(message: _error!),
                          ],
                          SizedBox(height: context.spacing.space6),
                        ],
                      ),
                    ),
                  ),
                ),
                _StickyFooter(
                  loading: _saving,
                  onSave: _save,
                ),
              ],
            );
          },
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
          _ScaleTap(
            pressedScale: 0.92,
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.surface2,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: c.fg1),
            ),
          ),
          SizedBox(width: context.spacing.space3),
          Expanded(
            child: Text(
              'Modifier le client',
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

// ════════════════════════════════════════════════════════════
// Section title
// ════════════════════════════════════════════════════════════
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: context.typography.label.copyWith(color: context.colors.fg3),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Card field
// ════════════════════════════════════════════════════════════
class _CardField extends StatelessWidget {
  const _CardField({
    required this.controller,
    required this.hint,
    this.suffix,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.maxLines = 1,
    this.inputFormatters,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final String? suffix;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;

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
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        textInputAction: textInputAction,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        validator: validator,
        style: context.typography.input.copyWith(color: c.fg1),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: context.typography.input.copyWith(color: c.fg3),
          suffixText: suffix,
          suffixStyle: context.typography.bodyMd.copyWith(color: c.fg3),
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
      ),
    );
  }
}

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
// Sticky footer
// ════════════════════════════════════════════════════════════
class _StickyFooter extends StatelessWidget {
  const _StickyFooter({required this.loading, required this.onSave});
  final bool loading;
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
      child: DidoButton.primary(
        label: 'Enregistrer',
        loading: loading,
        fullWidth: true,
        onPressed: onSave,
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
