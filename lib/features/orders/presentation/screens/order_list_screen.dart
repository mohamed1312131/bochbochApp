import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../../../../shared/providers/user_name_provider.dart';
import '../../../../shared/widgets/order_flag_pill.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../domain/order_models.dart';
import '../providers/order_provider.dart';
import '../widgets/bulk_actions_sheet.dart';

// TODO(home): wire to real data — boutique provider
const _mockBoutiqueName = 'Boutique Sania';
const _mockBoutiqueInitial = 'S';

// TODO(notifs): wire to real data — notifications provider
const _mockHasUnreadNotifs = true;

const _kDateLabels = <String, String>{
  'all': 'Toute la période',
  'today': "Aujourd'hui",
  '3days': '3 derniers jours',
  'week': 'Cette semaine',
  'month': 'Ce mois-ci',
};

const _kStatusLabels = <String, String>{
  'PENDING': 'En attente',
  'CONFIRMED': 'Confirmée',
  'SHIPPED': 'Expédiée',
  'DELIVERED': 'Livrée',
  'CANCELLED': 'Annulée',
};

enum _OrdersTab { toutes, enAttente, livrees, retours }

String? _statusForTab(_OrdersTab t) => switch (t) {
      _OrdersTab.toutes => null,
      _OrdersTab.enAttente => 'PENDING',
      _OrdersTab.livrees => 'DELIVERED',
      _OrdersTab.retours => null, // returns are out-of-band
    };

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  _OrdersTab _selectedTab = _OrdersTab.toutes;
  String? _extraStatus; // status from filter sheet that doesn't match a tab
  String _dateFilter = 'all';
  String _searchQuery = '';

  // F13 — multi-select state. Long-press on any row enters the mode;
  // tap toggles the row's selection.
  bool _multiSelect = false;
  final Set<String> _selectedOrderIds = <String>{};

  bool get _isReturns => _selectedTab == _OrdersTab.retours;

  String? get _effectiveStatus =>
      _isReturns ? null : (_extraStatus ?? _statusForTab(_selectedTab));

  bool get _hasExtraFilters =>
      _dateFilter != 'all' || _extraStatus != null;

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
    if (_isReturns) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(orderListProvider.notifier).loadMore();
    }
  }

  bool _matchesDateFilter(DateTime date) {
    final now = DateTime.now();
    return switch (_dateFilter) {
      'today' => date.year == now.year &&
          date.month == now.month &&
          date.day == now.day,
      '3days' => date.isAfter(now.subtract(const Duration(days: 3))),
      'week' => date.isAfter(now.subtract(const Duration(days: 7))),
      'month' => date.year == now.year && date.month == now.month,
      _ => true,
    };
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OrderFilterSheet(
        initialDate: _dateFilter,
        initialStatus: _effectiveStatus,
        onApply: (date, status) {
          setState(() {
            _dateFilter = date;
            // Map sheet status back to tab + extra fields.
            switch (status) {
              case null:
                _selectedTab = _OrdersTab.toutes;
                _extraStatus = null;
              case 'PENDING':
                _selectedTab = _OrdersTab.enAttente;
                _extraStatus = null;
              case 'DELIVERED':
                _selectedTab = _OrdersTab.livrees;
                _extraStatus = null;
              default:
                _selectedTab = _OrdersTab.toutes;
                _extraStatus = status;
            }
          });
        },
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _dateFilter = 'all';
      _extraStatus = null;
    });
  }

  void _enterMultiSelect(String firstOrderId) {
    setState(() {
      _multiSelect = true;
      _selectedOrderIds
        ..clear()
        ..add(firstOrderId);
    });
  }

  void _exitMultiSelect() {
    setState(() {
      _multiSelect = false;
      _selectedOrderIds.clear();
    });
  }

  void _toggleSelection(String orderId) {
    setState(() {
      if (_selectedOrderIds.contains(orderId)) {
        _selectedOrderIds.remove(orderId);
        if (_selectedOrderIds.isEmpty) _multiSelect = false;
      } else {
        _selectedOrderIds.add(orderId);
      }
    });
  }

  Future<void> _openBulkActions() async {
    if (_selectedOrderIds.isEmpty) return;
    final ok = await showBulkActionsSheet(
      context: context,
      orderIds: _selectedOrderIds.toList(growable: false),
    );
    if (ok && mounted) _exitMultiSelect();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ordersAsync = ref.watch(orderListProvider);
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
            // Header
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
            // Title
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.spacing.screenEdge,
                vertical: context.spacing.space3,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Commandes',
                  style: context.typography.h1.copyWith(color: c.fg1),
                ),
              ),
            ),
            // Search + filter
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.spacing.screenEdge,
              ),
              child: _SearchRow(
                controller: _searchController,
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
                hasActiveFilters: _hasExtraFilters,
                onFilterTap: _showFilterSheet,
              ),
            ),
            SizedBox(height: context.spacing.space3),
            // Tab strip
            _TabStrip(
              selected: _selectedTab,
              onSelect: (t) => setState(() => _selectedTab = t),
            ),
            // Active filter pills
            if (_hasExtraFilters)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.spacing.screenEdge,
                  context.spacing.space3,
                  context.spacing.screenEdge,
                  0,
                ),
                child: _ActiveFilterRow(
                  dateFilter: _dateFilter,
                  extraStatus: _extraStatus,
                  onRemoveDate: () => setState(() => _dateFilter = 'all'),
                  onRemoveStatus: () => setState(() => _extraStatus = null),
                  onClearAll: _clearFilters,
                ),
              ),
            // Content
            Expanded(
              child: _isReturns
                  ? const _RetoursEmptyState()
                  : ordersAsync.when(
                      loading: () => const _OrderListSkeleton(),
                      error: (e, _) => _ErrorState(
                        onRetry: () =>
                            ref.read(orderListProvider.notifier).refresh(),
                      ),
                      data: (orders) {
                        final filtered = _applyFilters(orders);
                        if (orders.isEmpty) return const _OrdersEmptyState();
                        if (filtered.isEmpty) {
                          return _NoMatchState(onClear: _clearFilters);
                        }
                        return RefreshIndicator(
                          color: c.fg1,
                          onRefresh: () =>
                              ref.read(orderListProvider.notifier).refresh(),
                          child: _OrdersList(
                            orders: filtered,
                            scrollController: _scrollController,
                            multiSelect: _multiSelect,
                            selectedIds: _selectedOrderIds,
                            onLongPress: _enterMultiSelect,
                            onTapSelect: _toggleSelection,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          _multiSelect ? null : const _OrdersFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _multiSelect
          ? _MultiSelectActionBar(
              count: _selectedOrderIds.length,
              onCancel: _exitMultiSelect,
              onActions: _openBulkActions,
            )
          : null,
    );
  }

  List<OrderLean> _applyFilters(List<OrderLean> orders) {
    final status = _effectiveStatus;
    return orders.where((o) {
      final matchesSearch = _searchQuery.isEmpty ||
          o.customerName.toLowerCase().contains(_searchQuery) ||
          o.customerPhone.toLowerCase().contains(_searchQuery) ||
          o.orderNumber.toLowerCase().contains(_searchQuery);
      final matchesDate = _matchesDateFilter(o.createdAt);
      final matchesStatus = status == null || o.status == status;
      return matchesSearch && matchesDate && matchesStatus;
    }).toList();
  }
}

// ════════════════════════════════════════════════════════════
// Reusable: scale + haptic tap feedback (no Material ripple)
// TODO(extract): duplicates _ScaleTap in home_screen.dart — promote
// to lib/shared/widgets/scale_tap.dart in a follow-up prompt.
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

// ════════════════════════════════════════════════════════════
// Header pieces — duplicate of home_screen's private widgets.
// TODO(extract): promote BoutiqueChip + UserAvatar to lib/shared/widgets/
// in a follow-up prompt and delete these duplicates.
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
// Search row + filter button (§3.8)
// ════════════════════════════════════════════════════════════
class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.controller,
    required this.onChanged,
    required this.hasActiveFilters,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool hasActiveFilters;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(context.radius.radiusInput),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: context.typography.input.copyWith(color: c.fg1),
              decoration: InputDecoration(
                hintText: 'Nom, téléphone…',
                hintStyle:
                    context.typography.input.copyWith(color: c.fg3),
                prefixIcon:
                    Icon(Icons.search_rounded, color: c.fg3, size: 20),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14),
                isDense: true,
              ),
            ),
          ),
        ),
        SizedBox(width: context.spacing.space2),
        _ScaleTap(
          onTap: onFilterTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: c.surface1,
                    border: Border.all(color: c.border1),
                    borderRadius:
                        BorderRadius.circular(context.radius.radiusInput),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.tune_rounded, size: 20, color: c.fg1),
                ),
                if (hasActiveFilters)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: c.coral,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Tab strip (§3.7) — underline-only active state
// ════════════════════════════════════════════════════════════
class _TabStrip extends StatelessWidget {
  const _TabStrip({required this.selected, required this.onSelect});
  final _OrdersTab selected;
  final ValueChanged<_OrdersTab> onSelect;

  static const _entries = <(_OrdersTab, String)>[
    (_OrdersTab.toutes, 'Toutes'),
    (_OrdersTab.enAttente, 'En attente'),
    (_OrdersTab.livrees, 'Livrées'),
    (_OrdersTab.retours, 'Retours'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border1, width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: context.spacing.screenEdge),
        child: Row(
          children: [
            for (final (tab, label) in _entries) ...[
              _Tab(
                label: label,
                active: selected == tab,
                onTap: () => onSelect(tab),
              ),
              SizedBox(width: context.spacing.space6),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ScaleTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: context.motion.base,
        curve: context.motion.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? c.fg1 : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: context.typography.h4.copyWith(
            color: active ? c.fg1 : c.fg3,
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Active filter pill row
// ════════════════════════════════════════════════════════════
class _ActiveFilterRow extends StatelessWidget {
  const _ActiveFilterRow({
    required this.dateFilter,
    required this.extraStatus,
    required this.onRemoveDate,
    required this.onRemoveStatus,
    required this.onClearAll,
  });

  final String dateFilter;
  final String? extraStatus;
  final VoidCallback onRemoveDate;
  final VoidCallback onRemoveStatus;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Icon(Icons.filter_list_rounded, size: 14, color: c.fg3),
        SizedBox(width: context.spacing.space2),
        if (dateFilter != 'all')
          _ActivePill(
            label: _kDateLabels[dateFilter] ?? dateFilter,
            onRemove: onRemoveDate,
          ),
        if (extraStatus != null) ...[
          SizedBox(width: context.spacing.space2),
          _ActivePill(
            label: _kStatusLabels[extraStatus!] ?? extraStatus!,
            onRemove: onRemoveStatus,
          ),
        ],
        const Spacer(),
        _ScaleTap(
          onTap: onClearAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(
              'Tout effacer',
              style: context.typography.bodySmallMd.copyWith(color: c.coralFg),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivePill extends StatelessWidget {
  const _ActivePill({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(context.radius.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: context.typography.tabPill.copyWith(color: c.fg1),
          ),
          SizedBox(width: context.spacing.space1),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 12, color: c.fg2),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Orders list — single card with internal dividers (§3.5)
// ════════════════════════════════════════════════════════════
class _OrdersList extends ConsumerWidget {
  const _OrdersList({
    required this.orders,
    required this.scrollController,
    required this.multiSelect,
    required this.selectedIds,
    required this.onLongPress,
    required this.onTapSelect,
  });
  final List<OrderLean> orders;
  final ScrollController scrollController;
  final bool multiSelect;
  final Set<String> selectedIds;
  final ValueChanged<String> onLongPress;
  final ValueChanged<String> onTapSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(
        context.spacing.screenEdge,
        context.spacing.space3,
        context.spacing.screenEdge,
        96,
      ),
      children: [
        Container(
          decoration: BoxDecoration(
            color: c.surface1,
            border: Border.all(color: c.border1),
            borderRadius: BorderRadius.circular(context.radius.radiusCard),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < orders.length; i++) ...[
                _OrderRow(
                  order: orders[i],
                  onStatusChanged: () =>
                      ref.read(orderListProvider.notifier).refresh(),
                  multiSelect: multiSelect,
                  selected: selectedIds.contains(orders[i].id),
                  onLongPress: () => onLongPress(orders[i].id),
                  onTapSelect: () => onTapSelect(orders[i].id),
                ),
                if (i < orders.length - 1)
                  Container(
                    height: 1,
                    color: c.border1,
                    margin: EdgeInsets.only(left: context.spacing.space4 * 2),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Order row (§3.5) with swipe-to-advance-status
// ════════════════════════════════════════════════════════════
class _OrderRow extends ConsumerWidget {
  const _OrderRow({
    required this.order,
    required this.onStatusChanged,
    required this.multiSelect,
    required this.selected,
    required this.onLongPress,
    required this.onTapSelect,
  });
  final OrderLean order;
  final VoidCallback onStatusChanged;
  final bool multiSelect;
  final bool selected;
  final VoidCallback onLongPress;
  final VoidCallback onTapSelect;

  String? _nextStatus(String s) => switch (s) {
        'PENDING' => 'CONFIRMED',
        'CONFIRMED' => 'SHIPPED',
        'SHIPPED' => 'DELIVERED',
        _ => null,
      };

  Future<void> _advance(
    BuildContext context,
    WidgetRef ref,
    String next,
  ) async {
    HapticFeedback.mediumImpact();
    try {
      await ref.read(orderRepositoryProvider).updateStatus(order.id, next);
      onStatusChanged();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: context.colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final next = _nextStatus(order.status);

    final rowContent = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.space4,
        vertical: context.spacing.space3,
      ),
      child: Row(
        children: [
          // Multi-select checkbox replaces the chevron when in mode.
          if (multiSelect) ...[
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? c.brandTeal : c.surface0,
                border: Border.all(
                  color: selected ? c.brandTeal : c.border2,
                  width: 1.5,
                ),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: selected
                  ? Icon(Icons.check, size: 14, color: c.surface0)
                  : null,
            ),
            SizedBox(width: context.spacing.space3),
          ],
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.surface2,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              order.customerName.isNotEmpty
                  ? order.customerName[0].toUpperCase()
                  : '?',
              style: context.typography.h4.copyWith(color: c.fg1),
            ),
          ),
          SizedBox(width: context.spacing.space3),
            // Body
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.typography.h4.copyWith(color: c.fg1),
                        ),
                      ),
                      SizedBox(width: context.spacing.space2),
                      Text(
                        MillimesFormatter.format(order.netRevenue),
                        textAlign: TextAlign.end,
                        style: context.typography.bodyMd.copyWith(color: c.fg1),
                      ),
                    ],
                  ),
                  SizedBox(height: context.spacing.space1),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${order.customerPhone} · ${order.orderNumber}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              context.typography.bodySmall.copyWith(color: c.fg3),
                        ),
                      ),
                      SizedBox(width: context.spacing.space2),
                      Text(
                        DateFormatter.relative(order.createdAt),
                        style:
                            context.typography.bodySmall.copyWith(color: c.fg3),
                      ),
                    ],
                  ),
                  SizedBox(height: context.spacing.space2),
                  StatusBadge(status: order.status),
                  if (order.flags.isNotEmpty) ...[
                    SizedBox(height: context.spacing.space2),
                    _FlagRow(order: order),
                  ],
                ],
              ),
            ),
            SizedBox(width: context.spacing.space2),
            if (!multiSelect)
              Icon(Icons.chevron_right_rounded, size: 16, color: c.fg3),
          ],
        ),
      );

    // Wrap with gesture handlers. In multi-select mode, taps toggle
    // selection and long-press is a no-op; in normal mode, tap opens
    // the order detail and long-press enters multi-select.
    final row = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: multiSelect
          ? onTapSelect
          : () => context.push('/orders/${order.id}'),
      onLongPress: multiSelect ? null : onLongPress,
      child: Container(
        color: multiSelect && selected
            ? c.brandTealTint08
            : Colors.transparent,
        child: rowContent,
      ),
    );

    // Swipe-to-advance is disabled while in multi-select mode.
    if (multiSelect || next == null) return row;

    return Dismissible(
      key: Key(order.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _advance(context, ref, next);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: context.spacing.space4),
        color: c.fg1,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(Icons.check_circle_outline_rounded,
                color: c.surface0, size: 22),
            SizedBox(height: context.spacing.space1),
            Text(
              _kStatusLabels[next] ?? next,
              style: context.typography.tabPill.copyWith(color: c.surface0),
            ),
          ],
        ),
      ),
      child: row,
    );
  }
}

// ════════════════════════════════════════════════════════════
// Empty / Error / NoMatch / Skeleton
// ════════════════════════════════════════════════════════════
class _OrdersEmptyState extends StatelessWidget {
  const _OrdersEmptyState();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: c.fg3),
            SizedBox(height: context.spacing.space3),
            Text(
              'Aucune commande',
              style: context.typography.h3.copyWith(color: c.fg2),
            ),
            SizedBox(height: context.spacing.space1),
            Text(
              "Tu n'as pas encore de commandes.",
              textAlign: TextAlign.center,
              style: context.typography.bodyMd.copyWith(color: c.fg3),
            ),
            SizedBox(height: context.spacing.space4),
            _PrimaryCta(
              label: 'Nouvelle commande',
              onTap: () => context.push('/orders/add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RetoursEmptyState extends StatelessWidget {
  const _RetoursEmptyState();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_return_outlined, size: 48, color: c.fg3),
            SizedBox(height: context.spacing.space3),
            Text(
              'Aucun retour',
              style: context.typography.h3.copyWith(color: c.fg2),
            ),
            SizedBox(height: context.spacing.space1),
            Text(
              'Les retours apparaîtront ici.',
              textAlign: TextAlign.center,
              style: context.typography.bodyMd.copyWith(color: c.fg3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoMatchState extends StatelessWidget {
  const _NoMatchState({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: c.fg3),
            SizedBox(height: context.spacing.space3),
            Text(
              'Aucun résultat',
              style: context.typography.h4.copyWith(color: c.fg1),
            ),
            SizedBox(height: context.spacing.space2),
            _ScaleTap(
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 6),
                child: Text(
                  'Effacer les filtres',
                  style: context.typography.button.copyWith(color: c.fg1),
                ),
              ),
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
              'Impossible de charger les commandes',
              textAlign: TextAlign.center,
              style: context.typography.h4.copyWith(color: c.fg1),
            ),
            SizedBox(height: context.spacing.space4),
            _PrimaryCta(label: 'Réessayer', onTap: onRetry),
          ],
        ),
      ),
    );
  }
}

class _OrderListSkeleton extends StatelessWidget {
  const _OrderListSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.spacing.screenEdge,
        context.spacing.space3,
        context.spacing.screenEdge,
        96,
      ),
      children: [
        Container(
          decoration: BoxDecoration(
            color: c.surface1,
            border: Border.all(color: c.border1),
            borderRadius: BorderRadius.circular(context.radius.radiusCard),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < 5; i++) ...[
                const _SkeletonRow(),
                if (i < 4)
                  Container(
                    height: 1,
                    color: c.border1,
                    margin: EdgeInsets.only(left: context.spacing.space4 * 2),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget bar({required double width, required double height}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(4),
        ),
      ).animate(onPlay: (ctrl) => ctrl.repeat()).shimmer(
            duration: const Duration(milliseconds: 1500),
            color: c.surface3,
          );
    }

    return Padding(
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
          ).animate(onPlay: (ctrl) => ctrl.repeat()).shimmer(
                duration: const Duration(milliseconds: 1500),
                color: c.surface3,
              ),
          SizedBox(width: context.spacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(width: 140, height: 14),
                SizedBox(height: context.spacing.space1),
                bar(width: 200, height: 12),
                SizedBox(height: context.spacing.space2),
                bar(width: 64, height: 16),
              ],
            ),
          ),
          SizedBox(width: context.spacing.space2),
          bar(width: 56, height: 14),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// FAB — bottom-right floating (§3.9)
// ════════════════════════════════════════════════════════════
class _OrdersFab extends StatelessWidget {
  const _OrdersFab();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ScaleTap(
      pressedScale: 0.96,
      onTap: () => context.push('/orders/add'),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: c.fg1,
          shape: BoxShape.circle,
          boxShadow: context.shadows.shadowFab,
        ),
        alignment: Alignment.center,
        child: Icon(Icons.add_rounded, color: c.surface0, size: 26),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Inline v1.1-compliant primary button (used in Empty / Error states)
// NOTE: not using DidoButton.primary — that widget still backgrounds
// with appBrand (teal), violating v1.1 §3.1. DidoButton needs its own
// refactor prompt; for now we inline a token-driven primary.
// ════════════════════════════════════════════════════════════
class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: c.fg1,
          borderRadius: BorderRadius.circular(context.radius.radiusInput),
        ),
        child: Text(
          label,
          style: context.typography.button.copyWith(color: c.surface0),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Filter bottom sheet (§3.12) — date range + secondary status
// ════════════════════════════════════════════════════════════
class _OrderFilterSheet extends StatefulWidget {
  const _OrderFilterSheet({
    required this.initialDate,
    required this.initialStatus,
    required this.onApply,
  });

  final String initialDate;
  final String? initialStatus;
  final void Function(String date, String? status) onApply;

  @override
  State<_OrderFilterSheet> createState() => _OrderFilterSheetState();
}

class _OrderFilterSheetState extends State<_OrderFilterSheet> {
  late String _date = widget.initialDate;
  late String? _status = widget.initialStatus;

  static const _dateOptions = <(String, String)>[
    ('all', 'Toute la période'),
    ('today', "Aujourd'hui"),
    ('3days', '3 derniers jours'),
    ('week', 'Cette semaine'),
    ('month', 'Ce mois-ci'),
  ];

  static const _statusOptions = <(String?, String)>[
    (null, 'Toutes'),
    ('PENDING', 'En attente'),
    ('CONFIRMED', 'Confirmée'),
    ('SHIPPED', 'Expédiée'),
    ('DELIVERED', 'Livrée'),
    ('CANCELLED', 'Annulée'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.radius.radiusSheet),
          topRight: Radius.circular(context.radius.radiusSheet),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.spacing.space4,
            context.spacing.space2,
            context.spacing.space4,
            context.spacing.space6,
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
                    color: c.border2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: context.spacing.space4),
              Text('Filtrer',
                  style: context.typography.h3.copyWith(color: c.fg1)),
              SizedBox(height: context.spacing.space4),
              Text('PÉRIODE',
                  style: context.typography.label.copyWith(color: c.fg3)),
              SizedBox(height: context.spacing.space2),
              for (final (k, label) in _dateOptions)
                _RadioTile(
                  label: label,
                  selected: _date == k,
                  onTap: () => setState(() => _date = k),
                ),
              SizedBox(height: context.spacing.space4),
              Text('STATUT',
                  style: context.typography.label.copyWith(color: c.fg3)),
              SizedBox(height: context.spacing.space2),
              for (final (k, label) in _statusOptions)
                _RadioTile(
                  label: label,
                  selected: _status == k,
                  onTap: () => setState(() => _status = k),
                ),
              SizedBox(height: context.spacing.space6),
              _PrimaryCta(
                label: 'Appliquer',
                onTap: () {
                  widget.onApply(_date, _status);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioTile extends StatelessWidget {
  const _RadioTile({
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? c.fg1 : c.border2,
                  width: selected ? 6 : 1.5,
                ),
              ),
            ),
            SizedBox(width: context.spacing.space3),
            Text(
              label,
              style: context.typography.body.copyWith(
                color: selected ? c.fg1 : c.fg2,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// F13 — Multi-select action bar (bottom bar while in mode)
// ════════════════════════════════════════════════════════════
class _MultiSelectActionBar extends StatelessWidget {
  const _MultiSelectActionBar({
    required this.count,
    required this.onCancel,
    required this.onActions,
  });
  final int count;
  final VoidCallback onCancel;
  final VoidCallback onActions;

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
          context.spacing.space3,
        ),
        decoration: BoxDecoration(
          color: c.surface0,
          border: Border(top: BorderSide(color: c.border1)),
        ),
        child: Row(
          children: [
            TextButton(
              onPressed: onCancel,
              child: Text(
                'Annuler',
                style: context.typography.button.copyWith(color: c.fg2),
              ),
            ),
            const Spacer(),
            Text(
              count > 1
                  ? '$count sélectionnées'
                  : '$count sélectionnée',
              style: context.typography.bodyMd.copyWith(color: c.fg1),
            ),
            SizedBox(width: context.spacing.space3),
            ElevatedButton.icon(
              onPressed: count == 0 ? null : onActions,
              style: ElevatedButton.styleFrom(
                backgroundColor: c.fg1,
                foregroundColor: c.surface0,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                disabledBackgroundColor: c.surface2,
                disabledForegroundColor: c.fg3,
              ),
              icon: const Icon(Icons.more_horiz, size: 16),
              label: Text(
                'Actions',
                style:
                    context.typography.button.copyWith(color: c.surface0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// F12 — Order list flag row
// ════════════════════════════════════════════════════════════
class _FlagRow extends StatelessWidget {
  const _FlagRow({required this.order});
  final OrderLean order;

  @override
  Widget build(BuildContext context) {
    final visible = order.visibleFlags;
    final overflow = order.overflowCount;
    return SizedBox(
      height: 22,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            OrderFlagPill(flag: visible[i]),
          ],
          if (overflow > 0) ...[
            const SizedBox(width: 6),
            OrderFlagPill.overflow(count: overflow),
          ],
        ],
      ),
    );
  }
}
