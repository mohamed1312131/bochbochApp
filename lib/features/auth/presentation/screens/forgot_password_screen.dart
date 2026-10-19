import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../data/auth_repository.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await AuthRepository().forgotPassword(
        email: _emailController.text.trim(),
      );
      if (mounted) {
        context.go(
          '/auth/verify-otp',
          extra: _emailController.text.trim(),
        );
      }
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
                _BackButton(onTap: () => context.go('/auth/login')),
                SizedBox(height: context.spacing.space6),
                Text(
                  'Mot de passe oublié ?',
                  style: context.typography.h1.copyWith(color: c.fg1),
                ),
                SizedBox(height: context.spacing.space2),
                Text(
                  'Entrez votre email et nous vous enverrons un code de réinitialisation.',
                  style: context.typography.bodyMd.copyWith(color: c.fg2),
                ),
                SizedBox(height: context.spacing.space6),
                _FieldLabel(text: 'Email'),
                SizedBox(height: context.spacing.space2),
                _AuthField(
                  controller: _emailController,
                  hint: 'votre@email.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'L\'email est requis';
                    }
                    final emailRegex = RegExp(
                        r'^[\w+\-.]+@[a-zA-Z\d\-.]+\.[a-zA-Z]{2,}$');
                    if (!emailRegex.hasMatch(v)) {
                      return 'Entrez un email valide';
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
                  label: 'Envoyer le code',
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
// Shared auth pieces (inlined — TODO(extract))
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
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
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
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autocorrect: false,
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
