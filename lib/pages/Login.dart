// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../AppTheme.dart';
// import '../commonWidgets.dart';
//
// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});
//
//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }
//
// class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
//   final _emailCtrl = TextEditingController();
//   final _passCtrl = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   bool _obscure = true;
//   bool _loading = false;
//   String? _error;
//
//   late AnimationController _slideCtrl;
//   late Animation<Offset> _slideAnim;
//   late Animation<double> _fadeAnim;
//
//   @override
//   void initState() {
//     super.initState();
//     _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
//     _slideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
//         .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
//     _fadeAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);
//     _slideCtrl.forward();
//   }
//
//   @override
//   void dispose() {
//     _emailCtrl.dispose();
//     _passCtrl.dispose();
//     _slideCtrl.dispose();
//     super.dispose();
//   }
//
//   Future<void> _signIn() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() { _loading = true; _error = null; });
//
//     try {
//       await FirebaseAuth.instance.signInWithEmailAndPassword(
//         email: _emailCtrl.text.trim(),
//         password: _passCtrl.text,
//       );
//       // StreamBuilder in main.dart handles navigation automatically
//     } on FirebaseAuthException catch (e) {
//       setState(() => _error = _friendlyError(e.code));
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }
//
//   String _friendlyError(String code) {
//     switch (code) {
//       case 'user-not-found': return 'No account found for this email.';
//       case 'wrong-password': return 'Incorrect password. Please try again.';
//       case 'invalid-email': return 'Please enter a valid email address.';
//       case 'user-disabled': return 'This account has been disabled.';
//       case 'too-many-requests': return 'Too many attempts. Please try again later.';
//       default: return 'Sign in failed. Please try again.';
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
//               child: SlideTransition(
//                 position: _slideAnim,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const SizedBox(height: 48),
//
//                     // ─── Logo ──────────────────────────────────────────────
//                     Row(
//                       children: [
//                         Container(
//                           width: 44,
//                           height: 44,
//                           decoration: BoxDecoration(color: VeloceTheme.accentBlue, borderRadius: BorderRadius.circular(12)),
//                           child: const Center(child: Text('V', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900))),
//                         ),
//                         const SizedBox(width: 12),
//                         const Text('VELOCE', style: TextStyle(color: VeloceTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 3)),
//                       ],
//                     ),
//                     const SizedBox(height: 48),
//
//                     const Text('Welcome back', style: TextStyle(color: VeloceTheme.textPrimary, fontSize: 32, fontWeight: FontWeight.w800, height: 1.1)),
//                     const SizedBox(height: 6),
//                     const Text('Sign in to continue driving.', style: TextStyle(color: VeloceTheme.textMuted, fontSize: 15)),
//                     const SizedBox(height: 40),
//
//                     // ─── Email ─────────────────────────────────────────────
//                     _FieldLabel('Email address'),
//                     const SizedBox(height: 8),
//                     TextFormField(
//                       controller: _emailCtrl,
//                       keyboardType: TextInputType.emailAddress,
//                       style: const TextStyle(color: VeloceTheme.textPrimary),
//                       decoration: const InputDecoration(
//                         hintText: 'you@example.com',
//                         prefixIcon: Icon(Icons.mail_outline, color: VeloceTheme.textMuted, size: 20),
//                       ),
//                       validator: (v) {
//                         if (v == null || v.isEmpty) return 'Email is required';
//                         if (!v.contains('@')) return 'Enter a valid email';
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 18),
//
//                     // ─── Password ──────────────────────────────────────────
//                     _FieldLabel('Password'),
//                     const SizedBox(height: 8),
//                     TextFormField(
//                       controller: _passCtrl,
//                       obscureText: _obscure,
//                       style: const TextStyle(color: VeloceTheme.textPrimary),
//                       decoration: InputDecoration(
//                         hintText: '••••••••',
//                         prefixIcon: const Icon(Icons.lock_outline, color: VeloceTheme.textMuted, size: 20),
//                         suffixIcon: IconButton(
//                           icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: VeloceTheme.textMuted, size: 20),
//                           onPressed: () => setState(() => _obscure = !_obscure),
//                         ),
//                       ),
//                       validator: (v) {
//                         if (v == null || v.isEmpty) return 'Password is required';
//                         if (v.length < 6) return 'Password must be at least 6 characters';
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 10),
//
//                     // Forgot password
//                     Align(
//                       alignment: Alignment.centerRight,
//                       child: GestureDetector(
//                         onTap: () => _showForgotPassword(),
//                         child: const Text('Forgot password?', style: TextStyle(color: VeloceTheme.accentBlueBright, fontSize: 13, fontWeight: FontWeight.w600)),
//                       ),
//                     ),
//                     const SizedBox(height: 28),
//
//                     // ─── Error message ─────────────────────────────────────
//                     if (_error != null) ...[
//                       Container(
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: VeloceTheme.accentRed.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(10),
//                           border: Border.all(color: VeloceTheme.accentRed.withOpacity(0.4)),
//                         ),
//                         child: Row(
//                           children: [
//                             const Icon(Icons.error_outline, color: VeloceTheme.accentRed, size: 18),
//                             const SizedBox(width: 8),
//                             Expanded(child: Text(_error!, style: const TextStyle(color: VeloceTheme.accentRed, fontSize: 13))),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                     ],
//
//                     // ─── Sign In Button ────────────────────────────────────
//                     SizedBox(
//                       width: double.infinity,
//                       child: VeloceButton(label: 'Sign In', onPressed: _loading ? null : _signIn, isLoading: _loading, icon: Icons.arrow_forward),
//                     ),
//                     const SizedBox(height: 20),
//
//                     // ─── Divider ───────────────────────────────────────────
//                     Row(
//                       children: [
//                         const Expanded(child: Divider(color: VeloceTheme.borderColor)),
//                         const Padding(
//                           padding: EdgeInsets.symmetric(horizontal: 14),
//                           child: Text('or', style: TextStyle(color: VeloceTheme.textMuted, fontSize: 13)),
//                         ),
//                         const Expanded(child: Divider(color: VeloceTheme.borderColor)),
//                       ],
//                     ),
//                     const SizedBox(height: 20),
//
//                     // ─── Google Sign In ────────────────────────────────────
//                     SizedBox(
//                       width: double.infinity,
//                       child: VeloceButton(
//                         label: 'Continue with Google',
//                         onPressed: () {},
//                         isOutlined: true,
//                         icon: Icons.g_mobiledata,
//                       ),
//                     ),
//                     const SizedBox(height: 40),
//
//                     // ─── Sign Up Link ──────────────────────────────────────
//                     Center(
//                       child: GestureDetector(
//                         onTap: () => Navigator.pushReplacementNamed(context, '/signup'),
//                         child: RichText(
//                           text: const TextSpan(
//                             children: [
//                               TextSpan(text: "Don't have an account? ", style: TextStyle(color: VeloceTheme.textMuted, fontSize: 14)),
//                               TextSpan(text: 'Sign Up', style: TextStyle(color: VeloceTheme.accentBlueBright, fontSize: 14, fontWeight: FontWeight.w700)),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 32),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _showForgotPassword() {
//     final ctrl = TextEditingController();
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: VeloceTheme.bgCard,
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
//       builder: (_) => Padding(
//         padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: VeloceTheme.textMuted, borderRadius: BorderRadius.circular(2)))),
//             const SizedBox(height: 20),
//             const Text('Reset Password', style: TextStyle(color: VeloceTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
//             const SizedBox(height: 6),
//             const Text("Enter your email and we'll send a reset link.", style: TextStyle(color: VeloceTheme.textMuted, fontSize: 13)),
//             const SizedBox(height: 20),
//             TextField(
//               controller: ctrl,
//               keyboardType: TextInputType.emailAddress,
//               style: const TextStyle(color: VeloceTheme.textPrimary),
//               decoration: const InputDecoration(hintText: 'you@example.com', prefixIcon: Icon(Icons.mail_outline, color: VeloceTheme.textMuted, size: 20)),
//             ),
//             const SizedBox(height: 20),
//             SizedBox(
//               width: double.infinity,
//               child: VeloceButton(
//                 label: 'Send Reset Link',
//                 onPressed: () async {
//                   if (ctrl.text.isNotEmpty) {
//                     try {
//                       await FirebaseAuth.instance.sendPasswordResetEmail(email: ctrl.text.trim());
//                       Navigator.pop(context);
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: const Text('Reset link sent! Check your inbox.'),
//                           backgroundColor: VeloceTheme.successGreen,
//                           behavior: SnackBarBehavior.floating,
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                         ),
//                       );
//                     } catch (e) {
//                       Navigator.pop(context);
//                     }
//                   }
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // Helper label widget
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
import 'package:google_fonts/google_fonts.dart';
import '../AppTheme.dart'; // Ensure path is correct
import 'signup.dart';
import 'home.dart';
import 'Admin/dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    final String enteredEmail = _emailController.text.trim().toLowerCase();
    final String enteredPassword = _passwordController.text.trim();

    if (enteredEmail.isEmpty || enteredPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields"), backgroundColor: VeloceTheme.accentRed),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Authenticate with Firebase Auth
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: enteredEmail,
        password: enteredPassword,
      );

      // 2. Fetch the profile document named exactly after the entered email
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(enteredEmail)
          .get();

      if (!mounted) return;

      // 3. Check if the document exists and route accordingly
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String userRole = userData['role'] ?? 'user'; // Safe fallback logic

        if (userRole == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()), // Regular user panel
          );
        }
      } else {
        // Fallback case: Account exists in Auth, but you haven't created the document in Firestore
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("User profile not found in database. Contact system admin."),
            backgroundColor: VeloceTheme.accentGold,
          ),
        );
      }

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Login Failed"), backgroundColor: VeloceTheme.accentRed),
      );
    } catch (e) {
      // Catch any generic Firestore or mapping exceptions to prevent silent freezing
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching user data: $e"), backgroundColor: VeloceTheme.accentRed),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VeloceTheme.bgDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              // Logo
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: VeloceTheme.accentBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/veloce.png',
                    height: 30, // Adjust this height to fit your container scale
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text('Login',
                  style: GoogleFonts.rajdhani(fontSize: 32, fontWeight: FontWeight.w800, color: VeloceTheme.textPrimary)
              ),
              Text('Sign in to continue your journey.',
                  style: TextStyle(color: VeloceTheme.textMuted, fontSize: 16)
              ),
              const SizedBox(height: 40),

              // Inputs
              _buildTextField("Email Address", _emailController, Icons.email_outlined),
              const SizedBox(height: 20),
              _buildTextField("Password", _passwordController, Icons.lock_outline, obscure: true),

              const SizedBox(height: 30),
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
                  onPressed: _login,
                  child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const Spacer(),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpPage())),
                  child: RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(text: "Don't have an account? ", style: TextStyle(color: VeloceTheme.textMuted)),
                        TextSpan(text: "Sign Up", style: TextStyle(color: VeloceTheme.accentBlueBright, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool obscure = false}) {
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: VeloceTheme.accentBlue),
        ),
        filled: true,
        fillColor: VeloceTheme.bgCard,
      ),
    );
  }
}