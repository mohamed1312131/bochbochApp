import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../providers/auth_provider.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({super.key, required this.email});
  final String email;

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  String? _error;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  // H7: latch so the auto-fire in _onChanged can't navigate twice when
  // the user backspaces and retypes the last digit. context.go is
  // idempotent in URL but the rebuild + extra state push is wasteful and
  // visible to the user.
  bool _navigated = false;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _cooldownTimer?.cancel();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_otp.length == 6) _proceed();
  }

  void _proceed() {
    if (_navigated) return;
    if (_otp.length < 6) {
      setState(() => _error = 'Entrez le code à 6 chiffres');
      return;
    }
    _navigated = true;
    context.go(
      '/auth/new-password',
      extra: {'email': widget.email, 'otp': _otp},
    );
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds--);
      }
    });
  }

  Future<void> _handleResend() async {
    if (_cooldownSeconds > 0) return;
    try {
      await ref
          .read(authRepositoryProvider)
          .resendForgotPasswordOtp(widget.email);
      if (!mounted) return;
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code renvoyé')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'envoi')),
      );
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: context.spacing.space8),
              _BackButton(
                  onTap: () => context.go('/auth/forgot-password')),
              SizedBox(height: context.spacing.space6),
              Text(
                'Entrez le code',
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
                      text: widget.email,
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
                label: 'Continuer',
                onPressed: _proceed,
              ),
              SizedBox(height: context.spacing.space6),
              Center(
                child: _cooldownSeconds > 0
                    ? Text(
                        'Renvoyer dans ${_cooldownSeconds}s',
                        style: context.typography.bodyMd
                            .copyWith(color: c.fg3),
                      )
                    : GestureDetector(
                        onTap: _handleResend,
                        child: RichText(
                          text: TextSpan(
                            text: 'Pas reçu le code ? ',
                            style: context.typography.bodyMd
                                .copyWith(color: c.fg2),
                            children: [
                              TextSpan(
                                text: 'Renvoyer',
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
