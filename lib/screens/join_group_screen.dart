import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({Key? key}) : super(key: key);

  @override
  _JoinGroupScreenState createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final TextEditingController _joinCodeController = TextEditingController();
  bool _hasJoinError = false;
  bool _isLoading = false;

  Future<void> _handleJoinGroup() async {
    final code = _joinCodeController.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _hasJoinError = true);
      return;
    }

    setState(() {
      _isLoading = true;
      _hasJoinError = false;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final userName = await Supabase.instance.client
          .from('profiles')
          .select('name')
          .eq('user_id', userId)
          .single()
          .then((res) => res['name'] as String);
      final groupResponse = await Supabase.instance.client
          .from('groups')
          .select()
          .eq('joining_code', code)
          .maybeSingle();
      if (groupResponse == null) {
        setState(() {
          _hasJoinError = true;
          _isLoading = false;
        });
        return;
      }
      final groupId = groupResponse['id'];
      final isMember = await Supabase.instance.client
          .from('members')
          .select()
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();
      if (isMember != null) {
        setState(() {
          _hasJoinError = true;
          _isLoading = false;
        });
        return;
      }
      await Supabase.instance.client.from('members').insert({
        'group_id': groupId,
        'user_id': userId,
        'name': userName,
        'total_savings': 0.0,
      });
      _joinCodeController.clear();
      setState(() => _isLoading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully joined group!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF0B0B45),
        ),
      );
      Navigator.pop(context, 'refresh');
    } catch (e) {
      print('Join group error: $e');
      setState(() {
        _hasJoinError = true;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B45),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B45),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: const Color(0xFFFFD700),
            size: math.min(screenWidth * 0.06, 24),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Join Group',
          style: TextStyle(
            color: const Color(0xFFFFD700),
            fontSize: math.min(screenWidth * 0.06, 24),
            fontWeight: FontWeight.w900,
          ),
        ).animate().fadeIn(duration: 600.ms),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0B0B45), Color(0xFF1A237E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Stack(
        children: [
          if (_isLoading)
            Center(
              child: SpinKitCubeGrid(
                color: const Color(0xFFFFD700),
                size: screenWidth * 0.125,
              ),
            ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.03,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: screenWidth * 0.8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.all(screenWidth * 0.06),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0B0B45), Color(0xFF1A237E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(screenWidth * 0.04),
                      border: Border.all(
                        color: const Color(0xFFFFD700),
                        width: screenWidth * 0.005,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.5),
                          blurRadius: screenWidth * 0.03,
                          spreadRadius: screenWidth * 0.01,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Enter Joining Code',
                          style: TextStyle(
                            color: const Color(0xFFE0E0E0),
                            fontSize: math.min(screenWidth * 0.045, 18),
                            fontWeight: FontWeight.w600,
                          ),
                        ).animate().fadeIn(duration: 600.ms),
                        SizedBox(height: screenHeight * 0.02),
                        TextField(
                          controller: _joinCodeController,
                          decoration: InputDecoration(
                            labelText: 'Joining Code',
                            labelStyle: TextStyle(
                              color: const Color(0xFFE0E0E0),
                              fontSize: math.min(screenWidth * 0.04, 16),
                            ),
                            filled: true,
                            fillColor: Color(0xFF0B0B45),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(screenWidth * 0.02),
                              borderSide: BorderSide.none,
                            ),
                            errorText: _hasJoinError ? 'Invalid or already joined' : null,
                            errorStyle: TextStyle(
                              color: const Color(0xFFFFD700),
                              fontSize: math.min(screenWidth * 0.035, 14),
                            ),
                          ),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: math.min(screenWidth * 0.04, 16),
                          ),
                          textCapitalization: TextCapitalization.characters,
                          onChanged: (_) => setState(() => _hasJoinError = false),
                        ).animate().slideY(
                              begin: 0.2,
                              end: 0,
                              duration: 800.ms,
                              curve: Curves.easeOut,
                            ),
                        SizedBox(height: screenHeight * 0.03),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton(
                              onPressed: _isLoading ? null : () => Navigator.pop(context),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: const Color(0xFFE0E0E0),
                                  fontSize: math.min(screenWidth * 0.045, 18),
                                ),
                              ),
                            ).animate().fadeIn(duration: 400.ms),
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFF0B0B45),
                                foregroundColor: const Color(0xFFFFD700),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.06,
                                  vertical: screenHeight * 0.015,
                                ),
                              ),
                              onPressed: _isLoading ? null : _handleJoinGroup,
                              child: Text(
                                'Join',
                                style: TextStyle(
                                  fontSize: math.min(screenWidth * 0.045, 18),
                                ),
                              ),
                            ).animate().scale(
                                  duration: 400.ms,
                                  begin: const Offset(1.0, 1.0),
                                  end: const Offset(0.95, 0.95),
                                  curve: Curves.easeInOut,
                                ),
                          ],
                        ),
                      ],
                    ),
                  ).animate(effects: [
                    FadeEffect(duration: 500.ms),
                    SlideEffect(
                      begin: Offset(0, 0.2),
                      end: Offset.zero,
                      duration: 500.ms,
                      curve: Curves.easeOut,
                    ),
                    if (_hasJoinError)
                      ShakeEffect(
                        duration: 400.ms,
                        hz: 4,
                        offset: Offset(screenWidth * 0.015, 0),
                      ),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}