import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_border_radius.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/config/feature_flags.dart';
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
    final registerState = ref.watch(registerProvider);
    final isLoading = registerState.status == RegisterStatus.loading;

ref.listen(registerProvider, (_, next) {
  if (next.status == RegisterStatus.success) {
    context.go('/auth/verify-email');
  }
});

    // Google-login plumbing only matters when the flag is on. Without
    // it the button is hidden and loginProvider can never fire from
    // this screen, so the listener and watch would be dead code.
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
                const SizedBox(height: AppSpacing.xxxl),

                // Back button
                GestureDetector(
                  onTap: () => context.go('/auth/login'),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.appSurfaceL2,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: context.appTextPrimary,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Title
                Text(
                  'Create account',
                  style: AppTypography.h1.copyWith(
                    color: context.appTextPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Start your free 30-day trial',
                  style: AppTypography.body.copyWith(
                    color: context.appTextSecondary,
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Full name
                Text(
                  'Full Name',
                  style: AppTypography.body.copyWith(
                    color: context.appTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  height: 52,
                  child: TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    style: AppTypography.body,
                    decoration: const InputDecoration(
                      hintText: 'Amira Ben Ali',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Full name is required';
                      }
                      if (v.trim().length < 2) return 'Name too short';
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Email
                Text(
                  'Email',
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
                    decoration: const InputDecoration(
                      hintText: 'your@email.com',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email is required';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Password
                Text(
                  'Password',
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
                    textInputAction: TextInputAction.next,
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
                      if (v == null || v.isEmpty) return 'Password is required';
                      if (v.length < 8) return 'Minimum 8 characters';
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Confirm password
                Text(
                  'Confirm Password',
                  style: AppTypography.body.copyWith(
                    color: context.appTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  height: 52,
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    style: AppTypography.body,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: context.appTextTertiary,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscureConfirm = !_obscureConfirm,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (v != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ),

                // Error
                if (registerState.error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      registerState.error!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xxl),

                // Register button
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
                            'Create Account',
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
                          'Ou se connecter avec',
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
                    onPressed: (isLoading || isGoogleLoading)
                        ? null
                        : () => ref
                            .read(loginProvider.notifier)
                            .loginWithGoogle(),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                ],

                // Login link
                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/auth/login'),
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: AppTypography.body.copyWith(
                          color: context.appTextSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign In',
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
