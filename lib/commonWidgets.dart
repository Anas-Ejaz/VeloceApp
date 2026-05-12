import 'package:flutter/material.dart';
import '../AppTheme.dart';
import '../models.dart';

// ─── Glassmorphic Container ───────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final double? height;
  final double? width;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.borderColor,
    this.height,
    this.width,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VeloceTheme.bgCard,
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          border: Border.all(
            color: borderColor ?? VeloceTheme.borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ─── Stat Chip ────────────────────────────────────────────────────────────────
class StatChip extends StatelessWidget {
  final String value;
  final String label;

  const StatChip({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: VeloceTheme.accentBlueBright,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: VeloceTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Vehicle Card (Fleet) ─────────────────────────────────────────────────────
class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback? onTap;

  const VehicleCard({super.key, required this.vehicle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: VeloceTheme.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: VeloceTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Image.network(
                    vehicle.imageUrl,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 130,
                      color: VeloceTheme.bgElevated,
                      child: const Icon(Icons.directions_car, size: 48, color: VeloceTheme.textMuted),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: vehicle.isAvailable
                          ? VeloceTheme.successGreen.withOpacity(0.2)
                          : VeloceTheme.accentRed.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: vehicle.isAvailable ? VeloceTheme.successGreen : VeloceTheme.accentRed,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      vehicle.isAvailable ? 'Available' : 'In Use',
                      style: TextStyle(
                        color: vehicle.isAvailable ? VeloceTheme.successGreen : VeloceTheme.accentRed,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.category,
                    style: const TextStyle(
                      color: VeloceTheme.accentBlueBright,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vehicle.name,
                    style: const TextStyle(
                      color: VeloceTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    vehicle.brand,
                    style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _specBadge('${vehicle.horsepower.toInt()} HP'),
                      const SizedBox(width: 6),
                      _specBadge('0-60 in ${vehicle.zeroToSixty}s'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '\$${vehicle.monthlyPrice.toInt()}',
                              style: const TextStyle(
                                color: VeloceTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const TextSpan(
                              text: '/mo',
                              style: TextStyle(color: VeloceTheme.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: VeloceTheme.accentBlue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.arrow_forward, size: 14, color: VeloceTheme.accentBlueBright),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _specBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: VeloceTheme.bgElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: VeloceTheme.borderColor),
      ),
      child: Text(text, style: const TextStyle(color: VeloceTheme.textSecondary, fontSize: 10)),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: VeloceTheme.accentBlueBright,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Subscription Badge ───────────────────────────────────────────────────────
class TierBadge extends StatelessWidget {
  final SubscriptionTier tier;

  const TierBadge({super.key, required this.tier});

  Color get _color {
    switch (tier) {
      case SubscriptionTier.basic:
        return const Color(0xFF64748B);
      case SubscriptionTier.premium:
        return VeloceTheme.accentBlueBright;
      case SubscriptionTier.elite:
        return VeloceTheme.accentGold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tier == SubscriptionTier.elite
                ? Icons.workspace_premium
                : tier == SubscriptionTier.premium
                ? Icons.star
                : Icons.verified,
            size: 12,
            color: _color,
          ),
          const SizedBox(width: 4),
          Text(
            tier.name.toUpperCase(),
            style: TextStyle(
              color: _color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Custom Blue Button ───────────────────────────────────────────────────────
class VeloceButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isOutlined;
  final bool isLoading;
  final Color? color;

  const VeloceButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isOutlined = false,
    this.isLoading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? VeloceTheme.accentBlue;
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : bg,
          borderRadius: BorderRadius.circular(12),
          border: isOutlined ? Border.all(color: bg, width: 1.5) : null,
          gradient: isOutlined
              ? null
              : LinearGradient(
            colors: [bg, bg.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: isOutlined
              ? null
              : [
            BoxShadow(
              color: bg.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            else ...[
              if (icon != null) ...[
                Icon(icon, size: 18, color: isOutlined ? bg : Colors.white),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isOutlined ? bg : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Booking Tile ─────────────────────────────────────────────────────────────
class BookingTile extends StatelessWidget {
  final Booking booking;

  const BookingTile({super.key, required this.booking});

  Color _statusColor(BookingStatus s) {
    switch (s) {
      case BookingStatus.active:
        return VeloceTheme.successGreen;
      case BookingStatus.completed:
        return VeloceTheme.textMuted;
      case BookingStatus.upcoming:
        return VeloceTheme.accentBlueBright;
      case BookingStatus.cancelled:
        return VeloceTheme.accentRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              booking.vehicle.imageUrl,
              width: 70,
              height: 54,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 70,
                height: 54,
                color: VeloceTheme.bgElevated,
                child: const Icon(Icons.directions_car, color: VeloceTheme.textMuted, size: 28),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.vehicle.brand,
                  style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 11),
                ),
                Text(
                  booking.vehicle.name,
                  style: const TextStyle(
                    color: VeloceTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${booking.vehicle.horsepower.toInt()} HP · 0-60 in ${booking.vehicle.zeroToSixty}s',
                  style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(booking.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  booking.status.label,
                  style: TextStyle(
                    color: _statusColor(booking.status),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Icon(Icons.chevron_right, color: VeloceTheme.textMuted, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}