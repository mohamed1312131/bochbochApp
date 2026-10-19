import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../providers/auth_provider.dart';
import '../widgets/google_signin_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(registerProvider.notifier).register(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final registerState = ref.watch(registerProvider);
    final isLoading = registerState.status == RegisterStatus.loading;

    ref.listen(registerProvider, (_, next) {
      if (next.status == RegisterStatus.success) {
        context.go('/auth/verify-email');
      }
    });

    final isGoogleLoading = FeatureFlags.googleSigninEnabled
        ? ref.watch(loginProvider).status == LoginStatus.loading
        : false;
    if (FeatureFlags.googleSigninEnabled) {
      ref.listen(loginProvider, (_, next) {
        if (next.status == LoginStatus.success) {
          context.go('/home');
        }
      });
    }

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
                  'Créer un compte',
                  style: context.typography.h1.copyWith(color: c.fg1),
                ),
                SizedBox(height: context.spacing.space2),
                Text(
                  'Commencez votre essai gratuit de 30 jours',
                  style: context.typography.bodyMd.copyWith(color: c.fg2),
                ),
                SizedBox(height: context.spacing.space6),
                _FieldLabel(text: 'Nom complet'),
                SizedBox(height: context.spacing.space2),
                _AuthField(
                  controller: _nameController,
                  hint: 'Amira Ben Ali',
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Le nom est requis';
                    }
                    if (v.trim().length < 2) return 'Nom trop court';
                    return null;
                  },
                ),
                SizedBox(height: context.spacing.space4),
                _FieldLabel(text: 'Email'),
                SizedBox(height: context.spacing.space2),
                _AuthField(
                  controller: _emailController,
                  hint: 'votre@email.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'L\'email est requis';
                    }
                    if (!v.contains('@')) return 'Entrez un email valide';
                    return null;
                  },
                ),
                SizedBox(height: context.spacing.space4),
                _FieldLabel(text: 'Mot de passe'),
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
                  controller: _confirmPasswordController,
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
                if (registerState.error != null) ...[
                  SizedBox(height: context.spacing.space3),
                  _ErrorBanner(message: registerState.error!),
                ],
                SizedBox(height: context.spacing.space6),
                DidoButton.primary(
                  label: 'Créer le compte',
                  loading: isLoading,
                  onPressed: _submit,
                ),
                SizedBox(height: context.spacing.space6),
                if (FeatureFlags.googleSigninEnabled) ...[
                  Row(
                    children: [
                      Expanded(child: Divider(color: c.border1)),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: context.spacing.space3),
                        child: Text(
                          'Ou se connecter avec',
                          style: context.typography.bodySmall
                              .copyWith(color: c.fg3),
                        ),
                      ),
                      Expanded(child: Divider(color: c.border1)),
                    ],
                  ),
                  SizedBox(height: context.spacing.space4),
                  GoogleSignInButton(
                    onPressed: (isLoading || isGoogleLoading)
                        ? null
                        : () => ref
                            .read(loginProvider.notifier)
                            .loginWithGoogle(),
                  ),
                  SizedBox(height: context.spacing.space6),
                ],
                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/auth/login'),
                    child: RichText(
                      text: TextSpan(
                        text: 'Déjà un compte ? ',
                        style: context.typography.bodyMd
                            .copyWith(color: c.fg2),
                        children: [
                          TextSpan(
                            text: 'Se connecter',
                            style: context.typography.bodyMd.copyWith(
                              color: c.fg1,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: context.spacing.space6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Shared auth pieces (inlined per file — TODO(extract))
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
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
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
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
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
