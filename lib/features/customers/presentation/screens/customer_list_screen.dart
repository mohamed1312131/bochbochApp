import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../../../../shared/providers/user_name_provider.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../../../shared/widgets/segment_chip.dart';
import '../../domain/customer_models.dart';
import '../providers/customer_provider.dart';

// TODO(home): wire to real data — boutique provider
const _mockBoutiqueName = 'Boutique Sania';
const _mockBoutiqueInitial = 'S';

// TODO(notifs): wire to real data — notifications provider
const _mockHasUnreadNotifs = true;

enum _SortOption { recentOrder, mostSpent, mostOrders }

const _segmentCodes = <String?>[
  null,
  'VIP',
  'LOYAL',
  'NEW',
  'AT_RISK',
  'RETURNER',
];

String _segmentLabel(String? code) => switch (code) {
      null => 'Tous',
      'VIP' => 'VIP',
      'LOYAL' => 'Fidèle',
      'NEW' => 'Nouveau',
      'AT_RISK' => 'À risque',
      'RETURNER' => 'De retour',
      _ => code,
    };

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() =>
      _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String _query = '';
  String? _segmentFilter;
  _SortOption _sort = _SortOption.recentOrder;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(customerListProvider.notifier).loadMore();
    }
  }

  List<CustomerLean> _applyFiltersAndSort(List<CustomerLean> customers) {
    final q = _query;
    final filtered = customers.where((c) {
      final matchesQuery = q.isEmpty ||
          c.name.toLowerCase().contains(q) ||
          c.phone.contains(q);
      final matchesSegment =
          _segmentFilter == null || c.segment == _segmentFilter;
      return matchesQuery && matchesSegment;
    }).toList();

    filtered.sort((a, b) => switch (_sort) {
          _SortOption.recentOrder => (b.lastOrderDate ?? DateTime(0))
              .compareTo(a.lastOrderDate ?? DateTime(0)),
          _SortOption.mostSpent => b.totalSpent.compareTo(a.totalSpent),
          _SortOption.mostOrders => b.totalOrders.compareTo(a.totalOrders),
        });
    return filtered;
  }

  Future<void> _openSortSheet() async {
    final picked = await showModalBottomSheet<_SortOption>(
      context: context,
      backgroundColor: context.colors.surface0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.radius.radiusSheet),
        ),
      ),
      builder: (ctx) => _SortSheet(current: _sort),
    );
    if (picked != null && mounted) {
      setState(() => _sort = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final customersAsync = ref.watch(customerListProvider);
    final userAsync = ref.watch(userNameProvider);
    final userInitial = userAsync.maybeWhen(
      data: (name) => name.isNotEmpty ? name[0].toUpperCase() : 'M',
      orElse: () => 'M',
    );

    return Scaffold(
      backgroundColor: c.surface0,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.spacing.screenEdge,
                context.spacing.space4,
                context.spacing.screenEdge,
                context.spacing.space2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _BoutiqueChip(),
                  _UserAvatar(initial: userInitial),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.spacing.screenEdge,
                vertical: context.spacing.space3,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Clients',
                  style: context.typography.h1.copyWith(color: c.fg1),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.spacing.screenEdge,
                0,
                context.spacing.screenEdge,
                context.spacing.space3,
              ),
              child: _SearchInput(
                controller: _searchController,
                hint: 'Nom, téléphone…',
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.spacing.screenEdge,
                0,
                context.spacing.screenEdge,
                context.spacing.space3,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SegmentFilter(
                      selected: _segmentFilter,
                      onSelected: (s) =>
                          setState(() => _segmentFilter = s),
                    ),
                  ),
                  SizedBox(width: context.spacing.space2),
                  _SortButton(onTap: _openSortSheet),
                ],
              ),
            ),
            Expanded(
              child: customersAsync.when(
                loading: () => const _ListSkeleton(),
                error: (_, __) => _ErrorState(
                  onRetry: () =>
                      ref.read(customerListProvider.notifier).refresh(),
                ),
                data: (customers) {
                  if (customers.isEmpty) return const _EmptyState();
                  final filtered = _applyFiltersAndSort(customers);
                  if (filtered.isEmpty) {
                    return _NoSearchResults(query: _query);
                  }
                  return RefreshIndicator(
                    color: c.fg1,
                    onRefresh: () =>
                        ref.read(customerListProvider.notifier).refresh(),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        context.spacing.screenEdge,
                        0,
                        context.spacing.screenEdge,
                        100,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: context.spacing.space3,
                            ),
                            child: Text(
                              'CLIENTS · ${filtered.length}',
                              style: context.typography.label.copyWith(
                                color: c.fg3,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          _CustomerList(customers: filtered),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Header pieces (duplicated — TODO(extract))
// ════════════════════════════════════════════════════════════
class _BoutiqueChip extends StatelessWidget {
  const _BoutiqueChip();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ScaleTap(
      onTap: () {
        // TODO(home): open boutique switcher bottom sheet
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.surface1,
          border: Border.all(color: c.border1),
          borderRadius: BorderRadius.circular(context.radius.radiusInput),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: c.brandTeal,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _mockBoutiqueInitial,
                style: context.typography.label.copyWith(
                  fontWeight: FontWeight.w700,
                  color: c.surface0,
                ),
              ),
            ),
            SizedBox(width: context.spacing.space2),
            Text(
              _mockBoutiqueName,
              style: context.typography.bodyMd.copyWith(color: c.fg1),
            ),
            SizedBox(width: context.spacing.space1),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: c.fg3),
          ],
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.initial});
  final String initial;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ScaleTap(
      onTap: () => context.push('/settings'),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: c.brandTealTint08,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: context.typography.bodySmallMd.copyWith(
                  fontWeight: FontWeight.w700,
                  color: c.brandTeal,
                ),
              ),
            ),
            if (_mockHasUnreadNotifs)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: c.coral,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.surface0, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Search input
// ════════════════════════════════════════════════════════════
class _SearchInput extends StatelessWidget {
  const _SearchInput({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(context.radius.radiusInput),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: context.typography.input.copyWith(color: c.fg1),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: context.typography.input.copyWith(color: c.fg3),
          prefixIcon: Icon(Icons.search_rounded, color: c.fg3, size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          isDense: true,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Segment filter strip
// ════════════════════════════════════════════════════════════
class _SegmentFilter extends StatelessWidget {
  const _SegmentFilter({
    required this.selected,
    required this.onSelected,
  });

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _segmentCodes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final code = _segmentCodes[i];
          return _SegmentFilterChip(
            label: _segmentLabel(code),
            selected: selected == code,
            onTap: () => onSelected(code),
          );
        },
      ),
    );
  }
}

class _SegmentFilterChip extends StatelessWidget {
  const _SegmentFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? c.fg1 : c.surface2,
          borderRadius: BorderRadius.circular(context.radius.radiusChip),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: context.typography.tabPill.copyWith(
            color: selected ? c.surface0 : c.fg2,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Sort button + sheet
// ════════════════════════════════════════════════════════════
class _SortButton extends StatelessWidget {
  const _SortButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ScaleTap(
      pressedScale: 0.94,
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(context.radius.radiusChip),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.sort_rounded, size: 16, color: c.fg1),
      ),
    );
  }
}

class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.current});
  final _SortOption current;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.spacing.space4,
          context.spacing.space3,
          context.spacing.space4,
          context.spacing.space4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border1,
                  borderRadius: BorderRadius.circular(
                      context.radius.radiusFull),
                ),
              ),
            ),
            SizedBox(height: context.spacing.space4),
            Text(
              'Trier par',
              style: context.typography.h4.copyWith(color: c.fg1),
            ),
            SizedBox(height: context.spacing.space2),
            _SortTile(
              label: 'Plus récente',
              icon: Icons.access_time_rounded,
              selected: current == _SortOption.recentOrder,
              onTap: () => Navigator.pop(context, _SortOption.recentOrder),
            ),
            _SortTile(
              label: 'Plus dépensé',
              icon: Icons.payments_outlined,
              selected: current == _SortOption.mostSpent,
              onTap: () => Navigator.pop(context, _SortOption.mostSpent),
            ),
            _SortTile(
              label: 'Plus de commandes',
              icon: Icons.receipt_long_outlined,
              selected: current == _SortOption.mostOrders,
              onTap: () => Navigator.pop(context, _SortOption.mostOrders),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortTile extends StatelessWidget {
  const _SortTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? c.fg1 : c.fg3;
    return _ScaleTap(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.spacing.space3),
        child: Row(
          children: [
            Icon(icon, size: 18, color: fg),
            SizedBox(width: context.spacing.space3),
            Expanded(
              child: Text(
                label,
                style: context.typography.bodyMd.copyWith(
                  color: selected ? c.fg1 : c.fg2,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (selected) Icon(Icons.check_rounded, size: 18, color: c.fg1),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Customer list (single bordered card with internal dividers)
// ════════════════════════════════════════════════════════════
class _CustomerList extends StatelessWidget {
  const _CustomerList({required this.customers});
  final List<CustomerLean> customers;

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
      child: Column(
        children: [
          for (var i = 0; i < customers.length; i++) ...[
            _CustomerRow(customer: customers[i]),
            if (i != customers.length - 1)
              Container(
                height: 1,
                margin: const EdgeInsets.only(left: 60),
                color: c.border1,
              ),
          ],
        ],
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({required this.customer});
  final CustomerLean customer;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final initial = customer.name.isNotEmpty
        ? customer.name[0].toUpperCase()
        : '?';

    return _ScaleTap(
      onTap: () => context.push('/customers/${customer.id}'),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.space4,
          vertical: context.spacing.space3,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.surface2,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: context.typography.h4.copyWith(
                  color: c.fg1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: context.spacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.typography.h4.copyWith(color: c.fg1),
                  ),
                  SizedBox(height: context.spacing.space1),
                  Text(
                    customer.phone,
                    style: context.typography.bodySmall
                        .copyWith(color: c.fg3),
                  ),
                ],
              ),
            ),
            SizedBox(width: context.spacing.space2),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  MillimesFormatter.format(customer.totalSpent),
                  style: context.typography.bodyMd.copyWith(
                    color: c.fg1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: context.spacing.space1),
                if (customer.segment != null)
                  SegmentChip(segment: customer.segment!)
                else
                  Text(
                    customer.totalOrders == 1
                        ? '1 commande'
                        : '${customer.totalOrders} commandes',
                    style: context.typography.bodySmall
                        .copyWith(color: c.fg3),
                  ),
              ],
            ),
            SizedBox(width: context.spacing.space2),
            Icon(Icons.chevron_right_rounded, size: 16, color: c.fg3),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Empty / no-results / error / skeleton
// ════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded, size: 48, color: c.fg3),
            SizedBox(height: context.spacing.space3),
            Text(
              'Aucun client',
              style: context.typography.h3.copyWith(color: c.fg2),
            ),
            SizedBox(height: context.spacing.space1),
            Text(
              'Les clients sont ajoutés automatiquement lors de la création de commandes.',
              textAlign: TextAlign.center,
              style: context.typography.bodyMd.copyWith(color: c.fg3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 32, color: c.fg3),
            SizedBox(height: context.spacing.space2),
            Text(
              query.isEmpty
                  ? 'Aucun résultat'
                  : 'Aucun résultat pour « $query »',
              textAlign: TextAlign.center,
              style: context.typography.bodyMd.copyWith(color: c.fg3),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: c.fg3),
            SizedBox(height: context.spacing.space3),
            Text(
              'Impossible de charger les clients',
              textAlign: TextAlign.center,
              style: context.typography.h4.copyWith(color: c.fg1),
            ),
            SizedBox(height: context.spacing.space4),
            DidoButton.secondary(
              label: 'Réessayer',
              onPressed: onRetry,
              fullWidth: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        context.spacing.screenEdge,
        0,
        context.spacing.screenEdge,
        100,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface1,
          border: Border.all(color: c.border1),
          borderRadius: BorderRadius.circular(context.radius.radiusCard),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(6, (i) {
            return Container(
              height: 68,
              padding: EdgeInsets.symmetric(
                horizontal: context.spacing.space4,
                vertical: context.spacing.space3,
              ),
              decoration: BoxDecoration(
                border: i == 5
                    ? null
                    : Border(
                        bottom: BorderSide(color: c.border1, width: 1),
                      ),
              ),
              child: Row(
                children: [
                  _shimmer(
                    context,
                    width: 40,
                    height: 40,
                    radius: 9999,
                  ),
                  SizedBox(width: context.spacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _shimmer(context, width: 140, height: 14, radius: 4),
                        SizedBox(height: context.spacing.space1),
                        _shimmer(context, width: 90, height: 12, radius: 4),
                      ],
                    ),
                  ),
                  _shimmer(context, width: 60, height: 14, radius: 4),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _shimmer(
    BuildContext context, {
    required double width,
    required double height,
    required double radius,
  }) {
    final c = context.colors;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(radius),
      ),
    ).animate(onPlay: (ctrl) => ctrl.repeat()).shimmer(
          duration: const Duration(milliseconds: 1500),
          color: c.surface3,
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
