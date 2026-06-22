import 'package:flutter/material.dart';
import 'package:veloce/models.dart';
import '../AppTheme.dart';
import 'BookingDetails.dart';

class VehicleDetailScreen extends StatelessWidget {
  final Vehicle car;
  // True when this screen was opened from a cached (offline) vehicle list.
  // Booking requires a live availability check against Firestore, so the
  // Book button is disabled in this case even if car.isAvailable is true
  // in the stale cached data.
  final bool isOffline;

  const VehicleDetailScreen({
    super.key,
    required this.car,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    // Can only actually be booked if the cached availability flag says yes
    // AND we have a live connection to verify it.
    final bool canBook = car.isAvailable && !isOffline;

    return Scaffold(
      backgroundColor: VeloceTheme.bgDeep,
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Image.network(
                  car.imageUrl,
                  height: 350,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 350,
                    width: double.infinity,
                    color: VeloceTheme.bgElevated,
                    child: const Icon(Icons.directions_car, size: 80, color: VeloceTheme.textMuted),
                  ),
                ),
                // Availability badge
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: car.isAvailable
                          ? VeloceTheme.successGreen.withOpacity(0.2)
                          : VeloceTheme.accentRed.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: car.isAvailable ? VeloceTheme.successGreen : VeloceTheme.accentRed),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: car.isAvailable ? VeloceTheme.successGreen : VeloceTheme.accentRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          car.isAvailable ? 'Available Now' : 'Currently Unavailable',
                          style: TextStyle(
                            color: car.isAvailable ? VeloceTheme.successGreen : VeloceTheme.accentRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(car.category.toUpperCase(), style: const TextStyle(color: VeloceTheme.accentBlueBright, fontWeight: FontWeight.bold)),
                  Text(car.name, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('${car.perDayCharges.toInt()} PKR/Day', style: const TextStyle(color: Colors.white, fontSize: 24)),
                  const SizedBox(height: 20),

                  // ─── Quick specs ─────────────────────────────────────────────
                  Row(
                    children: [
                      _SpecChip(icon: Icons.bolt, label: '${car.horsepower.toInt()} HP'),
                      const SizedBox(width: 10),
                      _SpecChip(icon: Icons.timer_outlined, label: '0-60 in ${car.zeroToSixty}s'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text("Description", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    car.description.isNotEmpty ? car.description : 'Experience elite performance with this vehicle.',
                    style: const TextStyle(color: VeloceTheme.textMuted, height: 1.6),
                  ),

                  if (car.features.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text("Features", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: car.features.map((f) => _FeatureChip(label: f)).toList(),
                    ),
                  ],

                  const SizedBox(height: 30),

                  // ─── Offline notice ──────────────────────────────────────────
                  // Shown above the button whenever this vehicle is being
                  // viewed from cached/offline data, regardless of its
                  // cached availability flag.
                  if (isOffline) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: VeloceTheme.accentGold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: VeloceTheme.accentGold.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.cloud_off_rounded, color: VeloceTheme.accentGold, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You\'re offline. Connect to the internet to book this vehicle.',
                              style: TextStyle(color: VeloceTheme.accentGold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ─── Book button — disabled when unavailable OR offline ─────
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canBook ? VeloceTheme.accentBlue : VeloceTheme.bgElevated,
                        disabledBackgroundColor: VeloceTheme.bgElevated,
                      ),
                      onPressed: canBook
                          ? () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BookingDetailsPage(vehicle: car)),
                      )
                          : null,
                      child: Text(
                        isOffline
                            ? "Offline — Can't Book"
                            : (car.isAvailable ? "Book Now" : "Currently Unavailable"),
                        style: TextStyle(color: canBook ? Colors.white : VeloceTheme.textMuted),
                      ),
                    ),
                  ),

                  if (!isOffline && !car.isAvailable) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'This vehicle is currently booked by another user. Check back later or browse other vehicles.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: VeloceTheme.textMuted, fontSize: 12, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SpecChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: VeloceTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: VeloceTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: VeloceTheme.accentGold, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: VeloceTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  const _FeatureChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: VeloceTheme.accentBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VeloceTheme.accentBlue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: VeloceTheme.accentBlueBright, size: 13),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: VeloceTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}