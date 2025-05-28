import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:vibration/vibration.dart';
import 'dart:math' as math;

class GroupDetailsScreen extends StatefulWidget {
  const GroupDetailsScreen({Key? key}) : super(key: key);

  @override
  _GroupDetailsScreenState createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  bool _isFull = false;
  String? _groupName;
  String? _joiningCode;
  bool isLoading = false;

  Future<Map<String, dynamic>> _fetchGroupDetails(int groupId) async {
    final groupResponse = await Supabase.instance.client
        .from('groups')
        .select()
        .eq('id', groupId)
        .single();
    debugPrint('Group: $groupResponse');

    final membersResponse = await Supabase.instance.client
        .from('members')
        .select('id, name, total_savings, user_id')
        .eq('group_id', groupId);
    debugPrint('Members: ${membersResponse.length}, Data: $membersResponse');

    final totalSavings = membersResponse.fold<double>(
        0.0, (sum, m) => sum + (m['total_savings'] as num).toDouble());

    final sortedMembers = membersResponse.toList()
      ..sort((a, b) => (b['total_savings'] as num).compareTo(a['total_savings'] as num));

    return {
      'group': groupResponse,
      'members': sortedMembers,
      'total_savings': totalSavings,
    };
  }

  void _showAddSavingsDialog(BuildContext context, List<Map<String, dynamic>> members, int groupId, VoidCallback refreshCallback) {
    showDialog(
      context: context,
      builder: (context) {
        return DefaultTabController(
          length: 2,
          child: Dialog(
            backgroundColor: const Color(0xFF1A237E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
                maxWidth: MediaQuery.of(context).size.width * 0.85,
              ),
              child: _AddSavingsDialogContent(
                members: members,
                groupId: groupId,
                refreshCallback: refreshCallback,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditGroupDialog(int groupId, String currentName, double? currentSavingsGoal, VoidCallback refreshCallback) {
    final nameController = TextEditingController(text: currentName);
    final savingsGoalController = TextEditingController(
      text: currentSavingsGoal != null ? currentSavingsGoal.toString() : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A237E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Edit Group Details',
                style: TextStyle(
                  color: const Color(0xFFFFD700),
                  fontWeight: FontWeight.w700,
                  fontSize: screenWidth * 0.045,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Group Name',
                        labelStyle: TextStyle(color: Color(0xFFE0E0E0), fontSize: screenWidth * 0.04),
                        filled: true,
                        fillColor: const Color(0xFF0B0B45),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04),
                    ),
                    SizedBox(height: screenWidth * 0.03),
                    TextField(
                      controller: savingsGoalController,
                      decoration: InputDecoration(
                        labelText: 'Savings Goal (₹)',
                        labelStyle: TextStyle(color: Color(0xFFE0E0E0), fontSize: screenWidth * 0.04),
                        filled: true,
                        fillColor: const Color(0xFF0B0B45),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFFE0E0E0), fontSize: screenWidth * 0.04),
                  ),
                ).animate().fadeIn(duration: 400.ms),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF0B0B45),
                    foregroundColor: const Color(0xFFFFD700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final newName = nameController.text.trim();
                    final newSavingsGoal = double.tryParse(savingsGoalController.text.trim());

                    if (newName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Group name cannot be empty.'),
                          backgroundColor: Color(0xFF0B0B45),
                        ),
                      );
                      return;
                    }

                    if (newSavingsGoal != null && newSavingsGoal < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Savings goal must be a positive number.'),
                          backgroundColor: Color(0xFF0B0B45),
                        ),
                      );
                      return;
                    }

                    try {
                      await Supabase.instance.client
                          .from('groups')
                          .update({
                            'name': newName,
                            'savings_goal': newSavingsGoal,
                          })
                          .eq('id', groupId);

                      setState(() {
                        _groupName = newName;
                      });

                      Navigator.pop(context);
                      refreshCallback();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Group details updated successfully!'),
                          backgroundColor: Color(0xFF0B0B45),
                        ),
                      );
                    } catch (e) {
                      debugPrint('Error updating group: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update group: $e'),
                          backgroundColor: const Color(0xFF0B0B45),
                        ),
                      );
                    }
                  },
                  child: Text('Confirm', style: TextStyle(fontSize: screenWidth * 0.04)),
                ).animate().scale(
                      duration: 400.ms,
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(0.95, 0.95),
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
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 600;
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final groupId = args['groupId'] as int;
    _groupName ??= args['groupName'] as String;
    _joiningCode ??= args['joining_code'] as String;

    debugPrint('Screen: W=$screenWidth, H=$screenHeight');

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0B45),
        body: Stack(
          children: [
            ...List.generate(12, (index) {
              return Positioned(
                left: math.Random().nextDouble() * screenWidth,
                top: math.Random().nextDouble() * screenHeight,
                child: AnimatedOpacity(
                  opacity: math.Random().nextDouble() * 0.5 + 0.3,
                  duration: Duration(milliseconds: 2000 + index * 300),
                  child: Container(
                    width: screenWidth * 0.01,
                    height: screenWidth * 0.01,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD700),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
            RefreshIndicator(
              key: _refreshIndicatorKey,
              color: const Color(0xFFFFD700),
              backgroundColor: const Color(0xFF0B0B45),
              onRefresh: () async {
                setState(() {});
              },
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: const Color(0xFF0B0B45),
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      title: Text(
                        _groupName!,
                        style: TextStyle(
                          color: const Color(0xFFFFD700),
                          fontSize: screenWidth * 0.065,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: const Color(0xFFFFD700).withOpacity(0.6),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 600.ms),
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF0B0B45), Color(0xFF1A237E)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    expandedHeight: (screenHeight * 0.22).clamp(110, 160),
                    floating: true,
                    pinned: true,
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back, color: Color(0xFFFFD700), size: screenWidth * 0.065),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      Padding(
                        padding: EdgeInsets.only(top: screenWidth * 0.01),
                        child: IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: const Color(0xFF0B0B45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
                                ),
                                title: Text(
                                  'Group Joining Code',
                                  style: GoogleFonts.orbitron(
                                    color: const Color(0xFFFFD700),
                                    fontSize: screenWidth * 0.06,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: screenWidth * 0.04,
                                        vertical: screenHeight * 0.015,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF1A237E), Color(0xFF0B0B45)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Color(0xFFFFD700)), // fixed here
                                      ),
                                      child: Text(
                                        _joiningCode!,
                                        style: GoogleFonts.orbitron(
                                          color: Colors.white,
                                          fontSize: screenWidth * 0.05,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.02),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: _joiningCode!));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Code copied to clipboard'),
                                            backgroundColor: Color(0xFF000000),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.copy, color: Color(0xFFFFD700)),
                                      label: Text(
                                        'Copy Code',
                                        style: GoogleFonts.orbitron(
                                          color: const Color(0xFFFFD700),
                                          fontSize: screenWidth * 0.04,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF000000),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.04,
                                          vertical: screenHeight * 0.01,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      'Close',
                                      style: GoogleFonts.orbitron(
                                        color: const Color(0xFFE0E0E0),
                                        fontSize: screenWidth * 0.04,
                                      ),
                                    ),
                                  ).animate().fadeIn(duration: 300.ms)
                                ],
                              ),
                            );
                          },
                          icon: Icon(Icons.info, color: Color(0xFFFFD700), size: screenWidth * 0.065),
                        ),
                      ),
                      IconButton(
                        icon: FaIcon(FontAwesomeIcons.penToSquare, color: Color(0xFFFFD700), size: screenWidth * 0.065),
                        onPressed: () async {
                          final data = await _fetchGroupDetails(groupId);
                          _showAddSavingsDialog(context, data['members'], groupId, () {
                            setState(() {});
                          });
                        },
                      ),
                    ],
                  ),
                  FutureBuilder<Map<String, dynamic>>(
                    future: _fetchGroupDetails(groupId),
                    builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SliverToBoxAdapter(
                          child: Center(
                            child: SpinKitCubeGrid(
                              color: Color(0xFFFFD700),
                              size: screenWidth * 0.1,
                            ),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        debugPrint('Fetch error: ${snapshot.error}');
                        return SliverToBoxAdapter(
                          child: Center(
                            child: Text(
                              'Error loading group details.',
                              style: TextStyle(
                                color: const Color(0xFFE0E0E0),
                                fontSize: screenWidth * 0.04,
                              ),
                            ),
                          ),
                        );
                      }
                      final data = snapshot.data!;
                      final group = data['group'] as Map<String, dynamic>;
                      final members = data['members'] as List<Map<String, dynamic>>;
                      final totalSavings = data['total_savings'] as double;
                      final savingsGoal = (group['savings_goal'] as num?)?.toDouble() ?? 10000.0;

                      final maxHeight = screenHeight * 0.32;
                      final minHeight = screenHeight * 0.09;
                      double firstHeight = minHeight;
                      double secondHeight = minHeight;
                      double thirdHeight = minHeight;

                      if (members.isNotEmpty) {
                        final maxSavings = members[0]['total_savings'] as num;
                        if (members.length == 1) {
                          firstHeight = maxSavings > 0
                              ? minHeight + (maxHeight - minHeight) * (maxSavings / savingsGoal).clamp(0.0, 1.0)
                              : minHeight;
                        } else {
                          firstHeight = maxSavings > 0 ? maxHeight : minHeight;
                          if (members.length >= 2) {
                            final secondSavings = members[1]['total_savings'] as num;
                            secondHeight = maxSavings > 0
                                ? minHeight + (maxHeight - minHeight) * (secondSavings / maxSavings).clamp(0.0, 1.0)
                                : minHeight;
                          }
                          if (members.length >= 3) {
                            final thirdSavings = members[2]['total_savings'] as num;
                            thirdHeight = maxSavings > 0
                                ? minHeight + (maxHeight - minHeight) * (thirdSavings / maxSavings).clamp(0.0, 1.0)
                                : minHeight;
                          }
                        }
                      }

                      debugPrint('Podium: 1st=$firstHeight, 2nd=$secondHeight, 3rd=$thirdHeight');

                      final progressPercent = savingsGoal > 0 ? (totalSavings / savingsGoal * 100).clamp(0, 100).toDouble() : 0.0;

                      if (progressPercent >= 100 && !_isFull) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Confetti.launch(
                            context,
                            options: ConfettiOptions(
                              particleCount: 150,
                              colors: const [Color(0xFFFFD700), Color(0xFF4CAF50), Colors.white],
                              gravity: 0.6,
                            ),
                          );
                          Vibration.vibrate(duration: 500);
                          setState(() => _isFull = true);
                        });
                      }

                      return SliverList(
                        delegate: SliverChildListDelegate([
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015),
                            child: Center(
                              child: Text(
                                'Leaderboard',
                                style: TextStyle(
                                  color: const Color(0xFFFFD700),
                                  fontSize: screenWidth * 0.05,
                                  fontWeight: FontWeight.w800,
                                  shadows: [
                                    Shadow(
                                      color: const Color(0xFFFFD700).withOpacity(0.6),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate().fadeIn(duration: 800.ms),
                          Container(
                            height: screenHeight * 0.36,
                            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                if (members.isEmpty)
                                  Center(
                                    child: Text(
                                      'No members in this group.',
                                      style: TextStyle(
                                        color: const Color(0xFFE0E0E0),
                                        fontSize: screenWidth * 0.04,
                                      ),
                                    ),
                                  ),
                                if (members.length >= 2)
                                  Positioned(
                                    left: screenWidth * 0.08,
                                    child: Animate(
                                      effects: [
                                        FadeEffect(duration: 500.ms, delay: 200.ms),
                                        SlideEffect(
                                          begin: const Offset(0, 0.3),
                                          end: Offset.zero,
                                          duration: 500.ms,
                                          delay: 200.ms,
                                          curve: Curves.easeOut,
                                        ),
                                      ],
                                      child: ClipRect(
                                        child: Container(
                                          width: screenWidth * 0.25,
                                          height: secondHeight,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFC0C0C0), Color(0xFFA9A9A9)],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '2nd',
                                                style: TextStyle(
                                                  color: const Color(0xFF0B0B45),
                                                  fontSize: screenWidth * 0.028 + (screenWidth * 0.038 - screenWidth * 0.028) * ((secondHeight - minHeight) / (maxHeight - minHeight)).clamp(0.0, 1.0),
                                                  fontWeight: FontWeight.bold,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.white.withOpacity(0.3),
                                                      blurRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  members[1]['name'],
                                                  style: TextStyle(
                                                    color: const Color(0xFF0B0B45),
                                                    fontSize: screenWidth * 0.024 + (screenWidth * 0.032 - screenWidth * 0.024) * ((secondHeight - minHeight) / (maxHeight - minHeight)).clamp(0.0, 1.0),
                                                    fontWeight: FontWeight.w600,
                                                    shadows: [
                                                      Shadow(
                                                        color: Colors.white.withOpacity(0.3),
                                                        blurRadius: 2,
                                                      ),
                                                    ],
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Text(
                                                '₹${(members[1]['total_savings'] as num).toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  color: const Color(0xFF0B0B45),
                                                  fontSize: screenWidth * 0.02 + (screenWidth * 0.028 - screenWidth * 0.02) * ((secondHeight - minHeight) / (maxHeight - minHeight)).clamp(0.0, 1.0),
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.white.withOpacity(0.3),
                                                      blurRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (members.length >= 1)
                                  Positioned(
                                    left: screenWidth * 0.375,
                                    child: Animate(
                                      effects: [
                                        FadeEffect(duration: 500.ms),
                                        SlideEffect(
                                          begin: const Offset(0, 0.3),
                                          end: Offset.zero,
                                          duration: 500.ms,
                                          curve: Curves.easeOut,
                                        ),
                                      ],
                                      child: ClipRect(
                                        child: Container(
                                          width: screenWidth * 0.25,
                                          height: firstHeight,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFFFD700), Color(0xFFDAA520)],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '1st',
                                                style: TextStyle(
                                                  color: const Color(0xFF0B0B45),
                                                  fontSize: screenWidth * 0.032 + (screenWidth * 0.042 - screenWidth * 0.032) * ((firstHeight - minHeight) / (maxHeight - minHeight)).clamp(0.0, 1.0),
                                                  fontWeight: FontWeight.bold,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.white.withOpacity(0.3),
                                                      blurRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  members[0]['name'],
                                                  style: TextStyle(
                                                    color: const Color(0xFF0B0B45),
                                                    fontSize: screenWidth * 0.028 + (screenWidth * 0.036 - screenWidth * 0.028) * ((firstHeight - minHeight) / (maxHeight - minHeight)).clamp(0.0, 1.0),
                                                    fontWeight: FontWeight.w600,
                                                    shadows: [
                                                      Shadow(
                                                        color: Colors.white.withOpacity(0.3),
                                                        blurRadius: 2,
                                                      ),
                                                    ],
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Text(
                                                '₹${(members[0]['total_savings'] as num).toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  color: const Color(0xFF0B0B45),
                                                  fontSize: screenWidth * 0.024 + (screenWidth * 0.032 - screenWidth * 0.024) * ((firstHeight - minHeight) / (maxHeight - minHeight)).clamp(0.0, 1.0),
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.white.withOpacity(0.3),
                                                      blurRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (members.length >= 3)
                                  Positioned(
                                    left: screenWidth * 0.67,
                                    child: Animate(
                                      effects: [
                                        FadeEffect(duration: 500.ms, delay: 400.ms),
                                        SlideEffect(
                                          begin: const Offset(0, 0.3),
                                          end: Offset.zero,
                                          duration: 500.ms,
                                          delay: 400.ms,
                                          curve: Curves.easeOut,
                                        ),
                                      ],
                                      child: ClipRect(
                                        child: Container(
                                          width: screenWidth * 0.25,
                                          height: thirdHeight,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFCD7F32), Color(0xFFB87333)],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '3rd',
                                                style: TextStyle(
                                                  color: const Color(0xFF0B0B45),
                                                  fontSize: screenWidth * 0.024 + (screenWidth * 0.032 - screenWidth * 0.024) * ((thirdHeight - minHeight) / (maxHeight - minHeight)).clamp(0.0, 1.0),
                                                  fontWeight: FontWeight.bold,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.white.withOpacity(0.3),
                                                      blurRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  members[2]['name'],
                                                  style: TextStyle(
                                                    color: const Color(0xFF0B0B45),
                                                    fontSize: screenWidth * 0.02 + (screenWidth * 0.028 - screenWidth * 0.02) * ((thirdHeight - minHeight) / (maxHeight - minHeight)).clamp(0.0, 1.0),
                                                    fontWeight: FontWeight.w600,
                                                    shadows: [
                                                      Shadow(
                                                        color: Colors.white.withOpacity(0.3),
                                                        blurRadius: 2,
                                                      ),
                                                    ],
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Text(
                                                '₹${(members[2]['total_savings'] as num).toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  color: const Color(0xFF0B0B45),
                                                  fontSize: screenWidth * 0.018 + (screenWidth * 0.024 - screenWidth * 0.018) * ((thirdHeight - minHeight) / (maxHeight - minHeight)).clamp(0.0, 1.0),
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.white.withOpacity(0.3),
                                                      blurRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 600.ms),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: EdgeInsets.all(screenWidth * 0.04),
                              constraints: BoxConstraints(maxWidth: 400),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1A237E), Color(0xFF0B0B45)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(screenWidth * 0.04),
                                border: Border.all(color: Color(0xFFFFD700), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD700).withOpacity(0.5),
                                    blurRadius: 15,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Group Stats',
                                    style: TextStyle(
                                      color: const Color(0xFFFFD700),
                                      fontSize: screenWidth * 0.05,
                                      fontWeight: FontWeight.w800,
                                      shadows: [
                                        Shadow(
                                          color: const Color(0xFFFFD700).withOpacity(0.6),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.015),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total Savings:',
                                        style: TextStyle(
                                          color: Color(0xFFE0E0E0),
                                          fontSize: screenWidth * 0.038,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          '₹${totalSavings.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            color: Color(0xFFFFD700),
                                            fontSize: screenWidth * 0.038,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: screenHeight * 0.01),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Savings Goal:',
                                        style: TextStyle(
                                          color: Color(0xFFE0E0E0),
                                          fontSize: screenWidth * 0.038,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          '₹${savingsGoal.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            color: Color(0xFFFFD700),
                                            fontSize: screenWidth * 0.038,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: screenHeight * 0.01),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Progress:',
                                        style: TextStyle(
                                          color: Color(0xFFE0E0E0),
                                          fontSize: screenWidth * 0.038,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${progressPercent.toStringAsFixed(2)}%',
                                        style: TextStyle(
                                          color: Color(0xFFFFD700),
                                          fontSize: screenWidth * 0.038,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: screenHeight * 0.01),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Members:',
                                        style: TextStyle(
                                          color: Color(0xFFE0E0E0),
                                          fontSize: screenWidth * 0.038,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${members.length}',
                                        style: TextStyle(
                                          color: Color(0xFFFFD700),
                                          fontSize: screenWidth * 0.038,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(duration: 800.ms).slideY(
                                begin: 0.3,
                                end: 0,
                                duration: 800.ms,
                                curve: Curves.easeOut,
                              ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/saving_records',
                                  arguments: {'groupId': groupId, 'groupName': _groupName},
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                constraints: BoxConstraints(maxWidth: 400),
                                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02, horizontal: screenWidth * 0.06),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF0B0B45), Color(0xFF1A237E)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                                  border: Border.all(color: Color(0xFFFFD700), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD700).withOpacity(0.5),
                                      blurRadius: 15,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    'Show Saving Records',
                                    style: TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.w700,
                                      shadows: [
                                        Shadow(
                                          color: Color(0xFFFFD700),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ).animate().fadeIn(duration: 800.ms).scale(
                                duration: 800.ms,
                                begin: const Offset(0.95, 0.95),
                                end: const Offset(1.0, 1.0),
                                curve: Curves.easeOut,
                              ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015),
                            child: Text(
                              'Members',
                              style: TextStyle(
                                color: const Color(0xFFFFD700),
                                fontSize: screenWidth * 0.05,
                                fontWeight: FontWeight.w800,
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFFFFD700).withOpacity(0.6),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(duration: 800.ms),
                          ...members.asMap().entries.map((entry) {
                            final index = entry.key;
                            final member = entry.value;
                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.005),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: EdgeInsets.all(screenWidth * 0.03),
                                constraints: BoxConstraints(maxWidth: 400),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF0B0B45), Color(0xFF1A237E)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                  border: Border.all(color: Color(0xFFFFD700), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD700).withOpacity(0.4),
                                      blurRadius: 12,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        member['name'],
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: screenWidth * 0.038,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    Flexible(
                                      child: Text(
                                        '₹${(member['total_savings'] as num).toStringAsFixed(0)}',
                                        style: TextStyle(
                                          color: Color(0xFFFFD700),
                                          fontSize: screenWidth * 0.038,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn(duration: 800.ms, delay: (index * 100).ms).slideY(
                                  begin: 0.3,
                                  end: 0,
                                  duration: 800.ms,
                                  curve: Curves.easeOut,
                                  delay: (index * 100).ms,
                                );
                          }).toList(),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.02),
                            child: GestureDetector(
                              onTap: () {
                                _showEditGroupDialog(groupId, _groupName!, savingsGoal, () {
                                  setState(() {});
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                constraints: BoxConstraints(maxWidth: 400),
                                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02, horizontal: screenWidth * 0.06),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF0B0B45), Color(0xFF1A237E)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                                  border: Border.all(color: Color(0xFFFFD700), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD700).withOpacity(0.5),
                                      blurRadius: 15,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    'Edit Group Details',
                                    style: TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.w700,
                                      shadows: [
                                        Shadow(
                                          color: Color(0xFFFFD700),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ).animate().fadeIn(duration: 800.ms).scale(
                                duration: 800.ms,
                                begin: const Offset(0.95, 0.95),
                                end: const Offset(1.0, 1.0),
                                curve: Curves.easeOut,
                              ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015),
                            child: GestureDetector(
                              onTap: () async {
                                final result = await Navigator.pushNamed(
                                  context,
                                  '/leave_group',
                                  arguments: {'groupId': groupId},
                                );

                                if (result == 'refresh') {
                                  Navigator.pop(context, 'refresh'); // Pass the result up to HomeScreen
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                constraints: BoxConstraints(maxWidth: 400),
                                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02, horizontal: screenWidth * 0.06),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF0B0B45), Color(0xFF1A237E)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                                  border: Border.all(color: Color(0xFFFFD700), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD700).withOpacity(0.5),
                                      blurRadius: 15,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    'Leave Group',
                                    style: TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.w700,
                                      shadows: [
                                        Shadow(
                                          color: Color(0xFFFFD700),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ).animate().fadeIn(duration: 800.ms).scale(
                                duration: 800.ms,
                                begin: const Offset(0.95, 0.95),
                                end: const Offset(1.0, 1.0),
                                curve: Curves.easeOut,
                              ),
                          SizedBox(height: screenHeight * 0.12),
                        ]),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}

class _AddSavingsDialogContent extends StatefulWidget {
  final List<Map<String, dynamic>> members;
  final int groupId;
  final VoidCallback refreshCallback;

  const _AddSavingsDialogContent({
    required this.members,
    required this.groupId,
    required this.refreshCallback,
  });

  @override
  _AddSavingsDialogContentState createState() => _AddSavingsDialogContentState();
}

class _AddSavingsDialogContentState extends State<_AddSavingsDialogContent> {
  String? _selectedMemberId;
  final _savingsController = TextEditingController();
  final _withdrawalController = TextEditingController();
  final _reasonController = TextEditingController();
  final _dateTimeController = TextEditingController();
  DateTime? _selectedDateTime;
  
  bool isLoading = false;

  Future<void> _pickDateTime() async {
    debugPrint("Date picker opened");
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFFD700),
              onPrimary: Color(0xFF0B0B45),
              surface: Color(0xFF1A237E),
              onSurface: Color(0xFFE0E0E0),
            ),
            dialogBackgroundColor: const Color(0xFF0B0B45),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      debugPrint("Picked date: $pickedDate");
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFFFFD700),
                onPrimary: Color(0xFF0B0B45),
                surface: Color(0xFF1A237E),
                onSurface: Color(0xFFE0E0E0),
              ),
              dialogBackgroundColor: const Color(0xFF0B0B45),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final selected = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        debugPrint("Picked full DateTime: $selected");
        setState(() {
          _selectedDateTime = selected;
          _dateTimeController.text = DateFormat('dd/MM/yyyy HH:mm').format(selected);
          debugPrint("Updated _selectedDateTime: $_selectedDateTime");
        });
      } else {
        debugPrint("Time not selected");
      }
    } else {
      debugPrint("Date not selected");
    }
  }

  @override
  void dispose() {
    _savingsController.dispose();
    _withdrawalController.dispose();
    _reasonController.dispose();
    _dateTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(screenWidth * 0.05, screenHeight * 0.02, screenWidth * 0.05, 0),
            child: Text(
              'Manage Savings',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.w700,
                fontSize: screenWidth * 0.045,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TabBar(
                      labelColor: const Color(0xFFFFD700),
                      unselectedLabelColor: const Color(0xFFE0E0E0),
                      labelStyle: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.w700),
                      unselectedLabelStyle: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.w500),
                      indicatorColor: const Color(0xFFFFD700),
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(text: 'Deposit'),
                        Tab(text: 'Withdrawal'),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: screenHeight * 0.25,
                        maxHeight: screenHeight * 0.35,
                      ),
                      child: TabBarView(
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButtonFormField<String>(
                                value: _selectedMemberId,
                                decoration: InputDecoration(
                                  labelText: 'Member',
                                  labelStyle: TextStyle(color: Color(0xFFE0E0E0), fontSize: screenWidth * 0.038),
                                  filled: true,
                                  fillColor: const Color(0xFF0B0B45),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.038),
                                dropdownColor: const Color(0xFF0B0B45),
                                items: widget.members.map((member) {
                                  return DropdownMenuItem<String>(
                                    value: member['id'].toString(),
                                    child: Text(
                                      member['name'],
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedMemberId = value;
                                  });
                                },
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              TextField(
                                controller: _savingsController,
                                decoration: InputDecoration(
                                  labelText: 'Amount (₹)',
                                  labelStyle: TextStyle(color: Color(0xFFE0E0E0), fontSize: screenWidth * 0.038),
                                  filled: true,
                                  fillColor: const Color(0xFF0B0B45),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.038),
                                keyboardType: TextInputType.number,
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              TextField(
                                readOnly: true,
                                controller: _dateTimeController,
                                decoration: InputDecoration(
                                  labelText: 'Date & Time',
                                  labelStyle: TextStyle(color: Color(0xFFE0E0E0), fontSize: screenWidth * 0.038),
                                  filled: true,
                                  fillColor: const Color(0xFF0B0B45),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: Icon(Icons.calendar_today, color: Color(0xFFFFD700), size: screenWidth * 0.05),
                                  hintText: 'Select Date & Time',
                                  hintStyle: TextStyle(color: Color(0xFFE0E0E0).withOpacity(0.7), fontSize: screenWidth * 0.038),
                                ),
                                style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.038),
                                onTap: _pickDateTime,
                              ),
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButtonFormField<String>(
                                value: _selectedMemberId,
                                decoration: InputDecoration(
                                  labelText: 'Member',
                                  labelStyle: TextStyle(color: Color(0xFFE0E0E0), fontSize: screenWidth * 0.038),
                                  filled: true,
                                  fillColor: const Color(0xFF0B0B45),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.038),
                                dropdownColor: const Color(0xFF0B0B45),
                                items: widget.members.map((member) {
                                  return DropdownMenuItem<String>(
                                    value: member['id'].toString(),
                                    child: Text(
                                      member['name'],
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedMemberId = value;
                                  });
                                },
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              TextField(
                                controller: _withdrawalController,
                                decoration: InputDecoration(
                                  labelText: 'Amount (₹)',
                                  labelStyle: TextStyle(color: Color(0xFFE0E0E0), fontSize: screenWidth * 0.038),
                                  filled: true,
                                  fillColor: const Color(0xFF0B0B45),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.038),
                                keyboardType: TextInputType.number,
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              TextField(
                                readOnly: true,
                                controller: _dateTimeController,
                                decoration: InputDecoration(
                                  labelText: 'Date & Time',
                                  labelStyle: TextStyle(color: Color(0xFFE0E0E0), fontSize: screenWidth * 0.038),
                                  filled: true,
                                  fillColor: const Color(0xFF0B0B45),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: Icon(Icons.calendar_today, color: Color(0xFFFFD700), size: screenWidth * 0.05),
                                  hintText: 'Select Date & Time',
                                  hintStyle: TextStyle(color: Color(0xFFE0E0E0).withOpacity(0.7), fontSize: screenWidth * 0.038),
                                ),
                                style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.038),
                                onTap: _pickDateTime,
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              TextField(
                                controller: _reasonController,
                                decoration: InputDecoration(
                                  labelText: 'Reason for Withdrawal',
                                  labelStyle: TextStyle(color: Color(0xFFE0E0E0), fontSize: screenWidth * 0.038),
                                  filled: true,
                                  fillColor: const Color(0xFF0B0B45),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.038),
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(screenWidth * 0.05, screenHeight * 0.01, screenWidth * 0.05, screenHeight * 0.015),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFFE0E0E0), fontSize: screenWidth * 0.038),
                  ),
                ).animate().fadeIn(duration: 400.ms),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF0B0B45),
                    foregroundColor: const Color(0xFFFFD700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isLoading ? null : () async {
                    if (_selectedMemberId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a member.'),
                          backgroundColor: Color(0xFF0B0B45),
                        ),
                      );
                      return;
                    }

                    final isDeposit = DefaultTabController.of(context)!.index == 0;
                    final controller = isDeposit ? _savingsController : _withdrawalController;
                    final amount = double.tryParse(controller.text);

                    if (controller.text.isEmpty || amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid amount.'),
                          backgroundColor: Color(0xFF0B0B45),
                        ),
                      );
                      return;
                    }

                    if (!isDeposit && _reasonController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a reason for withdrawal.'),
                          backgroundColor: Color(0xFF0B0B45),
                        ),
                      );
                      return;
                    }

                    try {
                      setState(() => isLoading = true);
                      final currentSavings = await Supabase.instance.client
                          .from('members')
                          .select('total_savings')
                          .eq('id', _selectedMemberId!)
                          .single()
                          .then((res) => res['total_savings'] as num);

                      if (!isDeposit && amount > currentSavings) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Withdrawal amount exceeds member savings.'),
                            backgroundColor: Color(0xFF0B0B45),
                          ),
                        );
                        return;
                      }

                      final entry = {
                        'group_id': widget.groupId,
                        'member_id': _selectedMemberId,
                        'amount': amount,
                        'type': isDeposit ? 'Deposit' : 'Withdrawal',
                        'note': isDeposit ? null : _reasonController.text.trim(),
                      };

                      debugPrint('Selected DateTime before insert: $_selectedDateTime');
                      if (_selectedDateTime != null) {
                        final utcDateTime = _selectedDateTime!.toUtc();
                        entry['created_at'] = utcDateTime.toIso8601String();
                        debugPrint('Inserted created_at: ${entry['created_at']}');
                      }

                      await Supabase.instance.client.from('savings_entries').insert(entry);

                      

                      final newSavings = isDeposit ? currentSavings + amount : currentSavings - amount;
                      await Supabase.instance.client
                          .from('members')
                          .update({'total_savings': newSavings})
                          .eq('id', _selectedMemberId!);

                      _savingsController.clear();
                      _withdrawalController.clear();
                      _reasonController.clear();
                      _dateTimeController.clear();
                      _selectedMemberId = null;
                      _selectedDateTime = null;

                      Navigator.pop(context);
                      widget.refreshCallback();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isDeposit
                              ? 'Savings added successfully!'
                              : 'Withdrawal processed successfully!'),
                          backgroundColor: const Color(0xFF0B0B45),
                        ),
                      );
                    } catch (e) {
                      debugPrint('Manage savings error: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isDeposit
                              ? 'Failed to add savings.'
                              : 'Failed to process withdrawal.'),
                          backgroundColor: const Color(0xFF0B0B45),
                        ),
                      );
                    } finally {
                      setState(() => isLoading = false); // Stop loader in all cases
                    }
                  },
                  child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Color(0xFFFFD700),
                        strokeWidth: 2,
                      ),
                    )
                  : Text('Submit', style: TextStyle(fontSize: screenWidth * 0.038)),
                ).animate().scale(
                      duration: 400.ms,
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(0.95, 0.95),
                      curve: Curves.easeInOut,
                    ),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms).slideY(
            begin: 0.2,
            end: 0,
            duration: 500.ms,
            curve: Curves.easeOut,
          ),
    );
  }
}