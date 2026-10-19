import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/i18n/l10n_context.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../providers/auth_provider.dart';
import '../widgets/google_signin_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(loginProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final loginState = ref.watch(loginProvider);
    final isLoading = loginState.status == LoginStatus.loading;

    ref.listen(loginProvider, (_, next) {
      if (next.status == LoginStatus.success) {
        context.go('/home');
      }
    });

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
                SizedBox(height: context.spacing.space12),
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: c.brandTeal,
                      borderRadius:
                          BorderRadius.circular(context.radius.radiusSheet),
                    ),
                    child: Icon(Icons.bolt, color: c.surface0, size: 36),
                  ),
                ),
                SizedBox(height: context.spacing.space6),
                Center(
                  child: Text(
                    l10n.loginWelcomeBack,
                    style: context.typography.h1.copyWith(color: c.fg1),
                  ),
                ),
                SizedBox(height: context.spacing.space2),
                Center(
                  child: Text(
                    l10n.loginSubtitle,
                    style: context.typography.bodyMd.copyWith(color: c.fg2),
                  ),
                ),
                SizedBox(height: context.spacing.space8),
                _FieldLabel(text: l10n.loginEmailLabel),
                SizedBox(height: context.spacing.space2),
                _AuthField(
                  controller: _emailController,
                  hint: l10n.loginEmailHint,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return l10n.loginEmailRequired;
                    }
                    if (!v.contains('@')) return l10n.loginEmailInvalid;
                    return null;
                  },
                ),
                SizedBox(height: context.spacing.space4),
                _FieldLabel(text: l10n.loginPasswordLabel),
                SizedBox(height: context.spacing.space2),
                _AuthField(
                  controller: _passwordController,
                  hint: '••••••••',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  suffixIcon: _ObscureToggle(
                    obscured: _obscurePassword,
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return l10n.loginPasswordRequired;
                    }
                    if (v.length < 6) return l10n.loginPasswordMinLength;
                    return null;
                  },
                ),
                SizedBox(height: context.spacing.space3),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => context.go('/auth/forgot-password'),
                    child: Text(
                      l10n.loginForgotPassword,
                      style: context.typography.bodyMd.copyWith(
                        color: c.fg1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (loginState.error != null) ...[
                  SizedBox(height: context.spacing.space3),
                  _ErrorBanner(message: loginState.error!),
                ],
                SizedBox(height: context.spacing.space6),
                DidoButton.primary(
                  label: l10n.loginSignInButton,
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
                          l10n.loginOrSignInWith,
                          style: context.typography.bodySmall
                              .copyWith(color: c.fg3),
                        ),
                      ),
                      Expanded(child: Divider(color: c.border1)),
                    ],
                  ),
                  SizedBox(height: context.spacing.space4),
                  GoogleSignInButton(
                    onPressed: isLoading
                        ? null
                        : () => ref
                            .read(loginProvider.notifier)
                            .loginWithGoogle(),
                  ),
                  SizedBox(height: context.spacing.space6),
                ],
                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/auth/register'),
                    child: RichText(
                      text: TextSpan(
                        text: l10n.loginNoAccountQuestion,
                        style: context.typography.bodyMd
                            .copyWith(color: c.fg2),
                        children: [
                          TextSpan(
                            text: l10n.loginSignUpLink,
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
// Shared auth field pieces
// ════════════════════════════════════════════════════════════
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
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(context.radius.radiusInput);
    OutlineInputBorder border(Color color, double width) =>
        OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: color, width: width));

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
        border: border(c.border1, 1),
        enabledBorder: border(c.border1, 1),
        focusedBorder: border(c.fg1, 1.5),
        errorBorder: border(c.red, 1),
        focusedErrorBorder: border(c.red, 1.5),
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
