import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/order_model.dart';
import '../../shared/widgets/app_network_image.dart';
import 'providers/order_provider.dart';

// ── Color tokens ──────────────────────────────────────────────────────────────
const _bg = Color(0xFFF8FAFC);
const _card = Colors.white;
const _primary = Color(0xFF0EA5E9);
const _orange = Color(0xFFF97316);
const _textPrimary = Color(0xFF0F172A);
const _textSecondary = Color(0xFF64748B);
const _green = Color(0xFF22C55E);
const _red = Color(0xFFEF4444);

// ── Screen ────────────────────────────────────────────────────────────────────

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(orderFilterProvider);
    final ordersAsync = ref.watch(filteredOrdersProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'My Orders',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: _textPrimary,
          ),
        ),

      ),

      // ── Filter tabs ───────────────────────────────────────────────────────
      body: Column(
        children: [
          _FilterRow(current: filter),
          Expanded(
            child: ordersAsync.when(
              loading: () => _Shimmer(),
              error: (e, _) => _ErrorView(error: e.toString()),
              data: (orders) {
                if (orders.isEmpty) return _EmptyState(filter: filter);
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  itemCount: orders.length,
                  separatorBuilder: (_, _i) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _OrderCard(order: orders[i])
                      .animate(delay: Duration(milliseconds: 50 * i))
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.06),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter row ────────────────────────────────────────────────────────────────

class _FilterRow extends ConsumerWidget {
  final OrderFilter current;
  const _FilterRow({required this.current});

  static const _tabs = [
    (OrderFilter.all, 'All'),
    (OrderFilter.active, 'Active'),
    (OrderFilter.delivered, 'Delivered'),
    (OrderFilter.cancelled, 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: _tabs.map((tab) {
          final isSelected = current == tab.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () =>
                  ref.read(orderFilterProvider.notifier).state = tab.$1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _primary : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected ? _primary : Colors.grey.shade300,
                    width: 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _primary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  tab.$2,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isSelected ? Colors.white : _textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Order card ────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: Order ID + Date + Status badge ───────────────
            Row(
              children: [
                Text(
                  '#${order.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                if (order.createdAt != null)
                  Text(
                    DateFormat('d MMM, hh:mm a').format(order.createdAt!),
                    style: const TextStyle(
                        fontSize: 11, color: _textSecondary),
                  ),
                const SizedBox(width: 8),
                _StatusBadge(status: order.status),
              ],
            ),

            const SizedBox(height: 12),

            // ── Product image row ─────────────────────────────────────
            if (order.items.isNotEmpty) ...[
              _ImageRow(items: order.items),
              const SizedBox(height: 10),
            ],

            // ── Product summary ───────────────────────────────────────
            Text(
              order.productSummary,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),

            // ── Item count + total ────────────────────────────────────
            Row(
              children: [
                Text(
                  '${order.items.length} item${order.items.length == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 12, color: _textSecondary),
                ),
                const SizedBox(width: 8),
                Container(
                    width: 4, height: 4,
                    decoration: const BoxDecoration(
                        color: _textSecondary, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(
                  '₹${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),

            // ── Delivery address ──────────────────────────────────────
            if (order.deliveryAddressLine.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(LucideIcons.mapPin,
                      size: 12, color: _textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.deliveryAddressLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: _textSecondary),
                    ),
                  ),
                ],
              ),
            ],

            // ── Progress bar (active orders only) ───────────────────
            if (order.isActive) ...[
              const SizedBox(height: 12),
              _ProgressBar(stepIndex: order.stepIndex),
            ],

            const SizedBox(height: 14),

            // ── Action buttons ────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        context.push('/order-detail/${order.id}'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _primary),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => context.push('/home'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Reorder',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case 'DELIVERED':
        return _green;
      case 'OUT_FOR_DELIVERY':
        return _primary;
      case 'CONFIRMED':
      case 'PREPARING':
        return _orange;
      case 'CANCELLED':
        return _red;
      default:
        return _textSecondary;
    }
  }

  String get _label {
    switch (status) {
      case 'DELIVERED':
        return 'Delivered';
      case 'OUT_FOR_DELIVERY':
        return 'Out for Delivery';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'PREPARING':
        return 'Preparing';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: _color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ── Product image row ─────────────────────────────────────────────────────────

class _ImageRow extends StatelessWidget {
  final List<OrderItem> items;
  const _ImageRow({required this.items});

  @override
  Widget build(BuildContext context) {
    const maxShow = 4;
    final shown = items.take(maxShow).toList();
    final extra = items.length - maxShow;

    return Row(
      children: [
        ...shown.map((item) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: item.imageUrl?.isNotEmpty == true
                    ? AppNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(
                            LucideIcons.shoppingBag,
                            size: 18,
                            color: _textSecondary),
                      )
                    : const Icon(LucideIcons.shoppingBag,
                        size: 18, color: _textSecondary),
              ),
            )),
        if (extra > 0)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '+$extra',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Progress bar ──────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int stepIndex;
  const _ProgressBar({required this.stepIndex});

  static const _steps = ['Confirmed', 'Preparing', 'Out for Delivery', 'Delivered'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(_steps.length * 2 - 1, (i) {
            if (i.isOdd) {
              // Line
              final lineStep = i ~/ 2;
              final done = lineStep < stepIndex;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 3,
                  decoration: BoxDecoration(
                    color: done ? _primary : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            } else {
              // Dot
              final dotStep = i ~/ 2;
              final done = dotStep <= stepIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: done ? _primary : Colors.grey.shade300,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: done ? _primary : Colors.grey.shade300,
                    width: done ? 0 : 1,
                  ),
                ),
              );
            }
          }),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _steps.asMap().entries.map((e) {
            final active = e.key <= stepIndex;
            return Flexible(
              child: Text(
                e.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  color: active ? _primary : _textSecondary,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final OrderFilter filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.shoppingBag,
                  size: 44, color: _primary),
            ),
            const SizedBox(height: 20),
            Text(
              filter == OrderFilter.all
                  ? 'No orders yet!'
                  : 'No ${filter.name} orders',
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your order history will\nappear here',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textSecondary, height: 1.5),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(LucideIcons.shoppingCart, size: 18),
              label: const Text('Start Shopping',
                  style: TextStyle(
                      fontFamily: 'Manrope', fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
      ),
    );
  }
}

// ── Shimmer skeleton ──────────────────────────────────────────────────────────

class _Shimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: 4,
      separatorBuilder: (_, _i) => const SizedBox(height: 12),
      itemBuilder: (_, _i) => _ShimmerCard(),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.04, end: 0.12).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends ConsumerWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.xCircle, size: 48, color: _red),
            const SizedBox(height: 12),
            Text(
              'Failed to load orders:\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _red, fontSize: 13),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref.invalidate(ordersStreamProvider),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(backgroundColor: _primary),
            ),
          ],
        ),
      ),
    );
  }
}
