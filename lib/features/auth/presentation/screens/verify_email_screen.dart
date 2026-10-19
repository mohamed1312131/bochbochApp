import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/observability/posthog_service.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../data/auth_repository.dart';
import '../providers/auth_provider.dart';

const _onboardingUserIdKey = 'onboarding_user_id';
const _onboardingStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    // H6: the auto-fire from `_onChanged` (`if (_otp.length == 6) _verify()`)
    // can trigger _verify multiple times in fast typing or paste/backspace
    // sequences. Without this guard the screen issued duplicate
    // POST /auth/verify-email calls — second one usually 400'd, but the
    // backend OTP attempts counter ticked twice.
    if (_isLoading) return;

    if (_otp.length < 6) {
      setState(() => _error = 'Entrez le code à 6 chiffres');
      return;
    }

    final registerState = ref.read(registerProvider);
    final userId = registerState.userId;
    final email = registerState.email;

    if (userId == null || email == null) {
      setState(() =>
          _error = 'Session expirée. Recommencez l\'inscription.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response =
          await AuthRepository().verifyEmail(userId: userId, otp: _otp);
      await ref
          .read(authStateProvider.notifier)
          .saveToken(response.accessToken);
      await _onboardingStorage.write(
        key: _onboardingUserIdKey,
        value: response.user.id,
      );
      await PostHogService.identify(response.user.id);
      if (mounted) context.go('/home');
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_otp.length == 6) _verify();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final registerState = ref.watch(registerProvider);
    final email = registerState.email ?? '';

    return Scaffold(
      backgroundColor: c.surface0,
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              EdgeInsets.symmetric(horizontal: context.spacing.screenEdge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: context.spacing.space8),
              _BackButton(onTap: () => context.go('/auth/register')),
              SizedBox(height: context.spacing.space6),
              Text(
                'Vérifiez vos emails',
                style: context.typography.h1.copyWith(color: c.fg1),
              ),
              SizedBox(height: context.spacing.space2),
              RichText(
                text: TextSpan(
                  text: 'Nous avons envoyé un code à 6 chiffres à ',
                  style:
                      context.typography.bodyMd.copyWith(color: c.fg2),
                  children: [
                    TextSpan(
                      text: email,
                      style: context.typography.bodyMd.copyWith(
                        color: c.fg1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.spacing.space8),
              _OtpRow(
                controllers: _controllers,
                focusNodes: _focusNodes,
                onChanged: _onChanged,
              ),
              if (_error != null) ...[
                SizedBox(height: context.spacing.space4),
                _ErrorBanner(message: _error!),
              ],
              SizedBox(height: context.spacing.space6),
              DidoButton.primary(
                label: 'Vérifier l\'email',
                loading: _isLoading,
                onPressed: _verify,
              ),
              SizedBox(height: context.spacing.space6),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// OTP row + shared pieces (inlined per file)
// ════════════════════════════════════════════════════════════
class _OtpRow extends StatelessWidget {
  const _OtpRow({
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(String value, int index) onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(context.radius.radiusInput);
    OutlineInputBorder b(Color color, double width) => OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: color, width: width));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 48,
          height: 56,
          child: TextFormField(
            controller: controllers[index],
            focusNode: focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: context.typography.h3.copyWith(color: c.fg1),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.zero,
              filled: true,
              fillColor: c.surface1,
              border: b(c.border1, 1),
              enabledBorder: b(c.border1, 1),
              focusedBorder: b(c.fg1, 1.5),
            ),
            onChanged: (value) => onChanged(value, index),
          ),
        );
      }),
    );
  }
}

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
