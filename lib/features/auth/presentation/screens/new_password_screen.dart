import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../data/auth_repository.dart';

class NewPasswordScreen extends ConsumerStatefulWidget {
  const NewPasswordScreen({
    super.key,
    required this.email,
    required this.otp,
  });
  final String email;
  final String otp;

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await AuthRepository().resetPassword(
        email: widget.email,
        otp: widget.otp,
        newPassword: _passwordController.text,
      );
      if (mounted) context.go('/auth/login?reset=true');
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.surface0,
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              EdgeInsets.symmetric(horizontal: context.spacing.screenEdge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: context.spacing.space8),
                _BackButton(
                  onTap: () => context.go(
                    '/auth/verify-otp',
                    extra: widget.email,
                  ),
                ),
                SizedBox(height: context.spacing.space6),
                Text(
                  'Nouveau mot de passe',
                  style: context.typography.h1.copyWith(color: c.fg1),
                ),
                SizedBox(height: context.spacing.space2),
                Text(
                  'Choisissez un mot de passe fort.',
                  style: context.typography.bodyMd.copyWith(color: c.fg2),
                ),
                SizedBox(height: context.spacing.space6),
                _FieldLabel(text: 'Nouveau mot de passe'),
                SizedBox(height: context.spacing.space2),
                _AuthField(
                  controller: _passwordController,
                  hint: '••••••••',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  suffixIcon: _ObscureToggle(
                    obscured: _obscurePassword,
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Le mot de passe est requis';
                    }
                    if (v.length < 8) return 'Minimum 8 caractères';
                    return null;
                  },
                ),
                SizedBox(height: context.spacing.space4),
                _FieldLabel(text: 'Confirmer le mot de passe'),
                SizedBox(height: context.spacing.space2),
                _AuthField(
                  controller: _confirmController,
                  hint: '••••••••',
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  suffixIcon: _ObscureToggle(
                    obscured: _obscureConfirm,
                    onPressed: () => setState(
                      () => _obscureConfirm = !_obscureConfirm,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Confirmez votre mot de passe';
                    }
                    if (v != _passwordController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
                if (_error != null) ...[
                  SizedBox(height: context.spacing.space3),
                  _ErrorBanner(message: _error!),
                ],
                SizedBox(height: context.spacing.space6),
                DidoButton.primary(
                  label: 'Réinitialiser',
                  loading: _isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Shared auth pieces (inlined per file)
// ════════════════════════════════════════════════════════════
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration:
            BoxDecoration(color: c.surface2, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(Icons.arrow_back_ios_new_rounded,
            size: 16, color: c.fg1),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.typography.bodyMd.copyWith(
        color: context.colors.fg1,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.hint,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(context.radius.radiusInput);
    OutlineInputBorder b(Color color, double width) => OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: color, width: width));

    return TextFormField(
      controller: controller,
      textInputAction: textInputAction,
      obscureText: obscureText,
      autocorrect: !obscureText,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: context.typography.input.copyWith(color: c.fg1),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: context.typography.input.copyWith(color: c.fg3),
        filled: true,
        fillColor: c.surface1,
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.spacing.space3,
          vertical: 14,
        ),
        isDense: true,
        border: b(c.border1, 1),
        enabledBorder: b(c.border1, 1),
        focusedBorder: b(c.fg1, 1.5),
        errorBorder: b(c.red, 1),
        focusedErrorBorder: b(c.red, 1.5),
        errorStyle: context.typography.bodySmall.copyWith(color: c.redFg),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class _ObscureToggle extends StatelessWidget {
  const _ObscureToggle({required this.obscured, required this.onPressed});
  final bool obscured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: context.colors.fg3,
        size: 20,
      ),
      onPressed: onPressed,
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
