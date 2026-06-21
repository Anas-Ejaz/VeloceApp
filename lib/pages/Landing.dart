import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../AppTheme.dart';
import '../commonWidgets.dart';
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  final List<_OnboardSlide> _slides = const [
    _OnboardSlide(
      image: 'assets/lq.jpg',
      title: 'Subscribe.\nVeloce.\nSwap.',
      subtitle: 'Access a world-class fleet of high-performance vehicles — no contracts, no ownership headaches.',
      accent: 'Veloce.',
    ),
    _OnboardSlide(
      image: 'assets/landing2.jpg',
      title: 'Drive\nthe Extraordinary.',
      subtitle: 'Swap to a new ride whenever the mood strikes.',
      accent: 'Extraordinary.',
    ),
    _OnboardSlide(
      image: 'assets/landing3.jpg',
      title: 'Zero\nWorry.\nAll Thrill.',
      subtitle: 'Insurance, maintenance, and paperwork — all handled. You just drive.',
      accent: 'Zero',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_welcome', true);
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VeloceTheme.bgDeep,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            // ─── Page View ─────────────────────────────────────────────────
            PageView.builder(
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: _slides.length,
              itemBuilder: (ctx, i) => _SlideView(slide: _slides[i]),
            ),

            // ─── Top: Skip button ──────────────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 20,
              child: _currentPage < _slides.length - 1
                  ? GestureDetector(
                onTap: _finishOnboarding,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: VeloceTheme.bgCard.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: VeloceTheme.borderColor),
                  ),
                  child: const Text('Skip', style: TextStyle(color: VeloceTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              )
                  : const SizedBox.shrink(),
            ),

            // ─── Bottom Controls ───────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(28, 24, 28, MediaQuery.of(context).padding.bottom + 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [VeloceTheme.bgDeep, VeloceTheme.bgDeep.withOpacity(0)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dot indicators
                    Row(
                      children: List.generate(_slides.length, (i) {
                        final active = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 6),
                          width: active ? 24 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active ? VeloceTheme.accentBlueBright : VeloceTheme.textMuted,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 28),

                    Row(
                      children: [
                        Expanded(
                          child: VeloceButton(
                            label: _currentPage == _slides.length - 1 ? 'Get Started →' : 'Next →',
                            onPressed: _nextPage,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (_currentPage == _slides.length - 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account? ', style: TextStyle(color: VeloceTheme.textMuted, fontSize: 13)),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                            child: const Text('Sign In', style: TextStyle(color: VeloceTheme.accentBlueBright, fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Slide Data ───────────────────────────────────────────────────────────────
class _OnboardSlide {
  final String image;
  final String title;
  final String subtitle;
  final String accent;

  const _OnboardSlide({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.accent,
  });
}

// ─── Slide View ───────────────────────────────────────────────────────────────
class _SlideView extends StatelessWidget {
  final _OnboardSlide slide;

  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image
        Image.network(
          slide.image,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: VeloceTheme.bgElevated),
        ),

        // Dark gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                VeloceTheme.bgDeep,
                VeloceTheme.bgDeep.withOpacity(0.5),
                Colors.transparent,
                VeloceTheme.bgDeep.withOpacity(0.6),
                VeloceTheme.bgDeep,
              ],
              stops: const [0.0, 0.15, 0.45, 0.65, 1.0],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),

        // Top logo
        Positioned(
          top: kToolbarHeight + 8,
          left: 28,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
            child: Center(
              child: Image.asset(
                'assets/veloce.png',
                height: 35, // Adjust this height to fit your container scale
                fit: BoxFit.contain,
              ),
            ),
                ),
              const SizedBox(width: 10),
              const Text('VELOCE', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 3)),
            ],
          ),
        ),

        // Content
        Positioned(
          bottom: 220,
          left: 28,
          right: 28,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Animated title with accent
              RichText(
                text: TextSpan(
                  children: slide.title.split('\n').map((line) {
                    final isAccent = line.trim() == slide.accent;
                    return TextSpan(
                      text: '$line\n',
                      style: TextStyle(
                        color: isAccent ? VeloceTheme.accentBlueBright : VeloceTheme.textPrimary,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: -1,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                slide.subtitle,
                style: const TextStyle(
                  color: VeloceTheme.textSecondary,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

