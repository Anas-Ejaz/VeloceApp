import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../AppTheme.dart'; // Ensure path is correct
import 'signup.dart';
import 'home.dart';

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
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Login Failed"), backgroundColor: VeloceTheme.accentRed),
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
                child: const Center(
                  child: Text('V', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
              Text('Welcome Back',
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