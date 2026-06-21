import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import '../AppTheme.dart';
import '../models.dart';
import '../commonWidgets.dart';
import 'VehicleDetails.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  // ─── Firestore stream — listens to the 'vehicles' collection in real time ──
  // The admin panel writes documents here; this screen auto-updates on changes.
  final Stream<QuerySnapshot> _vehicleStream = FirebaseFirestore.instance
      .collection('vehicles')
      .orderBy('brand')
      .snapshots();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Vehicle> _applySearch(List<Vehicle> all) {
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((v) =>
    v.name.toLowerCase().contains(q) ||
        v.brand.toLowerCase().contains(q) ||
        v.category.toLowerCase().contains(q),
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VeloceTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: VeloceTheme.bgDeep,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Our Fleet',
              style: TextStyle(
                color: VeloceTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'High-Performance Collection',
              style: TextStyle(color: VeloceTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ─── Search Bar ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: VeloceTheme.textPrimary),
              onChanged: (val) => setState(() => _query = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search brand, model, category...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: VeloceTheme.textMuted,
                  size: 20,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: VeloceTheme.textMuted,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                )
                    : null,
              ),
            ),
          ),

          // ─── Vehicle Grid (Firestore stream) ───────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _vehicleStream,
              builder: (context, snapshot) {
                // Loading state — shimmer skeleton
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _ShimmerGrid();
                }

                // Error state
                if (snapshot.hasError) {
                  return _ErrorView(message: snapshot.error.toString());
                }

                // Map Firestore docs → Vehicle objects
                final docs = snapshot.data?.docs ?? [];
                final allVehicles = docs.map((doc) {
                  return Vehicle.fromFirestore(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  );
                }).toList();

                // Apply search filter
                final vehicles = _applySearch(allVehicles);

                // Empty fleet
                if (allVehicles.isEmpty) {
                  return const _EmptyFleet();
                }

                // No search results
                if (vehicles.isEmpty) {
                  return _NoResults(query: _query);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Result count
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '${vehicles.length} vehicle${vehicles.length == 1 ? '' : 's'}'
                            '${_query.isNotEmpty ? ' for "$_query"' : ''}',
                        style: const TextStyle(
                          color: VeloceTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Grid
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: vehicles.length,
                        itemBuilder: (ctx, i) => _VehicleGridCard(
                          vehicle: vehicles[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  VehicleDetailScreen(car: vehicles[i]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Vehicle Grid Card ────────────────────────────────────────────────────────
class _VehicleGridCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;

  const _VehicleGridCard({required this.vehicle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: VeloceTheme.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: VeloceTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Image ───────────────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
                  child: vehicle.imageUrl.isNotEmpty
                      ? Image.network(
                    vehicle.imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) =>
                    progress == null
                        ? child
                        : _ImagePlaceholder(),
                    errorBuilder: (_, __, ___) => _ImagePlaceholder(),
                  )
                      : _ImagePlaceholder(),
                ),
                // Category badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: VeloceTheme.bgDeep.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      vehicle.category,
                      style: const TextStyle(
                        color: VeloceTheme.accentBlueBright,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                // Availability dot
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: VeloceTheme.bgDeep.withOpacity(0.85),
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: vehicle.isAvailable
                            ? VeloceTheme.successGreen
                            : VeloceTheme.accentRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ─── Info ─────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.brand,
                    style: const TextStyle(
                        color: VeloceTheme.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vehicle.name,
                    style: const TextStyle(
                      color: VeloceTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.bolt,
                          color: VeloceTheme.accentGold, size: 13),
                      Text(
                        ' ${vehicle.horsepower.toInt()} HP',
                        style: const TextStyle(
                            color: VeloceTheme.textSecondary, fontSize: 11),
                      ),
                      const Spacer(),
                      const Icon(Icons.timer_outlined,
                          color: VeloceTheme.textMuted, size: 12),
                      Text(
                        ' ${vehicle.zeroToSixty}s',
                        style: const TextStyle(
                            color: VeloceTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('from',
                              style: TextStyle(
                                  color: VeloceTheme.textMuted, fontSize: 10)),
                          Text(
                            '${vehicle.perDayCharges.toInt()} PKR/day',
                            style: const TextStyle(
                              color: VeloceTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: VeloceTheme.accentBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Book',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
}

// ─── Image Placeholder ────────────────────────────────────────────────────────
class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      color: VeloceTheme.bgElevated,
      child: const Icon(
        Icons.directions_car_outlined,
        size: 38,
        color: VeloceTheme.textMuted,
      ),
    );
  }
}

// ─── Shimmer Loading Grid ─────────────────────────────────────────────────────
class _ShimmerGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: VeloceTheme.bgCard,
      highlightColor: VeloceTheme.bgElevated,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: VeloceTheme.bgCard,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

// ─── Empty Fleet ──────────────────────────────────────────────────────────────
class _EmptyFleet extends StatelessWidget {
  const _EmptyFleet();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.garage_outlined,
            size: 72,
            color: VeloceTheme.textMuted.withOpacity(0.35),
          ),
          const SizedBox(height: 16),
          const Text(
            'Fleet coming soon',
            style: TextStyle(
              color: VeloceTheme.textSecondary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Vehicles added by the admin will\nappear here automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(color: VeloceTheme.textMuted, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─── No Search Results ────────────────────────────────────────────────────────
class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: VeloceTheme.textMuted.withOpacity(0.35),
          ),
          const SizedBox(height: 16),
          Text(
            'No results for "$query"',
            style: const TextStyle(
              color: VeloceTheme.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try a different brand or model name.',
            style: TextStyle(color: VeloceTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 56, color: VeloceTheme.accentRed),
            const SizedBox(height: 16),
            const Text(
              'Failed to load fleet',
              style: TextStyle(
                color: VeloceTheme.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: VeloceTheme.textMuted, fontSize: 12, height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}



















