import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'pages/Landing.dart';
import 'pages/Login.dart';
import 'pages/signup.dart';
import 'pages/home.dart';
import 'pages/VehicleBrowser.dart';
import 'pages/VehicleDetails.dart';
import 'pages/Profile.dart';
import 'pages/Admin/dashboard.dart';
import 'pages/Admin/CRUD.dart';
import 'pages/Admin/userHandling.dart';
import 'AppTheme.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(

    options: DefaultFirebaseOptions.currentPlatform,
  );

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
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: VeloceTheme.accentBlue,
        scaffoldBackgroundColor: VeloceTheme.bgDeep,
      ),


      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Connection check
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return const HomeScreen();
          }

          if (!hasSeenWelcome) {
            return const WelcomeScreen();
          }

          return const LoginPage();
        },
      ),


      routes: {
        "/login": (context) => const LoginPage(),
        "/signup": (context) => const SignUpPage(),
        "/home": (context) => const HomeScreen(),
        "/browser": (context) => const VehiclesScreen(),
      },
    );
  }
}
