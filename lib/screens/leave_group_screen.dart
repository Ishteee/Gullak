import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class LeaveGroupScreen extends StatefulWidget {
  const LeaveGroupScreen({Key? key}) : super(key: key);

  @override
  _LeaveGroupScreenState createState() => _LeaveGroupScreenState();
}

class _LeaveGroupScreenState extends State<LeaveGroupScreen> {
  bool _isLoading = false;

  Future<void> _handleLeaveGroup(int groupId) async {
    setState(() => _isLoading = true);
    try {
      // Count members in the group
      final memberCount = await Supabase.instance.client
          .from('members')
          .count(CountOption.exact)
          .eq('group_id', groupId);
      debugPrint('Member count: $memberCount');

      final currentUserId = Supabase.instance.client.auth.currentUser!.id;

      if (memberCount == 1) {
        // Only member: delete group and member
        await Supabase.instance.client
            .from('groups')
            .delete()
            .eq('id', groupId);
        await Supabase.instance.client
            .from('members')
            .delete()
            .eq('group_id', groupId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group deleted successfully!'),
            backgroundColor: Color(0xFF0B0B45),
          ),
        );
      } else {
        // Multiple members: remove only this user
        await Supabase.instance.client
            .from('members')
            .delete()
            .eq('group_id', groupId)
            .eq('user_id', currentUserId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Left group successfully!'),
            backgroundColor: Color(0xFF0B0B45),
          ),
        );
      }
      // Navigator.of(context).pop();
      // Navigator.of(context).pop();
      Navigator.pop(context, 'refresh');
    } catch (e) {
      debugPrint('Leave group error: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to leave group: $e'),
          backgroundColor: const Color(0xFF0B0B45),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final groupId = args['groupId'] as int;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B45),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B45),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: const Color(0xFFFFD700),
            size: math.min(screenWidth * 0.07, 28),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Leave Group',
          style: TextStyle(
            color: const Color(0xFFFFD700),
            fontSize: math.min(screenWidth * 0.065, 26),
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: const Color(0xFFFFD700),
                blurRadius: screenWidth * 0.03,
              ),
            ],
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0B0B45), Color(0xFF1A237E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
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
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.03),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.all(screenWidth * 0.06),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B0B45), Color(0xFF1A237E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(screenWidth * 0.05),
                  border: Border.all(color: const Color(0xFFFFD700), width: screenWidth * 0.005),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.5),
                      blurRadius: screenWidth * 0.0375,
                      spreadRadius: screenWidth * 0.01,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Are you sure you want to leave this group?',
                        style: TextStyle(
                          color: const Color(0xFFE0E0E0),
                          fontSize: math.min(screenWidth * 0.045, 20),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(duration: 500.ms),
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
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ).animate().fadeIn(duration: 400.ms),
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF0B0B45),
                            foregroundColor: const Color(0xFFFFD700),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.02)),
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: screenHeight * 0.015),
                          ),
                          onPressed: _isLoading ? null : () => _handleLeaveGroup(groupId),
                          child: Text(
                            'Confirm',
                            style: TextStyle(
                              fontSize: math.min(screenWidth * 0.045, 18),
                              fontWeight: FontWeight.w600,
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
              ).animate().fadeIn(duration: 500.ms).slideY(
                    begin: 0.2,
                    end: 0,
                    duration: 500.ms,
                    curve: Curves.easeOut,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}