import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../AppTheme.dart';
import 'home.dart';
import 'VehicleBrowser.dart';
import 'Profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Admin detection — checks Firebase custom claims or email pattern
  bool get _isAdmin {
    final user = FirebaseAuth.instance.currentUser;
    // Adjust this check to match your admin logic
    // e.g. check email domain, or use custom claims in Firestore
    return user?.email?.endsWith('@veloce.admin') == true ||
        user?.email == 'admin@veloce.com';
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    VehiclesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VeloceTheme.bgDeep,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        isAdmin: _isAdmin,
      ),
    );
  }
}

// ─── Custom Bottom Navigation Bar ────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  final bool isAdmin;

  const _BottomNav({required this.currentIndex, required this.onTap, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
      _NavItem(icon: Icons.directions_car_outlined, activeIcon: Icons.directions_car, label: 'Vehicles'),
      _NavItem(icon: Icons.swap_horiz_outlined, activeIcon: Icons.swap_horiz, label: 'Schedule Swap'),
      _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: VeloceTheme.bgCard,
        border: Border(top: BorderSide(color: VeloceTheme.borderColor, width: 0.8)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final active = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          decoration: BoxDecoration(
                            color: active ? VeloceTheme.accentBlue.withOpacity(0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            active ? item.activeIcon : item.icon,
                            color: active ? VeloceTheme.accentBlueBright : VeloceTheme.textMuted,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: active ? VeloceTheme.accentBlueBright : VeloceTheme.textMuted,
                            fontSize: 10,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}