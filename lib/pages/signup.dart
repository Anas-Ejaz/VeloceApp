import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../AppTheme.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    setState(() => _isLoading = true);
    try {
      // 1. Create User in Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Save User Data to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'createdAt': DateTime.now(),
        'membership': 'Basic',
      });

      if (mounted) Navigator.pop(context); // Go back to login or home
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Registration Failed"), backgroundColor: VeloceTheme.accentRed),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: VeloceTheme.bgDeep,
  //     appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: VeloceTheme.textPrimary)),
  //     body: SingleChildScrollView(
  //       padding: const EdgeInsets.symmetric(horizontal: 24),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text('Create Account',
  //               style: GoogleFonts.rajdhani(fontSize: 32, fontWeight: FontWeight.w800, color: VeloceTheme.textPrimary)
  //           ),
  //           const SizedBox(height: 10),
  //           const Text('Join the elite fleet of Veloce users.', style: TextStyle(color: VeloceTheme.textMuted)),
  //           const SizedBox(height: 40),
  //
  //           _buildTextField("Full Name", _nameController, Icons.person_outline),
  //           const SizedBox(height: 20),
  //           _buildTextField("Email Address", _emailController, Icons.email_outlined),
  //           const SizedBox(height: 20),
  //           _buildTextField("Password", _passwordController, Icons.lock_outline, obscure: true),
  //
  //           const SizedBox(height: 40),
  //           _isLoading
  //               ? const Center(child: CircularProgressIndicator(color: VeloceTheme.accentBlueBright))
  //               : SizedBox(
  //             width: double.infinity,
  //             child: ElevatedButton(
  //               style: ElevatedButton.styleFrom(
  //                 backgroundColor: VeloceTheme.accentBlue,
  //                 padding: const EdgeInsets.symmetric(vertical: 16),
  //                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //               ),
  //               onPressed: _signUp,
  //               child: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  // signup.dart - Add this to your build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VeloceTheme.bgDeep,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: VeloceTheme.textPrimary)
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Account',
                style: GoogleFonts.rajdhani(fontSize: 32, fontWeight: FontWeight.w800, color: VeloceTheme.textPrimary)
            ),
            const SizedBox(height: 10),
            const Text('Join the elite fleet of Veloce users.', style: TextStyle(color: VeloceTheme.textMuted)),
            const SizedBox(height: 40),

            _buildTextField("Full Name", _nameController, Icons.person_outline),
            const SizedBox(height: 20),
            _buildTextField("Email Address", _emailController, Icons.email_outlined),
            const SizedBox(height: 20),
            _buildTextField("Password", _passwordController, Icons.lock_outline, obscure: true),

            const SizedBox(height: 40),
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: VeloceTheme.accentBlueBright))
                : SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: VeloceTheme.accentBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _signUp,
                child: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),

            // ─── ADDED LOGIN LINK HERE ─────────────────────────────────────────
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () {
                  // Since LoginPage is likely your previous screen or in routes
                  Navigator.pushReplacementNamed(context, "/login");
                },
                child: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                          text: "Already have an account? ",
                          style: TextStyle(color: VeloceTheme.textMuted, fontSize: 14)
                      ),
                      TextSpan(
                        text: "Login",
                        style: TextStyle(
                            color: VeloceTheme.accentBlueBright,
                            fontWeight: FontWeight.bold,
                            fontSize: 14
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool obscure = false}) {
    // Reusing the same styling as Login for consistency
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: VeloceTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: VeloceTheme.textMuted),
        prefixIcon: Icon(icon, color: VeloceTheme.textMuted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: VeloceTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: VeloceTheme.accentBlue)),
        filled: true,
        fillColor: VeloceTheme.bgCard,
      ),
    );
  }
}