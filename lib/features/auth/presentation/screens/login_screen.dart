import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_border_radius.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/i18n/l10n_context.dart';
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
    final l10n = context.l10n;
    final loginState = ref.watch(loginProvider);
    final isLoading = loginState.status == LoginStatus.loading;

    ref.listen(loginProvider, (_, next) {
      if (next.status == LoginStatus.success) {
        context.go('/home');
      }
    });

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xxxxxl),

                // Logo / Brand
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: context.appBrand,
                      borderRadius:
                          BorderRadius.circular(AppRadius.lg),
                    ),
                    child: const Icon(
                      Icons.bolt,
                      color: AppColors.white,
                      size: 36,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Title
                Center(
                  child: Text(
                    l10n.loginWelcomeBack,
                    style: AppTypography.h1.copyWith(
                      color: context.appTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Center(
                  child: Text(
                    l10n.loginSubtitle,
                    style: AppTypography.body.copyWith(
                      color: context.appTextSecondary,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxxl),

                // Email
                Text(
                  l10n.loginEmailLabel,
                  style: AppTypography.body.copyWith(
                    color: context.appTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  height: 52,
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    style: AppTypography.body,
                    decoration: InputDecoration(
                      hintText: l10n.loginEmailHint,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l10n.loginEmailRequired;
                      if (!v.contains('@')) return l10n.loginEmailInvalid;
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Password
                Text(
                  l10n.loginPasswordLabel,
                  style: AppTypography.body.copyWith(
                    color: context.appTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  height: 52,
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    style: AppTypography.body,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: context.appTextTertiary,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l10n.loginPasswordRequired;
                      if (v.length < 6) return l10n.loginPasswordMinLength;
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => context.go('/auth/forgot-password'),
                    child: Text(
                      l10n.loginForgotPassword,
                      style: AppTypography.body.copyWith(
                        color: context.appBrand,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Error message
                if (loginState.error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      loginState.error!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xxl),

                // Login button
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
                        borderRadius: BorderRadius.circular(AppRadius.lg),
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
                            l10n.loginSignInButton,
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                if (FeatureFlags.googleSigninEnabled) ...[
                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: context.appBorder)),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: Text(
                          l10n.loginOrSignInWith,
                          style: AppTypography.bodySmall.copyWith(
                            color: context.appTextTertiary,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: context.appBorder)),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Google sign-in button
                  GoogleSignInButton(
                    onPressed: isLoading
                        ? null
                        : () => ref
                            .read(loginProvider.notifier)
                            .loginWithGoogle(),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                ],

                // Register link
                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/auth/register'),
                    child: RichText(
                      text: TextSpan(
                        text: l10n.loginNoAccountQuestion,
                        style: AppTypography.body.copyWith(
                          color: context.appTextSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: l10n.loginSignUpLink,
                            style: AppTypography.body.copyWith(
                              color: context.appBrand,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
    );
  }
}