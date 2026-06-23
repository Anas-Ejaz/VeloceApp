import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import '../AppTheme.dart';
import '../models.dart';
import '../commonWidgets.dart';
import '../database_helper.dart';
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

  // ─── Local SQLite cache state ────────────────────────────────────────────
  // Loaded once on init so the grid has something to show immediately, even
  // before the first Firestore snapshot arrives (or with no internet at
  // all). Every time a fresh Firestore snapshot comes in, this is updated
  // and the cache is overwritten so it stays in sync.
  List<Vehicle> _cachedVehicles = [];
  bool _cacheLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCache();
  }

  Future<void> _loadCache() async {
    try {
      final cached = await DatabaseHelper.instance.getCachedVehicles();
      if (mounted) {
        setState(() {
          _cachedVehicles = cached;
          _cacheLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cacheLoaded = true);
    }
  }

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

          // ─── Vehicle Grid (cache-first, then live Firestore) ────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _vehicleStream,
              builder: (context, snapshot) {
                // ─── Still waiting on the FIRST Firestore snapshot ───────────
                // If we already have a local cache, show it instead of a
                // shimmer skeleton — this is the "instant load" behavior.
                if (snapshot.connectionState == ConnectionState.waiting) {
                  if (!_cacheLoaded) {
                    return _ShimmerGrid();
                  }
                  if (_cachedVehicles.isNotEmpty) {
                    return _buildVehicleList(_cachedVehicles, isOffline: true);
                  }
                  return _ShimmerGrid();
                }

                // ─── Firestore error (e.g. no internet) ───────────────────────
                // Fall back to whatever is cached rather than showing a hard
                // error, since the point of the cache is to keep the app
                // usable offline.
                if (snapshot.hasError) {
                  if (_cachedVehicles.isNotEmpty) {
                    return _buildVehicleList(_cachedVehicles, isOffline: true);
                  }
                  return _ErrorView(message: snapshot.error.toString());
                }

                // ─── Fresh data from Firestore ────────────────────────────────
                final docs = snapshot.data?.docs ?? [];
                final freshVehicles = docs.map((doc) {
                  return Vehicle.fromFirestore(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  );
                }).toList();

                // Sync the cache in the background — doesn't block the UI.
                DatabaseHelper.instance.replaceAll(freshVehicles);
                _cachedVehicles = freshVehicles;

                // Empty fleet
                if (freshVehicles.isEmpty) {
                  return const _EmptyFleet();
                }

                return _buildVehicleList(freshVehicles, isOffline: false);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared grid builder used by both the live and cached paths ───────────
  // Layout below is unchanged from the original — same search-count text,
  // same SliverGrid settings, same card. Only addition is the optional
  // offline banner when serving cached data.
  Widget _buildVehicleList(List<Vehicle> source, {required bool isOffline}) {
    final vehicles = _applySearch(source);

    if (vehicles.isEmpty) {
      return _NoResults(query: _query);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Offline banner — only shown when serving the local cache because
        // Firestore hasn't responded yet (no internet / still connecting).
        if (isOffline)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: VeloceTheme.accentGold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: VeloceTheme.accentGold.withOpacity(0.3)),
            ),
            child: Row(
              children: const [
                Icon(Icons.cloud_off_rounded, color: VeloceTheme.accentGold, size: 15),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Showing saved fleet — connect to the internet to book.',
                    style: TextStyle(color: VeloceTheme.accentGold, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),

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
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              // Slightly taller cards than the original (0.72 -> 0.62) so
              // the text block (brand, name, specs, price row) always fits
              // without the RenderFlex overflowing.
              childAspectRatio: 0.62,
            ),
            itemCount: vehicles.length,
            itemBuilder: (ctx, i) => _VehicleGridCard(
              vehicle: vehicles[i],
              isOffline: isOffline,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VehicleDetailScreen(
                    car: vehicles[i],
                    isOffline: isOffline,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Vehicle Grid Card ────────────────────────────────────────────────────────
class _VehicleGridCard extends StatelessWidget {
  final Vehicle vehicle;
  final bool isOffline;
  final VoidCallback onTap;

  const _VehicleGridCard({
    required this.vehicle,
    required this.onTap,
    this.isOffline = false,
  });

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
        // Card itself sizes to whatever the grid gives it — no fixed
        // height here, so the Column below must not exceed that via
        // mainAxisSize.min layout + tight padding/spacing.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Image ───────────────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: vehicle.imageUrl.isNotEmpty
                        ? Image.network(
                      vehicle.imageUrl,
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
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.brand,
                    style: const TextStyle(
                        color: VeloceTheme.textMuted, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    vehicle.name,
                    style: const TextStyle(
                      color: VeloceTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.bolt,
                          color: VeloceTheme.accentGold, size: 12),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          '${vehicle.horsepower.toInt()} HP',
                          style: const TextStyle(
                              color: VeloceTheme.textSecondary, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.timer_outlined,
                          color: VeloceTheme.textMuted, size: 11),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          '${vehicle.zeroToSixty}s',
                          style: const TextStyle(
                              color: VeloceTheme.textSecondary, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('from',
                                style: TextStyle(
                                    color: VeloceTheme.textMuted, fontSize: 9)),
                            Text(
                              '${vehicle.perDayCharges.toInt()} PKR/day',
                              style: const TextStyle(
                                color: VeloceTheme.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          // Greyed out when offline since it can't actually
                          // be booked from a cached snapshot.
                          color: isOffline ? VeloceTheme.bgElevated : VeloceTheme.accentBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isOffline ? 'Offline' : 'Book',
                          style: TextStyle(
                            color: isOffline ? VeloceTheme.textMuted : Colors.white,
                            fontSize: 10,
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
          childAspectRatio: 0.62,
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



<<<<<<< HEAD
=======



//
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:shimmer/shimmer.dart';
// import '../AppTheme.dart';
// import '../models.dart';
// import '../commonWidgets.dart';
// import 'VehicleDetails.dart';
// import '../database_helper.dart'; // 👈 Sqflite helper class ko connect kiya
//
// class VehiclesScreen extends StatefulWidget {
//   const VehiclesScreen({super.key});
//
//   @override
//   State<VehiclesScreen> createState() => _VehiclesScreenState();
// }
//
// class _VehiclesScreenState extends State<VehiclesScreen> {
//   final TextEditingController _searchCtrl = TextEditingController();
//   String _query = '';
//   List<Vehicle> _vehiclesData = [];
//   bool _isLoading = true;
//   String? _errorMessage;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadFleetData(); // Screen open hote hi data fetch karne ka function execute hoga
//   }
//
//   @override
//   void dispose() {
//     _searchCtrl.dispose();
//     super.dispose();
//   }
//
//   // ─── OFFLINE-FIRST SYNCHRONIZATION LOGIC ──────────────────────────────────
//   Future<void> _loadFleetData() async {
//     try {
//       // 1. Tries to fetch latest records from Firestore Cloud Network
//       final snapshot = await FirebaseFirestore.instance
//           .collection('vehicles')
//           .orderBy('brand')
//           .get()
//           .timeout(const Duration(seconds: 4)); // Agar 4 seconds tak response na aaye to network timeout
//
//       final cloudVehicles = snapshot.docs.map((doc) {
//         return Vehicle.fromFirestore(doc.data(), doc.id);
//       }).toList();
//
//       if (cloudVehicles.isNotEmpty) {
//         // 2. Refresh local cache completely so it aligns perfectly with cloud
//         for (var vehicle in cloudVehicles) {
//           await DatabaseHelper.instance.insertOrUpdateLocal(vehicle);
//         }
//
//         if (mounted) {
//           setState(() {
//             _vehiclesData = cloudVehicles;
//             _isLoading = false;
//             _errorMessage = null;
//           });
//         }
//       }
//     } catch (e) {
//       debugPrint("Firebase network fetch dropped or timed out, triggering Sqflite fallback: $e");
//
//       // 3. FALLBACK MECHANISM: Network fails? Fetch silently from local storage!
//       final localVehicles = await DatabaseHelper.instance.getCachedVehicles();
//
//       if (mounted) {
//         setState(() {
//           _vehiclesData = localVehicles;
//           _isLoading = false;
//           // Agar local me bhi kuch nahi mila tabhi user ko message dikhayenge
//           _errorMessage = localVehicles.isEmpty ? "No network connection and local database is empty." : null;
//         });
//       }
//     }
//   }
//
//   List<Vehicle> _applySearch(List<Vehicle> all) {
//     if (_query.isEmpty) return all;
//     final q = _query.toLowerCase();
//     return all.where((v) =>
//     v.name.toLowerCase().contains(q) ||
//         v.brand.toLowerCase().contains(q) ||
//         v.category.toLowerCase().contains(q),
//     ).toList();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // Apply search filter on local variable list state natively
//     final displayedVehicles = _applySearch(_vehiclesData);
//
//     return Scaffold(
//       backgroundColor: VeloceTheme.bgDeep,
//       appBar: AppBar(
//         backgroundColor: VeloceTheme.bgDeep,
//         automaticallyImplyLeading: false,
//         title: const Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Our Fleet',
//               style: TextStyle(
//                 color: VeloceTheme.textPrimary,
//                 fontSize: 22,
//                 fontWeight: FontWeight.w800,
//               ),
//             ),
//             Text(
//               'High-Performance Collection',
//               style: TextStyle(color: VeloceTheme.textMuted, fontSize: 12),
//             ),
//           ],
//         ),
//         actions: [
//           // Refresh trigger button: Enables teacher to manually toggle offline tests seamlessly
//           IconButton(
//             icon: const Icon(Icons.refresh, color: VeloceTheme.textMuted, size: 20),
//             onPressed: () {
//               setState(() => _isLoading = true);
//               _loadFleetData();
//             },
//           )
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: _loadFleetData,
//         color: VeloceTheme.accentBlue,
//         backgroundColor: VeloceTheme.bgCard,
//         child: Column(
//           children: [
//             // ─── Search Bar ────────────────────────────────────────────────────
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
//               child: TextField(
//                 controller: _searchCtrl,
//                 style: const TextStyle(color: VeloceTheme.textPrimary),
//                 onChanged: (val) => setState(() => _query = val.trim()),
//                 decoration: InputDecoration(
//                   hintText: 'Search brand, model, category...',
//                   prefixIcon: const Icon(
//                     Icons.search,
//                     color: VeloceTheme.textMuted,
//                     size: 20,
//                   ),
//                   suffixIcon: _query.isNotEmpty
//                       ? IconButton(
//                     icon: const Icon(
//                       Icons.close,
//                       color: VeloceTheme.textMuted,
//                       size: 18,
//                     ),
//                     onPressed: () {
//                       _searchCtrl.clear();
//                       setState(() => _query = '');
//                     },
//                   )
//                       : null,
//                 ),
//               ),
//             ),
//
//             // ─── Core View Rendering (Evaluates Local & Network states smoothly) ──
//             Expanded(
//               child: Builder(
//                   builder: (context) {
//                     // Shimmer Skeleton State
//                     if (_isLoading) {
//                       return _ShimmerGrid();
//                     }
//
//                     // Actual Exception State
//                     if (_errorMessage != null) {
//                       return _ErrorView(message: _errorMessage!);
//                     }
//
//                     // Completely Empty Database Setup
//                     if (_vehiclesData.isEmpty) {
//                       return const _EmptyFleet();
//                     }
//
//                     // Dynamic Search Mismatch Handling
//                     if (displayedVehicles.isEmpty) {
//                       return _NoResults(query: _query);
//                     }
//
//                     return Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Dynamic Counter Track layout intact
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 16),
//                           child: Text(
//                             '${displayedVehicles.length} vehicle${displayedVehicles.length == 1 ? '' : 's'}'
//                                 '${_query.isNotEmpty ? ' for "$_query"' : ''}',
//                             style: const TextStyle(
//                               color: VeloceTheme.textMuted,
//                               fontSize: 13,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//
//                         // Fully Native Adaptive Vehicle Grid View
//                         Expanded(
//                           child: GridView.builder(
//                             padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
//                             gridDelegate:
//                             const SliverGridDelegateWithFixedCrossAxisCount(
//                               crossAxisCount: 2,
//                               crossAxisSpacing: 12,
//                               mainAxisSpacing: 12,
//                               childAspectRatio: 0.72,
//                             ),
//                             itemCount: displayedVehicles.length,
//                             itemBuilder: (ctx, i) => _VehicleGridCard(
//                               vehicle: displayedVehicles[i],
//                               onTap: () => Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (_) =>
//                                       VehicleDetailScreen(car: displayedVehicles[i]),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     );
//                   }
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // ─── Vehicle Grid Card ────────────────────────────────────────────────────────
// class _VehicleGridCard extends StatelessWidget {
//   final Vehicle vehicle;
//   final VoidCallback onTap;
//
//   const _VehicleGridCard({required this.vehicle, required this.onTap});
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           color: VeloceTheme.bgCard,
//           borderRadius: BorderRadius.circular(18),
//           border: Border.all(color: VeloceTheme.borderColor),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // ─── Image ───────────────────────────────────────────────────────
//             Stack(
//               children: [
//                 ClipRRect(
//                   borderRadius:
//                   const BorderRadius.vertical(top: Radius.circular(18)),
//                   child: vehicle.imageUrl.isNotEmpty
//                       ? Image.network(
//                     vehicle.imageUrl,
//                     height: 120,
//                     width: double.infinity,
//                     fit: BoxFit.cover,
//                     loadingBuilder: (_, child, progress) =>
//                     progress == null
//                         ? child
//                         : _ImagePlaceholder(),
//                     errorBuilder: (_, __, ___) => _ImagePlaceholder(),
//                   )
//                       : _ImagePlaceholder(),
//                 ),
//                 // Category badge
//                 Positioned(
//                   top: 8,
//                   left: 8,
//                   child: Container(
//                     padding:
//                     const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
//                     decoration: BoxDecoration(
//                       color: VeloceTheme.bgDeep.withOpacity(0.85),
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: Text(
//                       vehicle.category,
//                       style: const TextStyle(
//                         color: VeloceTheme.accentBlueBright,
//                         fontSize: 10,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ),
//                 ),
//                 // Availability dot
//                 Positioned(
//                   top: 8,
//                   right: 8,
//                   child: Container(
//                     padding: const EdgeInsets.all(6),
//                     decoration: BoxDecoration(
//                       color: VeloceTheme.bgDeep.withOpacity(0.85),
//                       shape: BoxShape.circle,
//                     ),
//                     child: Container(
//                       width: 7,
//                       height: 7,
//                       decoration: BoxDecoration(
//                         color: vehicle.isAvailable
//                             ? VeloceTheme.successGreen
//                             : VeloceTheme.accentRed,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//
//             // ─── Info ─────────────────────────────────────────────────────────
//             Padding(
//               padding: const EdgeInsets.all(12),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     vehicle.brand,
//                     style: const TextStyle(
//                         color: VeloceTheme.textMuted, fontSize: 11),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     vehicle.name,
//                     style: const TextStyle(
//                       color: VeloceTheme.textPrimary,
//                       fontSize: 14,
//                       fontWeight: FontWeight.w700,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 6),
//                   Row(
//                     children: [
//                       const Icon(Icons.bolt,
//                           color: VeloceTheme.accentGold, size: 13),
//                       Text(
//                         ' ${vehicle.horsepower.toInt()} HP',
//                         style: const TextStyle(
//                             color: VeloceTheme.textSecondary, fontSize: 11),
//                       ),
//                       const Spacer(),
//                       const Icon(Icons.timer_outlined,
//                           color: VeloceTheme.textMuted, size: 12),
//                       Text(
//                         ' ${vehicle.zeroToSixty}s',
//                         style: const TextStyle(
//                             color: VeloceTheme.textSecondary, fontSize: 11),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text('from',
//                               style: TextStyle(
//                                   color: VeloceTheme.textMuted, fontSize: 10)),
//                           Text(
//                             '${vehicle.perDayCharges.toInt()} PKR/day',
//                             style: const TextStyle(
//                               color: VeloceTheme.textPrimary,
//                               fontSize: 14,
//                               fontWeight: FontWeight.w800,
//                             ),
//                           ),
//                         ],
//                       ),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 10, vertical: 6),
//                         decoration: BoxDecoration(
//                           color: VeloceTheme.accentBlue,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: const Text(
//                           'Book',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 11,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // ─── Image Placeholder ────────────────────────────────────────────────────────
// class _ImagePlaceholder extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 120,
//       width: double.infinity,
//       color: VeloceTheme.bgElevated,
//       child: const Icon(
//         Icons.directions_car_outlined,
//         size: 38,
//         color: VeloceTheme.textMuted,
//       ),
//     );
//   }
// }
//
// // ─── Shimmer Loading Grid ─────────────────────────────────────────────────────
// class _ShimmerGrid extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Shimmer.fromColors(
//       baseColor: VeloceTheme.bgCard,
//       highlightColor: VeloceTheme.bgElevated,
//       child: GridView.builder(
//         padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           crossAxisSpacing: 12,
//           mainAxisSpacing: 12,
//           childAspectRatio: 0.72,
//         ),
//         itemCount: 6,
//         itemBuilder: (_, __) => Container(
//           decoration: BoxDecoration(
//             color: VeloceTheme.bgCard,
//             borderRadius: BorderRadius.circular(18),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // ─── Empty Fleet ──────────────────────────────────────────────────────────────
// class _EmptyFleet extends StatelessWidget {
//   const _EmptyFleet();
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.garage_outlined,
//             size: 72,
//             color: VeloceTheme.textMuted.withOpacity(0.35),
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             'Fleet coming soon',
//             style: TextStyle(
//               color: VeloceTheme.textSecondary,
//               fontSize: 17,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(height: 6),
//           const Text(
//             'Vehicles added by the admin will\nappear here automatically.',
//             textAlign: TextAlign.center,
//             style: TextStyle(color: VeloceTheme.textMuted, fontSize: 13, height: 1.5),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // ─── No Search Results ────────────────────────────────────────────────────────
// class _NoResults extends StatelessWidget {
//   final String query;
//   const _NoResults({required this.query});
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.search_off_rounded,
//             size: 64,
//             color: VeloceTheme.textMuted.withOpacity(0.35),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No results for "$query"',
//             style: const TextStyle(
//               color: VeloceTheme.textSecondary,
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(height: 6),
//           const Text(
//             'Try a different brand or model name.',
//             style: TextStyle(color: VeloceTheme.textMuted, fontSize: 13),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // ─── Error View ───────────────────────────────────────────────────────────────
// class _ErrorView extends StatelessWidget {
//   final String message;
//   const _ErrorView({required this.message});
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(28),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.wifi_off_rounded,
//                 size: 56, color: VeloceTheme.accentRed),
//             const SizedBox(height: 16),
//             const Text(
//               'Failed to load fleet',
//               style: TextStyle(
//                 color: VeloceTheme.textSecondary,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const SizedBox(height: 6),
//             Text(
//               message,
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                   color: VeloceTheme.textMuted, fontSize: 12, height: 1.5),
//               maxLines: 3,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
>>>>>>> 4e1ccf4dc0ff7d1ea396ef4698c50eb56e5d28ca
