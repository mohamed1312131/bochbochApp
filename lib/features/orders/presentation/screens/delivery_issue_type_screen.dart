import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../domain/issue_models.dart';
import 'delivery_resolution_screen.dart';

/// Screen 1 of the Lost/Damaged flow — pick the issue type.
///
/// Carries an [IssueDraft] forward so the resolution screen can
/// preview restored stock and submit the full payload.
class DeliveryIssueTypeScreen extends StatefulWidget {
  const DeliveryIssueTypeScreen({super.key, required this.draft});
  final IssueDraft draft;

  @override
  State<DeliveryIssueTypeScreen> createState() =>
      _DeliveryIssueTypeScreenState();
}

class _DeliveryIssueTypeScreenState extends State<DeliveryIssueTypeScreen> {
  late IssueDraft _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
  }

  void _select(IssueType t) {
    setState(() => _draft = _draft.copyWith(issueType: t));
  }

  void _onContinue() {
    if (_draft.issueType == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeliveryResolutionScreen(draft: _draft),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final orderLabel = _draft.orderNumber ?? _draft.orderId;
    final canContinue = _draft.issueType != null;
    return Scaffold(
      backgroundColor: c.surface1,
      appBar: AppBar(title: const Text('Problème de livraison')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                context.spacing.space4,
                context.spacing.space3,
                context.spacing.space4,
                context.spacing.space4,
              ),
              children: [
                Text(
                  'Quel est le problème avec la commande #$orderLabel ?',
                  style: context.typography.body.copyWith(color: c.fg2),
                ),
                SizedBox(height: context.spacing.space5),
                _IssueTypeCard(
                  type: IssueType.notReceived,
                  icon: Icons.local_shipping_outlined,
                  description: 'La cliente n\'a jamais reçu sa commande',
                  selected: _draft.issueType == IssueType.notReceived,
                  onTap: () => _select(IssueType.notReceived),
                ),
                SizedBox(height: context.spacing.space3),
                _IssueTypeCard(
                  type: IssueType.damaged,
                  icon: Icons.warning_amber_rounded,
                  description: 'Article cassé ou abîmé à la livraison',
                  selected: _draft.issueType == IssueType.damaged,
                  onTap: () => _select(IssueType.damaged),
                ),
                SizedBox(height: context.spacing.space3),
                _IssueTypeCard(
                  type: IssueType.wrongAddress,
                  icon: Icons.location_off_outlined,
                  description: 'Livré au mauvais endroit',
                  selected: _draft.issueType == IssueType.wrongAddress,
                  onTap: () => _select(IssueType.wrongAddress),
                ),
              ],
            ),
          ),
          _Footer(
            canContinue: canContinue,
            onContinue: _onContinue,
          ),
        ],
      ),
    );
  }
}

// ── IssueTypeCard ─────────────────────────────────────────
class _IssueTypeCard extends StatelessWidget {
  const _IssueTypeCard({
    required this.type,
    required this.icon,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IssueType type;
  final IconData icon;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.radius.radiusCard),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? c.brandTealTint08 : c.surface0,
          border: Border.all(
            color: selected ? c.brandTeal : c.border1,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(context.radius.radiusCard),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? c.brandTeal : c.surface2,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 22,
                color: selected ? c.surface0 : c.fg2,
              ),
            ),
            SizedBox(width: context.spacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.label,
                    style: context.typography.h4.copyWith(color: c.fg1),
                  ),
                  SizedBox(height: context.spacing.space1),
                  Text(
                    description,
                    style:
                        context.typography.bodySmall.copyWith(color: c.fg3),
                  ),
                ],
              ),
            ),
            SizedBox(width: context.spacing.space2),
            // Radio
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: c.surface0,
                border: Border.all(
                  color: selected ? c.brandTeal : c.border2,
                  width: selected ? 1.5 : 1,
                ),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: selected
                  ? Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: c.brandTeal,
                        shape: BoxShape.circle,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  const _Footer({required this.canContinue, required this.onContinue});
  final bool canContinue;
  final VoidCallback onContinue;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          context.spacing.space4,
          context.spacing.space3,
          context.spacing.space4,
          context.spacing.space4,
        ),
        decoration: BoxDecoration(
          color: c.surface0,
          border: Border(top: BorderSide(color: c.border1)),
        ),
        child: DidoButton.primary(
          label: 'Continuer',
          onPressed: canContinue ? onContinue : null,
          enabled: canContinue,
        ),
      ),
    );
  }
}
