import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LogInScreen extends StatefulWidget {
  const LogInScreen({super.key});

  @override
  State<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _logIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!_isValidEmail(email)) {
      _showErrorSnackBar('Please enter a valid email');
      return;
    }
    if (password.length < 6) {
      _showErrorSnackBar('Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (Supabase.instance.client.auth.currentUser != null) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/navbar',
            (route) => false,
          );
        }
      } else {
        throw Exception('Login failed');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error logging in: $e');
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF000000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    return Scaffold(
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
                  ).animate().fadeIn(duration: 500.ms),
                  SizedBox(height: screenHeight * 0.05),
                  TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: const TextStyle(color: Color(0xFFE0E0E0)),
                        filled: true,
                        fillColor: const Color(0xFF0B0B45),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFFD700)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFFD700)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
                        ),
                      ),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 20 : 18,
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ).animate().fadeIn(duration: 500.ms),
                    SizedBox(height: screenHeight * 0.02),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: Color(0xFFE0E0E0)),
                        filled: true,
                        fillColor: const Color(0xFF0B0B45),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFFD700)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFFD700)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
                        ),
                      ),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 20 : 18,
                      ),
                      obscureText: true,
                    ).animate().fadeIn(duration: 500.ms),
                    SizedBox(height: screenHeight * 0.03),
                    _isLoading
                        ? const SpinKitCubeGrid(
                            color: Color(0xFFFFD700),
                            size: 50.0,
                          )
                        : ElevatedButton(
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
                            onPressed: _logIn,
                            child: Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: isTablet ? 20 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ).animate().fadeIn(duration: 500.ms),
                    SizedBox(height: screenHeight * 0.02),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/sign-up');
                      },
                      child: Text(
                        'Need an account? Sign Up',
                        style: TextStyle(
                          color: const Color(0xFFE0E0E0),
                          fontSize: isTablet ? 18 : 16,
                        ),
                      ),
                    ).animate().fadeIn(duration: 500.ms),
              ],
            ),
          ),
        )
      ),
    );
  }
}