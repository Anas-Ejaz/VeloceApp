// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../AppTheme.dart';
// import '../commonWidgets.dart';
// import 'Login.dart';
//
// class SignUpPage extends StatefulWidget {
//   const SignUpPage({super.key});
//
//   @override
//   State<SignUpPage> createState() => _SignUpPageState();
// }
//
// class _SignUpPageState extends State<SignUpPage> with SingleTickerProviderStateMixin {
//   final _nameCtrl = TextEditingController();
//   final _emailCtrl = TextEditingController();
//   final _passCtrl = TextEditingController();
//   final _confirmCtrl = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//
//   bool _obscurePass = true;
//   bool _obscureConfirm = true;
//   bool _loading = false;
//   bool _agreedToTerms = false;
//   String? _error;
//
//   late AnimationController _animCtrl;
//   late Animation<double> _fadeAnim;
//
//   @override
//   void initState() {
//     super.initState();
//     _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
//     _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
//     _animCtrl.forward();
//   }
//
//   @override
//   void dispose() {
//     _nameCtrl.dispose();
//     _emailCtrl.dispose();
//     _passCtrl.dispose();
//     _confirmCtrl.dispose();
//     _animCtrl.dispose();
//     super.dispose();
//   }
//
//   Future<void> _signUp() async {
//     if (!_formKey.currentState!.validate()) return;
//     if (!_agreedToTerms) {
//       setState(() => _error = 'Please accept the terms and conditions.');
//       return;
//     }
//
//     setState(() { _loading = true; _error = null; });
//
//     try {
//       final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
//         email: _emailCtrl.text.trim(),
//         password: _passCtrl.text,
//       );
//       // Update display name
//       await cred.user?.updateDisplayName(_nameCtrl.text.trim());
//       // StreamBuilder in main.dart auto-navigates to HomeScreen
//     } on FirebaseAuthException catch (e) {
//       setState(() => _error = _friendlyError(e.code));
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }
//
//   String _friendlyError(String code) {
//     switch (code) {
//       case 'email-already-in-use': return 'An account already exists for this email.';
//       case 'invalid-email': return 'Please enter a valid email address.';
//       case 'weak-password': return 'Password is too weak. Use at least 6 characters.';
//       case 'operation-not-allowed': return 'Email sign-up is not enabled.';
//       default: return 'Sign up failed. Please try again.';
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: VeloceTheme.bgDeep,
//       body: SafeArea(
//         child: FadeTransition(
//           opacity: _fadeAnim,
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.symmetric(horizontal: 28),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const SizedBox(height: 24),
//
//                   // ─── Back + Logo ──────────────────────────────────────────
//                   Row(
//                     children: [
//                       GestureDetector(
//                         onTap: () => Navigator.pushReplacementNamed(context, '/login'),
//                         child: Container(
//                           padding: const EdgeInsets.all(8),
//                           decoration: BoxDecoration(
//                             color: VeloceTheme.bgCard,
//                             borderRadius: BorderRadius.circular(10),
//                             border: Border.all(color: VeloceTheme.borderColor),
//                           ),
//                           child: const Icon(Icons.arrow_back, color: VeloceTheme.textPrimary, size: 18),
//                         ),
//                       ),
//                       const Spacer(),
//                       Container(
//                         width: 36,
//                         height: 36,
//                         decoration: BoxDecoration(color: VeloceTheme.accentBlue, borderRadius: BorderRadius.circular(10)),
//                         child: const Center(child: Text('V', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 36),
//
//                   const Text('Create account', style: TextStyle(color: VeloceTheme.textPrimary, fontSize: 32, fontWeight: FontWeight.w800, height: 1.1)),
//                   const SizedBox(height: 6),
//                   const Text('Join the Veloce fleet today.', style: TextStyle(color: VeloceTheme.textMuted, fontSize: 15)),
//                   const SizedBox(height: 36),
//
//                   // ─── Full Name ────────────────────────────────────────────
//                   _FieldLabel('Full Name'),
//                   const SizedBox(height: 8),
//                   TextFormField(
//                     controller: _nameCtrl,
//                     textCapitalization: TextCapitalization.words,
//                     style: const TextStyle(color: VeloceTheme.textPrimary),
//                     decoration: const InputDecoration(
//                       hintText: 'Ahmed Raza',
//                       prefixIcon: Icon(Icons.person_outline, color: VeloceTheme.textMuted, size: 20),
//                     ),
//                     validator: (v) {
//                       if (v == null || v.isEmpty) return 'Full name is required';
//                       if (v.trim().split(' ').length < 2) return 'Please enter your full name';
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 16),
//
//                   // ─── Email ────────────────────────────────────────────────
//                   _FieldLabel('Email address'),
//                   const SizedBox(height: 8),
//                   TextFormField(
//                     controller: _emailCtrl,
//                     keyboardType: TextInputType.emailAddress,
//                     style: const TextStyle(color: VeloceTheme.textPrimary),
//                     decoration: const InputDecoration(
//                       hintText: 'you@example.com',
//                       prefixIcon: Icon(Icons.mail_outline, color: VeloceTheme.textMuted, size: 20),
//                     ),
//                     validator: (v) {
//                       if (v == null || v.isEmpty) return 'Email is required';
//                       if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 16),
//
//                   // ─── Password ─────────────────────────────────────────────
//                   _FieldLabel('Password'),
//                   const SizedBox(height: 8),
//                   TextFormField(
//                     controller: _passCtrl,
//                     obscureText: _obscurePass,
//                     style: const TextStyle(color: VeloceTheme.textPrimary),
//                     decoration: InputDecoration(
//                       hintText: '••••••••',
//                       prefixIcon: const Icon(Icons.lock_outline, color: VeloceTheme.textMuted, size: 20),
//                       suffixIcon: IconButton(
//                         icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: VeloceTheme.textMuted, size: 20),
//                         onPressed: () => setState(() => _obscurePass = !_obscurePass),
//                       ),
//                     ),
//                     validator: (v) {
//                       if (v == null || v.isEmpty) return 'Password is required';
//                       if (v.length < 6) return 'Must be at least 6 characters';
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 16),
//
//                   // ─── Confirm Password ─────────────────────────────────────
//                   _FieldLabel('Confirm Password'),
//                   const SizedBox(height: 8),
//                   TextFormField(
//                     controller: _confirmCtrl,
//                     obscureText: _obscureConfirm,
//                     style: const TextStyle(color: VeloceTheme.textPrimary),
//                     decoration: InputDecoration(
//                       hintText: '••••••••',
//                       prefixIcon: const Icon(Icons.lock_outline, color: VeloceTheme.textMuted, size: 20),
//                       suffixIcon: IconButton(
//                         icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: VeloceTheme.textMuted, size: 20),
//                         onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
//                       ),
//                     ),
//                     validator: (v) {
//                       if (v == null || v.isEmpty) return 'Please confirm your password';
//                       if (v != _passCtrl.text) return 'Passwords do not match';
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//
//                   // ─── Terms checkbox ───────────────────────────────────────
//                   GestureDetector(
//                     onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         AnimatedContainer(
//                           duration: const Duration(milliseconds: 200),
//                           width: 20,
//                           height: 20,
//                           margin: const EdgeInsets.only(top: 1),
//                           decoration: BoxDecoration(
//                             color: _agreedToTerms ? VeloceTheme.accentBlue : Colors.transparent,
//                             borderRadius: BorderRadius.circular(5),
//                             border: Border.all(
//                               color: _agreedToTerms ? VeloceTheme.accentBlue : VeloceTheme.borderColor,
//                               width: 1.5,
//                             ),
//                           ),
//                           child: _agreedToTerms
//                               ? const Icon(Icons.check, color: Colors.white, size: 12)
//                               : null,
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: RichText(
//                             text: const TextSpan(
//                               children: [
//                                 TextSpan(text: 'I agree to the ', style: TextStyle(color: VeloceTheme.textMuted, fontSize: 13)),
//                                 TextSpan(text: 'Terms of Service', style: TextStyle(color: VeloceTheme.accentBlueBright, fontSize: 13, fontWeight: FontWeight.w600)),
//                                 TextSpan(text: ' and ', style: TextStyle(color: VeloceTheme.textMuted, fontSize: 13)),
//                                 TextSpan(text: 'Privacy Policy', style: TextStyle(color: VeloceTheme.accentBlueBright, fontSize: 13, fontWeight: FontWeight.w600)),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 24),
//
//                   // ─── Error ────────────────────────────────────────────────
//                   if (_error != null) ...[
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: VeloceTheme.accentRed.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(10),
//                         border: Border.all(color: VeloceTheme.accentRed.withOpacity(0.4)),
//                       ),
//                       child: Row(
//                         children: [
//                           const Icon(Icons.error_outline, color: VeloceTheme.accentRed, size: 18),
//                           const SizedBox(width: 8),
//                           Expanded(child: Text(_error!, style: const TextStyle(color: VeloceTheme.accentRed, fontSize: 13))),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                   ],
//
//                   // ─── Sign Up Button ───────────────────────────────────────
//                   SizedBox(
//                     width: double.infinity,
//                     child: VeloceButton(label: 'Create Account', onPressed: _loading ? null : _signUp, isLoading: _loading, icon: Icons.arrow_forward),
//                   ),
//                   const SizedBox(height: 28),
//
//                   // ─── Sign In Link ─────────────────────────────────────────
//                   Center(
//                     child: GestureDetector(
//                       onTap: () => Navigator.pushReplacementNamed(context, '/login'),
//                       child: RichText(
//                         text: const TextSpan(
//                           children: [
//                             TextSpan(text: 'Already have an account? ', style: TextStyle(color: VeloceTheme.textMuted, fontSize: 14)),
//                             TextSpan(text: 'Sign In', style: TextStyle(color: VeloceTheme.accentBlueBright, fontSize: 14, fontWeight: FontWeight.w700)),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 32),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _FieldLabel extends StatelessWidget {
//   final String text;
//   const _FieldLabel(this.text);
//
//   @override
//   Widget build(BuildContext context) {
//     return Text(text, style: const TextStyle(color: VeloceTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500));
//   }
// }
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
      await FirebaseFirestore.instance.collection('users').doc( _emailController.text.trim()).set({
        'uid': userCredential.user!.uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'user',
        'createdAt': DateTime.now(),
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