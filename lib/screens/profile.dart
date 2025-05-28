import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'auth_screen.dart';
import 'dart:math' as math;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _name;
  String? _email;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }
      final response = await Supabase.instance.client
          .from('profiles')
          .select('name')
          .eq('user_id', user.id)
          .single();
      setState(() {
        _name = response['name'];
        _email = user.email;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error fetching profile: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF000000),
        ),
      );
    }
  }

  Future<void> _logOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error logging out: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF000000),
        ),
      );
    }
  }






  void _showEditNameDialog(VoidCallback refreshCallback) {
    final TextEditingController controller = TextEditingController();
    bool hasError = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;

            return AlertDialog(
              backgroundColor: Color(0xFF1A237E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
              ),
              title: Text(
                'Edit Name',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: math.min(screenWidth * 0.05, 20),
                  fontWeight: FontWeight.w700,
                ),
              ).animate().fadeIn(duration: 500.ms),
              content: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: screenWidth * 0.8),
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'New Name',
                      labelStyle: TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontSize: math.min(screenWidth * 0.04, 16),
                      ),
                      filled: true,
                      fillColor: Color(0xFF0B0B45),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        borderSide: BorderSide.none,
                      ),
                      errorText: hasError ? 'Name cannot be empty' : null,
                      errorStyle: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: math.min(screenWidth * 0.035, 14),
                      ),
                      prefixIcon: Icon(
                        Icons.person,
                        color: Color(0xFFFFD700),
                        size: screenWidth * 0.05,
                      ),
                    ),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: math.min(screenWidth * 0.045, 18),
                    ),
                    maxLines: 1,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(10),
                    ],
                    onChanged: (_) => setState(() => hasError = false),
                  ).animate().slideY(
                        begin: 0.2,
                        end: 0,
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFFE0E0E0),
                      fontSize: math.min(screenWidth * 0.04, 16),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Color(0xFF0B0B45),
                    foregroundColor: Color(0xFFFFD700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: screenHeight * 0.015,
                    ),
                  ),
                  onPressed: () async {
                    final newName = controller.text.trim();
                    if (newName.isEmpty) {
                      setState(() => hasError = true);
                      return;
                    }
                    try {
                      final userId = Supabase.instance.client.auth.currentUser!.id;

                      // Update the name in profiles table
                      await Supabase.instance.client
                          .from('profiles')
                          .update({'name': newName})
                          .eq('user_id', userId);

                      // Update the name in members table
                      await Supabase.instance.client
                          .from('members')
                          .update({'name': newName})
                          .eq('user_id', userId);

                      setState(() {
                        _name = newName;
                      });

                      if (!mounted) return;
                      Navigator.pop(context);
                      refreshCallback();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Name updated successfully!',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Color(0xFF000000),
                        ),
                      );
                    } catch (e) {
                      print('Update name error: $e');
                      setState(() => hasError = true);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error updating name: $e',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Color(0xFF000000),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Save',
                    style: TextStyle(
                      fontSize: math.min(screenWidth * 0.04, 16),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms).scale(
                      duration: 400.ms,
                      begin: Offset(1.0, 1.0),
                      end: Offset(0.95, 0.95),
                      curve: Curves.easeInOut,
                    ),
              ],
            ).animate().fadeIn(duration: 500.ms).slideY(
                  begin: 0.2,
                  end: 0,
                  duration: 500.ms,
                  curve: Curves.easeOut,
                );
          },
        );
      },
    );
  }












  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B45),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0B0B45), Color(0xFF1A237E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFFFFD700),
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ).animate().fadeIn(duration: 500.ms).scale(
              duration: 500.ms,
              curve: Curves.easeOut,
            ),
      ),
      body: Stack(
        children: [
          // Starry background with twinkling particles
          ClipRect(
            child: Stack(
              children: List.generate(15, (index) {
                return Positioned(
                  left: math.Random().nextDouble() * screenWidth,
                  top: math.Random().nextDouble() * screenHeight,
                  child: AnimatedOpacity(
                    opacity: math.Random().nextDouble() * 0.4 + 0.2,
                    duration: Duration(milliseconds: 2000 + index * 200),
                    child: Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD700),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          // Subtle radial gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Color(0xFF0B0B45),
                  Color(0xFF00002A),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.08,
                  vertical: screenHeight * 0.05,
                ),
                child: _isLoading
                    ? const SpinKitCubeGrid(
                        color: Color(0xFFFFD700),
                        size: 50.0,
                      ).animate().fadeIn(duration: 500.ms)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Avatar
                          Container(
                            width: isTablet ? 120 : 100,
                            height: isTablet ? 120 : 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFE082)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withOpacity(0.5),
                                  blurRadius: 12,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _name != null ? _name![0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: const Color(0xFF0B0B45),
                                  fontSize: isTablet ? 48 : 40,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                          SizedBox(height: screenHeight * 0.03),
                          // Title
                          Text(
                            'Your Profile',
                            style: TextStyle(
                              color: const Color(0xFFFFD700),
                              fontSize: isTablet ? 36 : 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(
                                  color: const Color(0xFFFFD700).withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ).animate().slideY(begin: 0.2, end: 0, duration: 500.ms).fadeIn(duration: 500.ms),
                          SizedBox(height: screenHeight * 0.04),
                          // Profile Card (Glassmorphism)
                          Container(
                            width: isTablet ? screenWidth * 0.6 : screenWidth * 0.85,
                            padding: EdgeInsets.all(isTablet ? 24 : 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A237E).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                              backgroundBlendMode: BlendMode.overlay,
                            ),
                            child: Column(
                              children: [
                                // Name with Edit Icon
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _name ?? 'Unknown',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isTablet ? 24 : 20,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: Color(0xFFFFD700),
                                        size: 24,
                                      ),
                                      onPressed: _isLoading ? null : () => _showEditNameDialog(() {
                                  setState(() {});
                                }),
                                    ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
                                  ],
                                ),
                                SizedBox(height: screenHeight * 0.015),
                                // Email
                                Text(
                                  _email ?? 'Unknown',
                                  style: TextStyle(
                                    color: const Color(0xFFE0E0E0),
                                    fontSize: isTablet ? 20 : 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ).animate().fadeIn(duration: 600.ms, delay: 300.ms),
                              ],
                            ),
                          ).animate().scale(duration: 700.ms, curve: Curves.easeOut).fadeIn(duration: 700.ms),
                          SizedBox(height: screenHeight * 0.04),
                          // Log Out Button
                          GestureDetector(
                            onTapDown: (_) {
                              setState(() {}); // Trigger rebuild for scale animation
                            },
                            onTapUp: (_) {
                              setState(() {}); // Reset scale
                              _logOut();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              transform: Matrix4.identity()..scale(1.0),
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? screenWidth * 0.12 : screenWidth * 0.15,
                                vertical: isTablet ? 16 : 12,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF000000), Color(0xFF1A237E)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFFD700)),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD700).withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Text(
                                'Log Out',
                                style: TextStyle(
                                  color: const Color(0xFFFFD700),
                                  fontSize: isTablet ? 20 : 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ).animate().fadeIn(duration: 600.ms, delay: 400.ms).then().shake(duration: 1000.ms, delay: 1000.ms),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}