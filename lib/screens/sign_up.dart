import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'auth_screen.dart'; // Redirect to AuthScreen after sign-up

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (!_isValidEmail(email)) {
      _showErrorSnackBar('Please enter a valid email');
      return;
    }
    if (name.length < 2) {
      _showErrorSnackBar('Name must be at least 2 characters');
      return;
    }
    if (password.length < 6) {
      _showErrorSnackBar('Password must be at least 6 characters');
      return;
    }
    if (password != confirmPassword) {
      _showErrorSnackBar('Passwords do not match');
      return;
    }

    try {
      setState(() => _isLoading = true);
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user != null) {
        // Save name to profiles table
        await Supabase.instance.client.from('profiles').insert({
          'user_id': user.id,
          'name': name,
          'email': email,
        });
        // Sign out to prevent auto-login
        await Supabase.instance.client.auth.signOut();
        // Redirect to LogInScreen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AuthScreen()),
          );
        }
      } else {
        throw Exception('Sign-up failed');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error signing up: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF000000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Color(0xFF0B0B45), // Dark navy blue
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Color(0xFFFFD700),
                  size: screenWidth * 0.06,
                ),
                onPressed: () => Navigator.pop(context),
              ),
      ),
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
                  SizedBox(height: screenHeight * 0.03),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Color(0xFFE0E0E0)),
                    filled: true,
                    fillColor: Color(0xFF0B0B45),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFFFFD700)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFFFFD700)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFFFFD700), width: 2),
                    ),
                  ),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 20 : 18,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: screenHeight * 0.02),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Color(0xFFE0E0E0)),
                    filled: true,
                    fillColor: Color(0xFF0B0B45),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFFFFD700)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFFFFD700)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFFFFD700), width: 2),
                    ),
                  ),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 20 : 18,
                  ),
                  keyboardType: TextInputType.name,
                  maxLines: 1,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(10),
                    ],
                ),
                SizedBox(height: screenHeight * 0.02),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Color(0xFFE0E0E0)),
                    filled: true,
                    fillColor: Color(0xFF0B0B45),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFFFFD700)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFFFFD700)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFFFFD700), width: 2),
                    ),
                  ),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 20 : 18,
                  ),
                  obscureText: true,
                ),
                SizedBox(height: screenHeight * 0.02),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: TextStyle(color: Color(0xFFE0E0E0)),
                    filled: true,
                    fillColor: Color(0xFF0B0B45),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFFFFD700)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFFFFD700)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFFFFD700), width: 2),
                    ),
                  ),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 20 : 18,
                  ),
                  obscureText: true,
                ),
                SizedBox(height: screenHeight * 0.03),
                _isLoading
                    ? SpinKitCubeGrid(
                            color: Color(0xFFFFD700),
                            size: 50.0,
                          )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF000000), // Black button
                          foregroundColor: Color(0xFFFFD700), // Gold text
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.1,
                            vertical: screenHeight * 0.02,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _signUp,
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: isTablet ? 20 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ).animate().fadeIn(duration: 500.ms),
                SizedBox(height: screenHeight * 0.02),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Already have an account? Log In',
                    style: TextStyle(
                      color: Color(0xFFE0E0E0),
                      fontSize: isTablet ? 18 : 16,
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}