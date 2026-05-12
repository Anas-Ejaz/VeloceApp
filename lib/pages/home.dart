import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../AppTheme.dart';
import '../models.dart';
import '../commonWidgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final PageController _heroController = PageController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
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
      'sub': 'No contracts. Flat fee.\nEndless possibilities.',
      'image': 'https://images.unsplash.com/photo-1614162692292-7ac56d7f7f1e?w=900',
    },
    {
      'title': 'Drive the Extraordinary.',
      'sub': 'From Porsche to Lamborghini.\nThe fleet awaits.',
      'image': 'https://images.unsplash.com/photo-1544636331-e26879cd4d9b?w=900',
    },
    {
      'title': 'Elite. Effortless. Exciting.',
      'sub': 'Your concierge delivers.\nYou just drive.',
      'image': 'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=900',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VeloceTheme.bgDeep,
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
              leading: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: _VeloceLogo(),
              ),
              leadingWidth: 80,
              actions: [
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: VeloceTheme.textPrimary),
                      onPressed: () {},
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: VeloceTheme.accentRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: const [
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SectionHeader(title: 'Why Veloce?'),
                  ),
                  const SizedBox(height: 14),
                  _buildWhyVeloce(),
                  const SizedBox(height: 28),

                  // ─── Featured Fleet ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SectionHeader(
                      title: 'Featured Fleet',
                      actionLabel: 'View All →',
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 290,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 20, right: 8),
                      itemCount: SampleData.vehicles.length,
                      itemBuilder: (ctx, i) => VehicleCard(
                        vehicle: SampleData.vehicles[i],
                        onTap: () {},
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
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
            // Background image
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
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
                ),
              ),
            ),
            // Gradient overlay
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
            // Text content
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
                    onPressed: () {},
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

// ─── Veloce Logo Widget ───────────────────────────────────────────────────────
class _VeloceLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: VeloceTheme.accentBlue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              'V',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}