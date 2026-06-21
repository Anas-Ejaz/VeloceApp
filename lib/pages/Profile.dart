import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../AppTheme.dart';
import '../models.dart';
import '../commonWidgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final name = firebaseUser?.displayName ?? 'User';
    final email = firebaseUser?.email ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: VeloceTheme.bgDeep,
      body: CustomScrollView(
        slivers: [
          // ─── Profile Header ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), VeloceTheme.bgDeep],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Profile', style: TextStyle(color: VeloceTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: VeloceTheme.bgCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: VeloceTheme.borderColor),
                          ),
                          child: const Icon(Icons.settings_outlined, color: VeloceTheme.textSecondary, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Avatar — initials circle (no avatarUrl in the real Firebase user)
                  Stack(
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: VeloceTheme.accentBlue.withOpacity(0.15),
                          border: Border.all(color: VeloceTheme.accentBlue, width: 2.5),
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(color: VeloceTheme.accentBlueBright, fontSize: 32, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(color: VeloceTheme.accentBlue, shape: BoxShape.circle, border: Border.all(color: VeloceTheme.bgDeep, width: 2)),
                          child: const Icon(Icons.edit, color: Colors.white, size: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(name, style: const TextStyle(color: VeloceTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 13)),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ─── My Bookings (live from Firestore) ──────────────────
                  const SectionHeader(title: 'My Bookings'),
                  const SizedBox(height: 12),
                  if (firebaseUser == null)
                    const Text('Sign in to see your bookings.', style: TextStyle(color: VeloceTheme.textMuted, fontSize: 13))
                  else
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('bookings')
                          .where('userId', isEqualTo: firebaseUser.uid)
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: CircularProgressIndicator(color: VeloceTheme.accentBlueBright)),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return GlassCard(
                            child: Column(
                              children: const [
                                Icon(Icons.directions_car_outlined, color: VeloceTheme.textMuted, size: 32),
                                SizedBox(height: 10),
                                Text('No bookings yet', style: TextStyle(color: VeloceTheme.textSecondary, fontSize: 14)),
                                SizedBox(height: 4),
                                Text('Book a vehicle to see it here.', style: TextStyle(color: VeloceTheme.textMuted, fontSize: 12)),
                              ],
                            ),
                          );
                        }

                        final bookings = docs
                            .map((d) => BookingRecord.fromFirestore(d.data() as Map<String, dynamic>, d.id))
                            .toList();

                        return Column(
                          children: bookings
                              .map((b) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: BookingRecordTile(booking: b),
                          ))
                              .toList(),
                        );
                      },
                    ),
                  const SizedBox(height: 20),

                  // ─── Menu Items ────────────────────────────────────────
                  const SectionHeader(title: 'Account'),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _MenuItem(icon: Icons.person_outline, label: 'Edit Profile', onTap: () {}),
                        _Divider(),
                        _MenuItem(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () {}),
                        _Divider(),
                        _MenuItem(icon: Icons.location_on_outlined, label: 'Saved Locations', onTap: () {}),
                        _Divider(),
                        _MenuItem(icon: Icons.help_outline_rounded, label: 'Help & Support', onTap: () {}),
                        _Divider(),
                        _MenuItem(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () {}),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Contact section
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Contact Support', style: TextStyle(color: VeloceTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        _ContactField(label: 'Full Name', hint: name),
                        const SizedBox(height: 10),
                        _ContactField(label: 'E-Mail', hint: email),
                        const SizedBox(height: 10),
                        _ContactField(label: 'Message', hint: 'Write your message...', maxLines: 3),
                        const SizedBox(height: 14),
                        SizedBox(width: double.infinity, child: VeloceButton(label: 'Send Message', onPressed: () {})),
                        const SizedBox(height: 16),
                        const Center(child: Text('Based in Lahore, PK', style: TextStyle(color: VeloceTheme.textMuted, fontSize: 12))),
                        const Center(child: Text('veloceautes@gmail.com', style: TextStyle(color: VeloceTheme.accentBlueBright, fontSize: 12))),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SocialIcon(icon: Icons.work_outline, label: 'LinkedIn'),
                            const SizedBox(width: 16),
                            _SocialIcon(icon: Icons.code, label: 'GitHub'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Footer nav links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: ['Home', 'About', 'Inventory', 'Login', 'Contact']
                        .map((t) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(t, style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 12)),
                    ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),

                  // Sign Out
                  SizedBox(
                    width: double.infinity,
                    child: VeloceButton(
                      label: 'Sign Out',
                      onPressed: () => _showSignOutDialog(context),
                      color: VeloceTheme.accentRed,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: VeloceTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out', style: TextStyle(color: VeloceTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to sign out?', style: TextStyle(color: VeloceTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: VeloceTheme.textMuted))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              // StreamBuilder in main.dart auto-redirects to /login.
            },
            child: const Text('Sign Out', style: TextStyle(color: VeloceTheme.accentRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: VeloceTheme.textSecondary, size: 20),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: const TextStyle(color: VeloceTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))),
            const Icon(Icons.chevron_right, color: VeloceTheme.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(color: VeloceTheme.borderColor, height: 1, indent: 50);
  }
}

class _ContactField extends StatelessWidget {
  final String label;
  final String hint;
  final int maxLines;

  const _ContactField({required this.label, required this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          maxLines: maxLines,
          style: const TextStyle(color: VeloceTheme.textPrimary, fontSize: 14),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SocialIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: VeloceTheme.bgElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: VeloceTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: VeloceTheme.textSecondary, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: VeloceTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}