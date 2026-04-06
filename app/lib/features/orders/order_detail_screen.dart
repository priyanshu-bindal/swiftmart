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

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderByIdProvider(orderId));

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
          'Order Details',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: _textPrimary,
          ),
        ),
      ),
      body: orderAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: _primary)),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: _red)),
        ),
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }
          return _OrderDetailBody(order: order);
        },
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _OrderDetailBody extends StatelessWidget {
  final OrderModel order;
  const _OrderDetailBody({required this.order});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Order ID + date + status ────────────────────────────────
          _SectionCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Order ID',
                              style: TextStyle(
                                  fontSize: 11, color: _textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            '#${order.id.substring(0, 12).toUpperCase()}',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: _textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: order.status),
                  ],
                ),
                if (order.createdAt != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(LucideIcons.calendar,
                          size: 13, color: _textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('EEEE, d MMMM yyyy • hh:mm a')
                            .format(order.createdAt!),
                        style: const TextStyle(
                            fontSize: 12, color: _textSecondary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: 12),

          // ── Status timeline ─────────────────────────────────────────
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Status Timeline'),
                const SizedBox(height: 16),
                _Timeline(order: order),
              ],
            ),
          ).animate(delay: 60.ms).fadeIn(duration: 300.ms),

          const SizedBox(height: 12),

          // ── Products ────────────────────────────────────────────────
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle('Items (${order.items.length})'),
                const SizedBox(height: 12),
                ...order.items.asMap().entries.map((e) {
                  return _ProductRow(item: e.value)
                      .animate(delay: Duration(milliseconds: 80 * e.key))
                      .fadeIn(duration: 250.ms)
                      .slideX(begin: 0.04);
                }),
              ],
            ),
          ).animate(delay: 120.ms).fadeIn(duration: 300.ms),

          const SizedBox(height: 12),

          // ── Price breakdown ─────────────────────────────────────────
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Price Breakdown'),
                const SizedBox(height: 14),
                _PriceRow('Subtotal',
                    '₹${order.subtotal.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                _PriceRow('Delivery Fee',
                    '₹${order.deliveryFee.toStringAsFixed(2)}'),
                if (order.discount > 0) ...[
                  const SizedBox(height: 8),
                  _PriceRow(
                    'Discount${order.couponCode != null ? ' (${order.couponCode})' : ''}',
                    '-₹${order.discount.toStringAsFixed(2)}',
                    valueColor: _orange,
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: _textPrimary,
                        )),
                    Text(
                      '₹${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: _primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate(delay: 180.ms).fadeIn(duration: 300.ms),

          const SizedBox(height: 12),

          // ── Delivery address ────────────────────────────────────────
          if (order.deliveryAddressLine.isNotEmpty)
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Delivery Address'),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.mapPin,
                            size: 16, color: _primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          order.deliveryAddressLine,
                          style: const TextStyle(
                            fontSize: 14,
                            color: _textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate(delay: 240.ms).fadeIn(duration: 300.ms),

          if (order.deliveryAddressLine.isNotEmpty)
            const SizedBox(height: 12),

          // ── Payment method ──────────────────────────────────────────
          if (order.paymentMethod != null)
            _SectionCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.creditCard,
                        size: 16, color: _green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payment Method',
                            style: TextStyle(
                                fontSize: 11, color: _textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          _paymentLabel(order.paymentMethod!),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Paid',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _green)),
                  ),
                ],
              ),
            ).animate(delay: 300.ms).fadeIn(duration: 300.ms),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _paymentLabel(String method) {
    switch (method.toLowerCase()) {
      case 'cod':
        return 'Cash on Delivery';
      case 'upi':
        return 'UPI Payment';
      case 'card':
        return 'Credit / Debit Card';
      case 'wallet':
        return 'Wallet';
      default:
        return method;
    }
  }
}

// ── Timeline ──────────────────────────────────────────────────────────────────

class _Timeline extends StatelessWidget {
  final OrderModel order;
  const _Timeline({required this.order});

  static const _steps = [
    (icon: LucideIcons.checkCircle, label: 'Order Confirmed'),
    (icon: LucideIcons.package,     label: 'Preparing'),
    (icon: LucideIcons.bike,        label: 'Out for Delivery'),
    (icon: LucideIcons.home,        label: 'Delivered'),
  ];

  @override
  Widget build(BuildContext context) {
    final current = order.isCancelled ? -1 : order.stepIndex;

    return Column(
      children: List.generate(_steps.length, (i) {
        final done = i <= current;
        final isLast = i == _steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dot + vertical line
            Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: done
                        ? _primary
                        : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _steps[i].icon,
                    color: done ? Colors.white : Colors.grey.shade400,
                    size: 18,
                  ),
                ),
                if (!isLast)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 2,
                    height: 40,
                    color: done && i < current
                        ? _primary
                        : Colors.grey.shade200,
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _steps[i].label,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: done ? _textPrimary : _textSecondary,
                      ),
                    ),
                    if (done && order.createdAt != null && i == 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('d MMM, hh:mm a').format(order.createdAt!),
                        style: const TextStyle(
                            fontSize: 11, color: _textSecondary),
                      ),
                    ],
                    SizedBox(height: isLast ? 0 : 24),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ── Product row ───────────────────────────────────────────────────────────────

class _ProductRow extends StatelessWidget {
  final OrderItem item;
  const _ProductRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: item.imageUrl?.isNotEmpty == true
                ? AppNetworkImage(
                    imageUrl: item.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(
                        LucideIcons.shoppingBag,
                        color: _textSecondary),
                  )
                : const Icon(LucideIcons.shoppingBag,
                    color: _textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _textPrimary)),
                const SizedBox(height: 2),
                Text(
                  '${item.unit ?? ''} × ${item.quantity}',
                  style: const TextStyle(
                      fontSize: 12, color: _textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${item.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: _textPrimary,
                ),
              ),
              Text(
                '₹${item.unitPrice.toStringAsFixed(2)} each',
                style: const TextStyle(
                    fontSize: 11, color: _textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w800,
        fontSize: 15,
        color: _textPrimary,
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _PriceRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: _textSecondary)),
        Text(value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? _textPrimary,
            )),
      ],
    );
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: _color,
        ),
      ),
    );
  }
}
