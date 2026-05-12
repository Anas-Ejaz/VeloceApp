// welcome_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../AppTheme.dart';
import 'Login.dart'; // Ensure correct path

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = false;

  Future<void> _completeGetStarted() async {
    setState(() => _isLoading = true);
    // 1. Save "seen" state to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_welcome', true);

    if (mounted) {
      // 2. Navigate and replace this screen, so they can't go back
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()), // Navigate to Login/Signup
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // We will use a gradient as the background, matching ref image
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              VeloceTheme.bgDeepGradientStart,
              VeloceTheme.bgDeepGradientEnd,
              VeloceTheme.bgDeep, // True Black at bottom
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // 1. Branding / Logo Section (Centralized)
                Column(
                  children: [
                    // The 'V' Logo Icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: VeloceTheme.accentBlue,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text('V',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            )
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Veloce',
                      style: GoogleFonts.rajdhani(
                        color: VeloceTheme.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 60),

                // 2. Text Content (Ref: Welcome! User Name)
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('👋 Welcome to Veloce!',
                            style: TextStyle(color: VeloceTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600)
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Drive Your Vision.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.rajdhani(
                        color: VeloceTheme.textPrimary,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Ref: Subtitle
                    Text(
                      'Answer a few questions, and Veloce will help you unlock the keys to the world\'s most extraordinary fleet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: VeloceTheme.textMuted.withOpacity(0.8),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 5),

                // 3. The "Get Started" Button (Bottom Pinned)
                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: VeloceTheme.accentBlueBright))
                    : SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      // Replicating the distinct blue-bright-accent feel
                      backgroundColor: VeloceTheme.accentBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _completeGetStarted,
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}