import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gullak/Navbar.dart';
import 'package:gullak/screens/auth_screen.dart';
import 'package:gullak/screens/log_in.dart';
import 'package:gullak/screens/sign_up.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://kfybvhmtezaemhwqymag.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtmeWJ2aG10ZXphZW1od3F5bWFnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc5NDQ3MjksImV4cCI6MjA2MzUyMDcyOX0.5aMNFS8iA51_lj3iEIhWQcRF0Z7my0KFvS_39Rl4QmU',
  );
  runApp(const MyApp());
}

class AuthNavigatorObserver extends NavigatorObserver {
  late final StreamSubscription<AuthState> _authSubscription;

  AuthNavigatorObserver() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut && navigator != null) {
        navigator!.pushNamedAndRemoveUntil('/auth', (route) => false);
      }
    });
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    debugPrint('Pushed route: ${route.settings.name}');
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    debugPrint('Popped route: ${route.settings.name}, Previous: ${previousRoute?.settings.name}');
  }

  void dispose() {
    _authSubscription.cancel();
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Supabase.instance.client.auth.currentUser;
      final route = user != null ? '/navbar' : '/auth';
      debugPrint('SplashScreen navigating to $route');
      Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B45),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.savings,
              size: 80,
              color: const Color(0xFFFFD700),
            ),
            const SizedBox(height: 20),
            Text(
              'Gullak',
              style: GoogleFonts.orbitron(
                color: const Color(0xFFFFD700),
                fontSize: 40,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 20),
            const SpinKitCubeGrid(
              color: Color(0xFFFFD700),
              size: 40,
            ),
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _authObserver = AuthNavigatorObserver();

  @override
  void dispose() {
    _authObserver.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gullak',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0B0B45),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFE0E0E0)),
          bodyMedium: TextStyle(color: Color(0xFFE0E0E0)),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF000000),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      navigatorObservers: [_authObserver],
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/sign-up': (context) => SignUpScreen(),
        '/log-in': (context) => LogInScreen(),
        '/navbar': (context) => const Navbar(),
      },
    );
  }
}