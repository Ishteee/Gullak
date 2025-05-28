import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:crypto/crypto.dart';

class CreateGroupScreen extends StatefulWidget {
  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _savingsGoalController = TextEditingController();
  bool _isLoading = false;

  // Generate a 6-digit alphanumeric joining code
  Future<String?> _generateJoiningCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    const length = 6;
    const maxAttempts = 3;
    final random = Random.secure();

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final code = String.fromCharCodes(
        List.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
      );
      final exists = await Supabase.instance.client
          .from('groups')
          .select('id')
          .eq('joining_code', code)
          .maybeSingle();
      if (exists == null) {
        return code;
      }
      print('Joining code collision on attempt ${attempt + 1}: $code');
    }
    print('Failed to generate unique joining code after $maxAttempts attempts');
    return null;
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();
    final savingsGoal = double.tryParse(_savingsGoalController.text.trim());
    if (groupName.isEmpty || savingsGoal == null || savingsGoal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please provide a valid group name and savings goal',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF0B0B45),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final userName = await Supabase.instance.client
          .from('profiles')
          .select('name')
          .eq('user_id', userId)
          .single()
          .then((res) => res['name'] as String);
      final newCode = await _generateJoiningCode();
      if (newCode == null) {
        throw Exception('Failed to generate unique joining code after 3 attempts');
      }
      final groupResponse = await Supabase.instance.client
          .from('groups')
          .insert({
            'name': groupName,
            'savings_goal': savingsGoal,
            'joining_code': newCode,
          })
          .select()
          .single();
      final groupId = groupResponse['id'] as int;
      await Supabase.instance.client.from('members').insert({
        'group_id': groupId,
        'user_id': userId,
        'name': userName,
        'total_savings': 0.0,
      });
      setState(() => _isLoading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Group created successfully!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF0B0B45),
        ),
      );
      Navigator.pop(context, 'refresh');
    } catch (e) {
      print('Group creation error: $e');
      setState(() => _isLoading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating group: $e', style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFF0B0B45),
        ),
      );
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _savingsGoalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [Color(0xFF0B0B45), Color(0xFF1A237E)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Color(0xFFFFD700),
                  size: screenWidth * 0.06,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Create Group',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: math.min(screenWidth * 0.06, 28),
                  fontWeight: FontWeight.w900,
                ),
              ).animate().fadeIn(duration: 600.ms),
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0B0B45), Color(0xFF1A237E).withOpacity(0.9)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              expandedHeight: screenHeight * 0.18,
              floating: true,
              pinned: true,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.02),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start a New Savings Group',
                      style: TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontSize: math.min(screenWidth * 0.045, 20),
                        fontWeight: FontWeight.w600,
                      ),
                    ).animate().fadeIn(duration: 800.ms),
                    SizedBox(height: screenHeight * 0.02),
                    TextField(
                      controller: _groupNameController,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(15),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Group Name',
                        labelStyle: TextStyle(
                          color: Color(0xFFE0E0E0),
                          fontSize: math.min(screenWidth * 0.04, 16),
                        ),
                        filled: true,
                        fillColor: Color(0xFF0B0B45),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(
                          Icons.group,
                          color: Color(0xFFFFD700),
                          size: screenWidth * 0.06,
                        ),
                      ),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: math.min(screenWidth * 0.04, 16),
                      ),
                    ).animate().slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 800.ms,
                          curve: Curves.easeOut,
                        ),
                    SizedBox(height: screenHeight * 0.015),
                    TextField(
                      controller: _savingsGoalController,
                      decoration: InputDecoration(
                        labelText: 'Savings Goal (₹)',
                        labelStyle: TextStyle(
                          color: Color(0xFFE0E0E0),
                          fontSize: math.min(screenWidth * 0.04, 16),
                        ),
                        filled: true,
                        fillColor: Color(0xFF0B0B45),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(
                          Icons.savings,
                          color: Color(0xFFFFD700),
                          size: screenWidth * 0.06,
                        ),
                      ),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: math.min(screenWidth * 0.04, 16),
                      ),
                      keyboardType: TextInputType.number,
                    ).animate().slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 900.ms,
                          curve: Curves.easeOut,
                        ),
                    SizedBox(height: screenHeight * 0.03),
                    GestureDetector(
                      onTap: _isLoading ? null : _createGroup,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF0B0B45), Color(0xFF1A237E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(screenWidth * 0.04),
                          border: Border.all(color: Color(0xFFFFD700), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFFFD700).withOpacity(0.3),
                              blurRadius: screenWidth * 0.025,
                              spreadRadius: screenWidth * 0.005,
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isLoading
                              ? SpinKitCubeGrid(
                                  color: Color(0xFFFFD700),
                                  size: screenWidth * 0.125,
                                )
                              : Text(
                                  'Create Group',
                                  style: TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontSize: math.min(screenWidth * 0.045, 20),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ).animate().scale(
                          duration: 400.ms,
                          begin: Offset(1.0, 1.0),
                          end: Offset(0.95, 0.95),
                          curve: Curves.easeInOut,
                        ).fadeIn(duration: 1000.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      )
    );
  }
}