import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';

class AuthScreen extends StatefulWidget {
  final bool showLoginForm;

  const AuthScreen({this.showLoginForm = false, Key? key}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  DateTime? _lastPressed;

  Future<bool> _handleBackPress() async {
    if (Platform.isAndroid) {
      const duration = Duration(seconds: 2);
      if (_lastPressed == null || DateTime.now().difference(_lastPressed!) > duration) {
        _lastPressed = DateTime.now();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Press back again to exit'),
            duration: Duration(seconds: 2),
          ),
        );
        return false;
      }
      return true;
    }
    return false; // iOS: Disable back
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _handleBackPress();
        if (shouldExit && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0B45),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.08,
                vertical: screenHeight * 0.05,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.savings,
                    size: isTablet ? 100 : 80,
                    color: const Color(0xFFFFD700),
                  ).animate().fadeIn(duration: 500.ms),
                  SizedBox(height: screenHeight * 0.03),
                  Text(
                    'Gullak',
                    style: GoogleFonts.orbitron(
                      color: const Color(0xFFFFD700),
                      fontSize: screenWidth * 0.11,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(duration: 1000.ms),
                  SizedBox(height: screenHeight * 0.05),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF000000),
                        foregroundColor: const Color(0xFFFFD700),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.1,
                          vertical: screenHeight * 0.02,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/sign-up');
                      },
                      child: Text(
                        'Sign Up with Email',
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ).animate().fadeIn(duration: 500.ms),
                    SizedBox(height: screenHeight * 0.02),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/log-in');
                      },
                      child: Text(
                        'Already have an account? Log In',
                        style: TextStyle(
                          color: const Color(0xFFE0E0E0),
                          fontSize: isTablet ? 18 : 16,
                        ),
                      ),
                    ).animate().fadeIn(duration: 500.ms),
                  
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}