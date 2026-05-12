import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Import your pages
import 'pages/Landing.dart';
import 'pages/login.dart';
import 'pages/signup.dart';
import 'pages/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Check if they've seen the "Get Started" page
  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;

  runApp(MyApp(hasSeenWelcome: hasSeenWelcome));
}

class MyApp extends StatelessWidget {
  final bool hasSeenWelcome;
  const MyApp({super.key, required this.hasSeenWelcome});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Veloce',

      // The StreamBuilder checks if a user is already signed into Firebase
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. If user is logged in, go straight to Home
          if (snapshot.hasData) {
            return const HomeScreen();
          }

          // 2. If not logged in, check if they need the Welcome screen
          if (!hasSeenWelcome) {
            return const WelcomeScreen();
          }

          // 3. Otherwise, go to Login
          return const LoginPage();
        },
      ),

      routes: {
        "/login": (context) => const LoginPage(),
        "/signup": (context) => const SignUpPage(),
        "/home": (context) => const HomeScreen(),
      },
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
// import 'pages/login.dart';
// import 'pages/signup.dart';
// import 'pages/home.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Veloce App',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//       ),
//
//       debugShowCheckedModeBanner: false,
//
//       // App starts from login page
//       home: const SignUpPage (),
//
//       routes: {
//         "/login": (context) => const LoginPage(),
//       //  "/signup": (context) => const SignUpPage(),
//         "/home": (context) => const SignUpPage (),
//         "/login": (context) => const LoginPage(),
//       },
//     );
//   }
// }