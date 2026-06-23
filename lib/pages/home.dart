import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../AppTheme.dart';
import '../models.dart';
import '../commonWidgets.dart';
import '../database_helper.dart';
import 'VehicleBrowser.dart';
import 'VehicleDetails.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PageController _heroController = PageController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  final Stream<QuerySnapshot> _featuredStream = FirebaseFirestore.instance
      .collection('vehicles')
      .limit(6)
      .snapshots();

  List<Vehicle> _cachedFeatured = [];
  bool _cacheLoaded = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
    _loadFeaturedCache();
  }

  Future<void> _loadFeaturedCache() async {
    try {
      final cached = await DatabaseHelper.instance.getCachedVehicles();
      if (mounted) {
        setState(() {
          _cachedFeatured = cached.take(6).toList();
          _cacheLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cacheLoaded = true);
    }
  }

  @override
  void dispose() {
    _heroController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  final List<Map<String, String>> _heroSlides = [
    {
      'title': 'Subscribe. Veloce. Swap.',
      'sub': 'No contracts. Flat fee.',
      'image': 'assets/corolla.jpg',
    },
    {
      'title': 'Drive the Extraordinary.',
      'sub': 'The fleet awaits.',
      'image': 'assets/200.jpg',
    },
    {
      'title': 'Elite. Effortless. Exciting.',
      'sub': 'Your concierge delivers.\nYou just drive.',
      'image': 'assets/f.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: VeloceTheme.bgDeep,
      endDrawer: const _AccountDrawer(),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // ─── App Bar ───────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              pinned: false,
              backgroundColor: VeloceTheme.bgDeep,
              leading: const Padding(
                padding: EdgeInsets.only(left: 20),
                child: _VeloceLogo(),
              ),
              leadingWidth: 80,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: _buildUserAvatar(),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Hero Carousel ─────────────────────────────────────
                  _buildHeroCarousel(),
                  const SizedBox(height: 24),

                  // ─── Stats Row ─────────────────────────────────────────
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(child: StatChip(value: '1.5K+', label: 'Total Bookings')),
                        SizedBox(width: 10),
                        Expanded(child: StatChip(value: '150+', label: 'Fleet Size')),
                        SizedBox(width: 10),
                        Expanded(child: StatChip(value: '99%', label: 'Satisfied Clients')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ─── Why Veloce Cards ──────────────────────────────────
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: SectionHeader(title: 'Why Veloce?'),
                  ),
                  const SizedBox(height: 14),
                  _buildWhyVeloce(),
                  const SizedBox(height: 28),

                  // ─── Featured Fleet (cache-first, then live Firestore) ──
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const VehiclesScreen()),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: SectionHeader(
                        title: 'Featured Fleet',
                        actionLabel: 'View All →',
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildFeaturedFleet(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Featured Fleet row ───────────────────────────────────────────────────
  Widget _buildFeaturedFleet() {
    return SizedBox(
      height: 290,
      child: StreamBuilder<QuerySnapshot>(
        stream: _featuredStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            if (!_cacheLoaded) {
              return _buildLoadingRow();
            }
            if (_cachedFeatured.isNotEmpty) {
              return _buildFeaturedList(_cachedFeatured, isOffline: true);
            }
            return _buildLoadingRow();
          }

          // ─── Firestore error (no internet) ──────────────────────────────────
          if (snapshot.hasError) {
            if (_cachedFeatured.isNotEmpty) {
              return _buildFeaturedList(_cachedFeatured, isOffline: true);
            }
            return _buildEmptyFleetCard();
          }

          final docs = snapshot.data?.docs ?? [];

          // Empty fleet — nothing added by admin yet
          if (docs.isEmpty) {
            return _buildEmptyFleetCard();
          }

          final vehicles = docs
              .map((d) => Vehicle.fromFirestore(d.data() as Map<String, dynamic>, d.id))
              .toList();

          // Sync the cache in the background for next time / offline use.
          DatabaseHelper.instance.replaceAll(vehicles);
          _cachedFeatured = vehicles.take(6).toList();

          return _buildFeaturedList(vehicles, isOffline: false);
        },
      ),
    );
  }

  Widget _buildLoadingRow() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 20, right: 8),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: VeloceTheme.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: VeloceTheme.borderColor),
        ),
      ),
    );
  }

  Widget _buildEmptyFleetCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: VeloceTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VeloceTheme.borderColor),
        ),
        child: Column(
          children: const [
            Icon(Icons.garage_outlined, color: VeloceTheme.textMuted, size: 32),
            SizedBox(height: 10),
            Text('Fleet coming soon', style: TextStyle(color: VeloceTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedList(List<Vehicle> vehicles, {required bool isOffline}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        if (isOffline)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: const [
                Icon(Icons.cloud_off_rounded, color: VeloceTheme.accentGold, size: 13),
                SizedBox(width: 6),
                Text(
                  'Showing saved fleet — offline',
                  style: TextStyle(color: VeloceTheme.accentGold, fontSize: 11),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20, right: 8),
            itemCount: vehicles.length,
            itemBuilder: (ctx, i) => GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VehicleDetailScreen(
                    car: vehicles[i],
                    isOffline: isOffline,
                  ),
                ),
              ),
              child: VehicleCard(vehicle: vehicles[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserAvatar() {
    final User? user = FirebaseAuth.instance.currentUser;
    final String email = user?.email ?? 'Guest';
    final String initial = email.isNotEmpty ? email[0].toUpperCase() : 'G';

    return GestureDetector(
      onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
      child: Center(
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: VeloceTheme.bgCard,
            border: Border.all(
              color: VeloceTheme.accentBlueBright.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: VeloceTheme.accentBlueBright.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 1,
              )
            ],
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                color: VeloceTheme.accentBlueBright,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 260,
          child: PageView.builder(
            controller: _heroController,
            itemCount: _heroSlides.length,
            itemBuilder: (ctx, i) {
              final slide = _heroSlides[i];
              return _HeroSlide(
                title: slide['title']!,
                subtitle: slide['sub']!,
                imageUrl: slide['image']!,
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        SmoothPageIndicator(
          controller: _heroController,
          count: _heroSlides.length,
          effect: const ExpandingDotsEffect(
            activeDotColor: VeloceTheme.accentBlueBright,
            dotColor: VeloceTheme.textMuted,
            dotHeight: 6,
            dotWidth: 6,
            expansionFactor: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildWhyVeloce() {
    final items = [
      {
        'icon': Icons.trending_down_rounded,
        'title': 'Stop the Value Drop',
        'desc': 'Save 20-40% depreciation costs with our app.',
        'color': const Color(0xFF8B5CF6),
      },
      {
        'icon': Icons.shield_outlined,
        'title': 'Lower Financial Risks',
        'desc': 'Bypass high APRs with your subscription fee.',
        'color': VeloceTheme.accentGold,
      },
      {
        'icon': Icons.check_circle_outline,
        'title': 'All-Inclusive, Zero Worry',
        'desc': 'Paperwork, insurance and maintenance is sorted.',
        'color': VeloceTheme.successGreen,
      },
    ];

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20, right: 8),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final item = items[i];
          final color = item['color'] as Color;
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: VeloceTheme.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
              gradient: LinearGradient(
                colors: [color.withOpacity(0.08), VeloceTheme.bgCard],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item['icon'] as IconData, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  item['title'] as String,
                  style: const TextStyle(
                    color: VeloceTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 4),
                Text(
                  item['desc'] as String,
                  style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Hero Slide Widget ────────────────────────────────────────────────────────
class _HeroSlide extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;

  const _HeroSlide({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: VeloceTheme.borderColor),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                imageUrl,
                width: double.infinity,
                height: 260,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: VeloceTheme.bgElevated,
                  ),
                  child: const Center(
                    child: Icon(Icons.image_not_supported, color: VeloceTheme.textMuted),
                  ),
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 260,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      VeloceTheme.bgDeep.withOpacity(0.9),
                      VeloceTheme.bgDeep.withOpacity(0.3),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: title.split(' ').map((word) {
                        final isAccent = word == 'Veloce.' || word == 'Extraordinary.' || word == 'Exciting.';
                        return TextSpan(
                          text: '$word ',
                          style: TextStyle(
                            color: isAccent ? VeloceTheme.accentBlueBright : VeloceTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: VeloceTheme.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  VeloceButton(
                    label: 'View Vehicles →',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const VehiclesScreen()),
                    ),
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

class _VeloceLogo extends StatelessWidget {
  const _VeloceLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Image.asset(
        'assets/veloce.png',
        height: 55,
        fit: BoxFit.contain,
      ),
    );
  }
}

// ─── Account Drawer ───────────────────────────────────────────────────────────
/// Slides in from the right when the avatar in the top app bar is tapped.
/// Shows a larger version of the same initial-letter avatar, the signed-in
/// user's email, and a Logout button that signs out of Firebase and sends
/// the user back to the login screen.
class _AccountDrawer extends StatelessWidget {
  const _AccountDrawer();

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String email = user?.email ?? 'Guest';
    final String initial = email.isNotEmpty ? email[0].toUpperCase() : 'G';

    return Drawer(
      backgroundColor: VeloceTheme.bgDeep,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: VeloceTheme.bgCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: VeloceTheme.borderColor),
                    ),
                    child: const Icon(Icons.close, color: VeloceTheme.textSecondary, size: 18),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ─── Large avatar ────────────────────────────────────────────
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: VeloceTheme.bgCard,
                    border: Border.all(
                      color: VeloceTheme.accentBlueBright.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: VeloceTheme.accentBlueBright.withOpacity(0.15),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: VeloceTheme.accentBlueBright,
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ─── Email ────────────────────────────────────────────────────
              Center(
                child: Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: VeloceTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const Spacer(),

              // ─── Logout button ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: VeloceButton(
                  label: 'Logout',
                  icon: Icons.logout,
                  color: VeloceTheme.accentRed,
                  onPressed: () => _logout(context),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

<<<<<<< HEAD
=======
//
// import 'package:flutter/material.dart';
// import 'package:smooth_page_indicator/smooth_page_indicator.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../AppTheme.dart';
// import '../models.dart';
// import '../commonWidgets.dart';
// import 'VehicleBrowser.dart';
// import 'VehicleDetails.dart';
// import '../database_helper.dart'; // 👈 Sqflite connection layer include ki
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   final PageController _heroController = PageController();
//   late AnimationController _fadeController;
//   late Animation<double> _fadeAnim;
//
//   // ─── Offline-First Local Cache Management State Variables ───
//   List<Vehicle> _featuredVehicles = [];
//   bool _isFeaturedLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
//     _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
//     _fadeController.forward();
//
//     _loadFeaturedData(); // Home screen loads cache or cloud on setup natively
//   }
//
//   @override
//   void dispose() {
//     _heroController.dispose();
//     _fadeController.dispose();
//     super.dispose();
//   }
//
//   // ─── ADAPTIVE DATA FETCH ENGINE (FIRESTORE CLOUD OR SQFLITE CACHE) ───
//   Future<void> _loadFeaturedData() async {
//     try {
//       // 1. Fire up cloud fetching engine with explicit network timeout boundary
//       final snapshot = await FirebaseFirestore.instance
//           .collection('vehicles')
//           .limit(6)
//           .get()
//           .timeout(const Duration(seconds: 4));
//
//       final cloudVehicles = snapshot.docs.map((doc) {
//         return Vehicle.fromFirestore(doc.data(), doc.id);
//       }).toList();
//
//       if (cloudVehicles.isNotEmpty) {
//         // 2. Refresh local database cache rows incrementally
//         for (var vehicle in cloudVehicles) {
//           await DatabaseHelper.instance.insertOrUpdateLocal(vehicle);
//         }
//
//         if (mounted) {
//           setState(() {
//             _featuredVehicles = cloudVehicles;
//             _isFeaturedLoading = false;
//           });
//         }
//       } else {
//         // Fallback natively if Firestore collection acts up empty
//         _loadFeaturedFromLocal();
//       }
//     } catch (e) {
//       debugPrint("Featured cloud sync dropped, pulling local cached nodes silently: $e");
//       // 3. FALLBACK MECHANISM: Silently grab from local SQLite storage if network failure occurs
//       _loadFeaturedFromLocal();
//     }
//   }
//
//   Future<void> _loadFeaturedFromLocal() async {
//     final localVehicles = await DatabaseHelper.instance.getFeaturedCachedVehicles();
//     if (mounted) {
//       setState(() {
//         _featuredVehicles = localVehicles;
//         _isFeaturedLoading = false;
//       });
//     }
//   }
//
//   final List<Map<String, String>> _heroSlides = [
//     {
//       'title': 'Subscribe. Veloce. Swap.',
//       'sub': 'No contracts. Flat fee.',
//       'image': 'assets/corolla.jpg',
//     },
//     {
//       'title': 'Drive the Extraordinary.',
//       'sub': 'The fleet awaits.',
//       'image': 'assets/200.jpg',
//     },
//     {
//       'title': 'Elite. Effortless. Exciting.',
//       'sub': 'Your concierge delivers.\nYou just drive.',
//       'image': 'assets/f.jpg',
//     },
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       backgroundColor: VeloceTheme.bgDeep,
//       endDrawer: const _AccountDrawer(),
//       body: FadeTransition(
//         opacity: _fadeAnim,
//         child: RefreshIndicator(
//           onRefresh: _loadFeaturedData, // Pull down to refresh mechanism triggers real sync
//           color: VeloceTheme.accentBlue,
//           backgroundColor: VeloceTheme.bgCard,
//           child: CustomScrollView(
//             slivers: [
//               // ─── App Bar ───────────────────────────────────────────────────
//               SliverAppBar(
//                 expandedHeight: 0,
//                 floating: true,
//                 pinned: false,
//                 backgroundColor: VeloceTheme.bgDeep,
//                 leading: const Padding(
//                   padding: EdgeInsets.only(left: 20),
//                   child: _VeloceLogo(),
//                 ),
//                 leadingWidth: 80,
//                 actions: [
//                   Padding(
//                     padding: const EdgeInsets.only(right: 20),
//                     child: _buildUserAvatar(),
//                   ),
//                 ],
//               ),
//
//               SliverToBoxAdapter(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // ─── Hero Carousel ─────────────────────────────────────
//                     _buildHeroCarousel(),
//                     const SizedBox(height: 24),
//
//                     // ─── Stats Row ─────────────────────────────────────────
//                     const Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 20),
//                       child: Row(
//                         children: [
//                           Expanded(child: StatChip(value: '1.5K+', label: 'Total Bookings')),
//                           SizedBox(width: 10),
//                           Expanded(child: StatChip(value: '150+', label: 'Fleet Size')),
//                           SizedBox(width: 10),
//                           Expanded(child: StatChip(value: '99%', label: 'Satisfied Clients')),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 28),
//
//                     // ─── Why Veloce Cards ──────────────────────────────────
//                     const Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 20),
//                       child: SectionHeader(title: 'Why Veloce?'),
//                     ),
//                     const SizedBox(height: 14),
//                     _buildWhyVeloce(),
//                     const SizedBox(height: 28),
//
//                     // ─── Featured Fleet (live from Cache/Firestore engine) ───
//                     GestureDetector(
//                       onTap: () => Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (context) => const VehiclesScreen()),
//                       ),
//                       child: const Padding(
//                         padding: EdgeInsets.symmetric(horizontal: 20),
//                         child: SectionHeader(
//                           title: 'Featured Fleet',
//                           actionLabel: 'View All →',
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 14),
//                     _buildFeaturedFleet(),
//                     const SizedBox(height: 32),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ─── Featured Fleet row ───────────────────────────────────────────────────
//   Widget _buildFeaturedFleet() {
//     return SizedBox(
//       height: 290,
//       child: Builder(
//         builder: (context) {
//           // Loading Shimmer Skel placeholders
//           if (_isFeaturedLoading) {
//             return ListView.builder(
//               scrollDirection: Axis.horizontal,
//               padding: const EdgeInsets.only(left: 20, right: 8),
//               itemCount: 3,
//               itemBuilder: (_, __) => Container(
//                 width: 200,
//                 margin: const EdgeInsets.only(right: 12),
//                 decoration: BoxDecoration(
//                   color: VeloceTheme.bgCard,
//                   borderRadius: BorderRadius.circular(18),
//                   border: Border.all(color: VeloceTheme.borderColor),
//                 ),
//               ),
//             );
//           }
//
//           // Empty fleet — database handles zero items flawlessly
//           if (_featuredVehicles.isEmpty) {
//             return Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: VeloceTheme.bgCard,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(color: VeloceTheme.borderColor),
//                 ),
//                 child: const Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.garage_outlined, color: VeloceTheme.textMuted, size: 32),
//                     SizedBox(height: 10),
//                     Text('Fleet coming soon', style: TextStyle(color: VeloceTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
//                   ],
//                 ),
//               ),
//             );
//           }
//
//           return ListView.builder(
//             scrollDirection: Axis.horizontal,
//             padding: const EdgeInsets.only(left: 20, right: 8),
//             itemCount: _featuredVehicles.length,
//             itemBuilder: (ctx, i) => GestureDetector(
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => VehicleDetailScreen(car: _featuredVehicles[i])),
//               ),
//               child: VehicleCard(vehicle: _featuredVehicles[i]),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildUserAvatar() {
//     final User? user = FirebaseAuth.instance.currentUser;
//     final String email = user?.email ?? 'Guest';
//     final String initial = email.isNotEmpty ? email[0].toUpperCase() : 'G';
//
//     return GestureDetector(
//       onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
//       child: Center(
//         child: Container(
//           width: 36,
//           height: 36,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: VeloceTheme.bgCard,
//             border: Border.all(
//               color: VeloceTheme.accentBlueBright.withOpacity(0.4),
//               width: 1.5,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: VeloceTheme.accentBlueBright.withOpacity(0.1),
//                 blurRadius: 8,
//                 spreadRadius: 1,
//               )
//             ],
//           ),
//           child: Center(
//             child: Text(
//               initial,
//               style: const TextStyle(
//                 color: VeloceTheme.accentBlueBright,
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 letterSpacing: 0,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildHeroCarousel() {
//     return Column(
//       children: [
//         SizedBox(
//           height: 260,
//           child: PageView.builder(
//             controller: _heroController,
//             itemCount: _heroSlides.length,
//             itemBuilder: (ctx, i) {
//               final slide = _heroSlides[i];
//               return _HeroSlide(
//                 title: slide['title']!,
//                 subtitle: slide['sub']!,
//                 imageUrl: slide['image']!,
//               );
//             },
//           ),
//         ),
//         const SizedBox(height: 12),
//         SmoothPageIndicator(
//           controller: _heroController,
//           count: _heroSlides.length,
//           effect: const ExpandingDotsEffect(
//             activeDotColor: VeloceTheme.accentBlueBright,
//             dotColor: VeloceTheme.textMuted,
//             dotHeight: 6,
//             dotWidth: 6,
//             expansionFactor: 3,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildWhyVeloce() {
//     final items = [
//       {
//         'icon': Icons.trending_down_rounded,
//         'title': 'Stop the Value Drop',
//         'desc': 'Save 20-40% depreciation costs with our app.',
//         'color': const Color(0xFF8B5CF6),
//       },
//       {
//         'icon': Icons.shield_outlined,
//         'title': 'Lower Financial Risks',
//         'desc': 'Bypass high APRs with your subscription fee.',
//         'color': VeloceTheme.accentGold,
//       },
//       {
//         'icon': Icons.check_circle_outline,
//         'title': 'All-Inclusive, Zero Worry',
//         'desc': 'Paperwork, insurance and maintenance is sorted.',
//         'color': VeloceTheme.successGreen,
//       },
//     ];
//
//     return SizedBox(
//       height: 160,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         padding: const EdgeInsets.only(left: 20, right: 8),
//         itemCount: items.length,
//         itemBuilder: (ctx, i) {
//           final item = items[i];
//           final color = item['color'] as Color;
//           return Container(
//             width: 160,
//             margin: const EdgeInsets.only(right: 12),
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: VeloceTheme.bgCard,
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(color: color.withOpacity(0.3)),
//               gradient: LinearGradient(
//                 colors: [color.withOpacity(0.08), VeloceTheme.bgCard],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   width: 36,
//                   height: 36,
//                   decoration: BoxDecoration(
//                     color: color.withOpacity(0.15),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Icon(item['icon'] as IconData, color: color, size: 20),
//                 ),
//                 const Spacer(),
//                 Text(
//                   item['title'] as String,
//                   style: const TextStyle(
//                     color: VeloceTheme.textPrimary,
//                     fontSize: 13,
//                     fontWeight: FontWeight.w700,
//                   ),
//                   maxLines: 2,
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   item['desc'] as String,
//                   style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 11),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
//
// // ─── Hero Slide Widget ────────────────────────────────────────────────────────
// class _HeroSlide extends StatelessWidget {
//   final String title;
//   final String subtitle;
//   final String imageUrl;
//
//   const _HeroSlide({
//     required this.title,
//     required this.subtitle,
//     required this.imageUrl,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: VeloceTheme.borderColor),
//         ),
//         child: Stack(
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(20),
//               child: Image.asset(
//                 imageUrl,
//                 width: double.infinity,
//                 height: 260,
//                 fit: BoxFit.cover,
//                 errorBuilder: (_, __, ___) => Container(
//                   height: 260,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(20),
//                     color: VeloceTheme.bgElevated,
//                   ),
//                   child: const Center(
//                     child: Icon(Icons.image_not_supported, color: VeloceTheme.textMuted),
//                   ),
//                 ),
//               ),
//             ),
//             ClipRRect(
//               borderRadius: BorderRadius.circular(20),
//               child: Container(
//                 height: 260,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [
//                       VeloceTheme.bgDeep.withOpacity(0.9),
//                       VeloceTheme.bgDeep.withOpacity(0.3),
//                       Colors.transparent,
//                     ],
//                     begin: Alignment.bottomCenter,
//                     end: Alignment.topCenter,
//                   ),
//                 ),
//               ),
//             ),
//             Positioned(
//               bottom: 20,
//               left: 20,
//               right: 20,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   RichText(
//                     text: TextSpan(
//                       children: title.split(' ').map((word) {
//                         final isAccent = word == 'Veloce.' || word == 'Extraordinary.' || word == 'Exciting.';
//                         return TextSpan(
//                           text: '$word ',
//                           style: TextStyle(
//                             color: isAccent ? VeloceTheme.accentBlueBright : VeloceTheme.textPrimary,
//                             fontSize: 22,
//                             fontWeight: FontWeight.w800,
//                             letterSpacing: -0.5,
//                           ),
//                         );
//                       }).toList(),
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     subtitle,
//                     style: const TextStyle(
//                       color: VeloceTheme.textSecondary,
//                       fontSize: 13,
//                       height: 1.5,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   VeloceButton(
//                     label: 'View Vehicles →',
//                     onPressed: () => Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (context) => const VehiclesScreen()),
//                     ),
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
// class _VeloceLogo extends StatelessWidget {
//   const _VeloceLogo({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Align(
//       alignment: Alignment.centerLeft,
//       child: Image.asset(
//         'assets/veloce.png',
//         height: 55,
//         fit: BoxFit.contain,
//       ),
//     );
//   }
// }
//
// // ─── Account Drawer ───────────────────────────────────────────────────────────
// class _AccountDrawer extends StatelessWidget {
//   const _AccountDrawer();
//
//   Future<void> _logout(BuildContext context) async {
//     await FirebaseAuth.instance.signOut();
//     if (context.mounted) {
//       Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final User? user = FirebaseAuth.instance.currentUser;
//     final String email = user?.email ?? 'Guest';
//     final String initial = email.isNotEmpty ? email[0].toUpperCase() : 'G';
//
//     return Drawer(
//       backgroundColor: VeloceTheme.bgDeep,
//       child: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Close button
//               Align(
//                 alignment: Alignment.topRight,
//                 child: GestureDetector(
//                   onTap: () => Navigator.of(context).pop(),
//                   child: Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: VeloceTheme.bgCard,
//                       borderRadius: BorderRadius.circular(10),
//                       border: Border.all(color: VeloceTheme.borderColor),
//                     ),
//                     child: const Icon(Icons.close, color: VeloceTheme.textSecondary, size: 18),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 32),
//
//               // ─── Large avatar ────────────────────────────────────────────
//               Center(
//                 child: Container(
//                   width: 96,
//                   height: 96,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: VeloceTheme.bgCard,
//                     border: Border.all(
//                       color: VeloceTheme.accentBlueBright.withOpacity(0.5),
//                       width: 2,
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: VeloceTheme.accentBlueBright.withOpacity(0.15),
//                         blurRadius: 16,
//                         spreadRadius: 2,
//                       ),
//                     ],
//                   ),
//                   child: Center(
//                     child: Text(
//                       initial,
//                       style: const TextStyle(
//                         color: VeloceTheme.accentBlueBright,
//                         fontSize: 38,
//                         fontWeight: FontWeight.w800,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 18),
//
//               // ─── Email ────────────────────────────────────────────────────
//               Center(
//                 child: Text(
//                   email,
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(
//                     color: VeloceTheme.textPrimary,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//
//               const Spacer(),
//
//               // ─── Logout button ────────────────────────────────────────────
//               SizedBox(
//                 width: double.infinity,
//                 child: VeloceButton(
//                   label: 'Logout',
//                   icon: Icons.logout,
//                   color: VeloceTheme.accentRed,
//                   onPressed: () => _logout(context),
//                 ),
//               ),
//               const SizedBox(height: 8),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
>>>>>>> 4e1ccf4dc0ff7d1ea396ef4698c50eb56e5d28ca
