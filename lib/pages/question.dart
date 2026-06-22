import 'package:flutter/material.dart';

class Signupp extends StatefulWidget {
  const Signupp({super.key});

  @override
  State<Signupp> createState() => _SignuppState();
}

class _SignuppState extends State<Signupp> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SingleChildScrollView(
        child: TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: "label",
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: VeloceTheme.borderColor),
            ),
      ),
    );
  }
}
