import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _joinCodeController = TextEditingController();
  bool _hasJoinError = false;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchGroups() async {
    final userMembers = await Supabase.instance.client
        .from('members')
        .select()
        .eq('user_id', Supabase.instance.client.auth.currentUser!.id) as List<Map<String, dynamic>>;
    debugPrint('User members: ${userMembers.length}, Data: $userMembers');

    final groupIds = userMembers.map((m) => m['group_id'] as int).toList();
    debugPrint('Group IDs: $groupIds');

    if (groupIds.isEmpty) {
      return [];
    }

    final groups = await Supabase.instance.client
        .from('groups')
        .select()
        .inFilter('id', groupIds);
    debugPrint('Groups: ${groups.length}, Data: $groups');

    final allMembers = await Supabase.instance.client
        .from('members')
        .select('group_id, total_savings')
        .inFilter('group_id', groupIds);
    debugPrint('All members: ${allMembers.length}, Data: $allMembers');

    final groupList = groups.map((group) {
      final groupMembers = allMembers.where((m) => m['group_id'] == group['id']).toList();
      final totalSavings = groupMembers.fold<double>(
          0.0, (sum, m) => sum + (m['total_savings'] as num).toDouble());
      return {
        ...group,
        'total_savings': totalSavings,
        'member_count': groupMembers.length,
      };
    }).toList();
    debugPrint('Processed groups: ${groupList.length}');

    return groupList;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 600;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [Color(0xFF0B0B45), Color(0xFF1A237E)],
            ),
          ),
          child: RefreshIndicator(
            key: _refreshIndicatorKey,
            color: Color(0xFFFFD700),
            backgroundColor: Color(0xFF0B0B45),
            onRefresh: () async {
              setState(() {});
            },
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0B0B45), Color(0xFF1A237E).withOpacity(0.9)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: screenHeight * 0.03),
                          Icon(
                            Icons.savings,
                            size: screenWidth * 0.18,
                            color: Color(0xFFFFD700),
                          ).animate().scale(
                                duration: 800.ms,
                                begin: Offset(0.7, 0.7),
                                end: Offset(1.0, 1.0),
                                curve: Curves.bounceOut,
                              ).shimmer(
                                duration: 2000.ms,
                                color: Color(0xFFFFD700).withOpacity(0.3),
                              ),
                          SizedBox(height: screenHeight * 0.01),
                          Text(
                            'Gullak',
                            style: GoogleFonts.orbitron(
                              color: Color(0xFFFFD700),
                              fontSize: screenWidth * 0.09,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              shadows: [
                                Shadow(
                                  color: Color(0xFFFFD700).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 1000.ms),
                          SizedBox(height: screenHeight * 0.01),
                          Text(
                            'Save together, grow together!',
                            style: TextStyle(
                              color: Color(0xFFE0E0E0),
                              fontSize: screenWidth * 0.045,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w300,
                            ),
                          ).animate().slideY(
                                begin: 0.3,
                                end: 0,
                                duration: 1000.ms,
                                curve: Curves.easeOut,
                              ),
                        ],
                      ),
                    ),
                  ),
                  expandedHeight: (screenHeight * 0.28).clamp(180, 250),
                  floating: true,
                  pinned: true,
                  actions: [
                    Padding(
                      padding: EdgeInsets.only(right: screenWidth * 0.04),
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/profile'),
                        child: CircleAvatar(
                          radius: screenWidth * 0.06,
                          backgroundColor: const Color(0xFF000000),
                          child: FutureBuilder(
                            future: Supabase.instance.client
                                .from('profiles')
                                .select('name')
                                .eq('user_id', Supabase.instance.client.auth.currentUser!.id)
                                .single(),
                            builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
                              return Text(
                                snapshot.hasData ? (snapshot.data!['name'] as String)[0].toUpperCase() : '',
                                style: TextStyle(
                                  color: const Color(0xFFFFD700),
                                  fontSize: screenWidth * 0.05,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ).animate().scale(
                              duration: const Duration(milliseconds: 400),
                              begin: const Offset(1.0, 1.0),
                              end: const Offset(0.95, 0.95),
                              curve: Curves.easeInOut,
                            ),
                      ),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04, vertical: screenHeight * 0.02),
                    child: FutureBuilder(
                      future: Supabase.instance.client
                          .from('members')
                          .select('total_savings')
                          .eq('user_id', Supabase.instance.client.auth.currentUser!.id)
                          .then((response) => (response as List<dynamic>)
                              .fold(0.0, (sum, item) => sum + (item['total_savings'] ?? 0.0))),
                      builder: (context, AsyncSnapshot<double> snapshot) {
                        return Container(
                          width: screenWidth * 0.9,
                          height: screenHeight * 0.13,
                          padding: EdgeInsets.all(screenWidth * 0.03),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF1A237E), Color(0xFF0B0B45)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Color(0xFFFFD700), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFFFD700).withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Your Savings',
                                style: TextStyle(
                                  color: Color(0xFFE0E0E0),
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Text(
                                snapshot.hasData
                                    ? '₹${snapshot.data!.toStringAsFixed(2)}'
                                    : 'Calculating...',
                                style: TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: screenWidth * 0.05,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ).animate().scale(
                              duration: 800.ms,
                              begin: Offset(0.9, 0.9),
                              end: Offset(1.0, 1.0),
                              curve: Curves.easeOut,
                            ).shimmer(
                              duration: 2000.ms,
                              color: Color(0xFFFFD700).withOpacity(0.2),
                            );
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04, vertical: screenHeight * 0.005),
                    child: Text(
                      'Your Groups',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ).animate().fadeIn(duration: 600.ms),
                  ),
                ),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchGroups(),
                  builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.11),
                            child: SpinKitCubeGrid(
                              color: Color(0xFFFFD700),
                              size: screenWidth * 0.12,
                            ),
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      debugPrint('Fetch error: ${snapshot.error}');
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.07),
                            child: Text(
                              'Error loading groups.',
                              style: TextStyle(
                                color: Color(0xFFE0E0E0),
                                fontSize: screenWidth * 0.045,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    final groups = snapshot.data ?? [];
                    return SliverPadding(
                      padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04, vertical: screenHeight * 0.02),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: screenWidth / 2.2,
                          mainAxisSpacing: screenWidth * 0.03,
                          crossAxisSpacing: screenWidth * 0.03,
                          childAspectRatio: 1.0,
                          mainAxisExtent: screenHeight * 0.24,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == groups.length) {
                              return Animate(
                                effects: [
                                  FadeEffect(duration: 500.ms, delay: (index * 150).ms),
                                  SlideEffect(
                                    begin: const Offset(0, 0.3),
                                    end: Offset.zero,
                                    duration: 500.ms,
                                    delay: (index * 150).ms),
                                ],
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(context, '/create-group').then((result) {
                                      if (result == 'refresh') {
                                        setState(() {
                                          // or call any function here to refresh data
                                        });
                                      }
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF0B0B45), Color(0xFF1A237E)],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFFD700).withOpacity(0.4),
                                          blurRadius: 12,
                                          spreadRadius: 3,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(screenWidth * 0.02),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_circle,
                                            color: const Color(0xFFFFD700),
                                            size: screenWidth * 0.06,
                                          ),
                                          SizedBox(height: screenHeight * 0.01),
                                          Text(
                                            'Create Group',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: screenWidth * 0.045,
                                              fontWeight: FontWeight.w800,
                                              shadows: [
                                                Shadow(
                                                  color: const Color(0xFFFFD700).withOpacity(0.3),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                            final group = groups[index];
                            final savingsGoal = (group['savings_goal'] as num).toDouble();
                            final totalSavings = (group['total_savings'] as num).toDouble();
                            final remainingGoal = (savingsGoal - totalSavings).clamp(0, savingsGoal);
                            final progressPercent = savingsGoal > 0
                                ? (totalSavings / savingsGoal * 100).clamp(0, 100).toDouble()
                                : 0;
                            return Animate(
                              effects: [
                                FadeEffect(duration: 500.ms, delay: (index * 150).ms),
                                SlideEffect(
                                  begin: const Offset(0, 0.3),
                                  end: Offset.zero,
                                  duration: 500.ms,
                                  delay: (index * 150).ms,
                                ),
                              ],
                              child: GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.pushNamed(
                                    context,
                                    '/group_details',
                                    arguments: {
                                      'groupId': group['id'],
                                      'groupName': group['name'],
                                      'joining_code': group['joining_code'],
                                    },
                                  );

                                  if (result == 'refresh') {
                                    setState(() {
                                          // or call any function here to refresh data
                                        });
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF0B0B45), Color(0xFF1A237E)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFFD700).withOpacity(0.4),
                                        blurRadius: 12,
                                        spreadRadius: 3,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(screenWidth * 0.02),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(top: screenWidth * 0.01, left: screenWidth * 0.01),
                                          child: Text(
                                            group['name'],
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: screenWidth * 0.045,
                                              fontWeight: FontWeight.w800,
                                              shadows: [
                                                Shadow(
                                                  color: const Color(0xFFFFD700).withOpacity(0.3),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(height: screenHeight * 0.005),
                                        Divider(
                                          color: const Color(0xFFFFD700).withOpacity(0.5),
                                          thickness: 1,
                                          height: screenHeight * 0.015,
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: screenWidth * 0.01, horizontal: screenWidth * 0.02),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFF0B0B45).withOpacity(0.8),
                                                const Color(0xFF1A237E).withOpacity(0.6),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.account_balance_wallet,
                                                color: const Color(0xFFFFD700),
                                                size: screenWidth * 0.04,
                                              ),
                                              SizedBox(width: screenWidth * 0.015),
                                              Text(
                                                '₹${totalSavings.toStringAsFixed(0)} saved',
                                                style: TextStyle(
                                                  color: const Color(0xFFFFD700),
                                                  fontSize: screenWidth * 0.035,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: screenHeight * 0.005),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: screenWidth * 0.01, horizontal: screenWidth * 0.02),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFF0B0B45).withOpacity(0.8),
                                                const Color(0xFF1A237E).withOpacity(0.6),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.savings,
                                                color: const Color(0xFFFFD700),
                                                size: screenWidth * 0.04,
                                              ),
                                              SizedBox(width: screenWidth * 0.015),
                                              Text(
                                                '₹${remainingGoal.toStringAsFixed(0)} left',
                                                style: TextStyle(
                                                  color: const Color(0xFFFFD700),
                                                  fontSize: screenWidth * 0.035,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: screenHeight * 0.005),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: screenWidth * 0.01, horizontal: screenWidth * 0.02),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFF0B0B45).withOpacity(0.8),
                                                const Color(0xFF1A237E).withOpacity(0.6),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.trending_up,
                                                color: const Color(0xFFE0E0E0),
                                                size: screenWidth * 0.04,
                                              ),
                                              SizedBox(width: screenWidth * 0.015),
                                              Text(
                                                '${progressPercent.toStringAsFixed(2)}% complete',
                                                style: TextStyle(
                                                  color: const Color(0xFFE0E0E0),
                                                  fontSize: screenWidth * 0.035,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: screenHeight * 0.005),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: screenWidth * 0.01, horizontal: screenWidth * 0.02),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFF0B0B45).withOpacity(0.8),
                                                const Color(0xFF1A237E).withOpacity(0.6),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.group,
                                                color: const Color(0xFFE0E0E0E0),
                                                size: screenWidth * 0.04,
                                              ),
                                              SizedBox(width: screenWidth * (0.015)),
                                              Text(
                                                '${group['member_count']} member${group['member_count'] == 1 ? '' : 's'}',
                                                style: TextStyle(
                                                  color: const Color(0xFFE0E0E0),
                                                  fontSize: screenWidth * 0.035,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ));
                          },
                          childCount: groups.length + 1,
                        ),
                      ),
                    );
                  },
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04, vertical: screenHeight * 0.01),
                    child: Column(
                      children: [
                        _buildActionButton(
                          context,
                          label: 'Join an Existing Group',
                          icon: Icons.group_add,
                          onTap: () {
                            Navigator.pushNamed(context, '/join-group').then((result) {
                                      if (result == 'refresh') {
                                        setState(() {
                                          // or call any function here to refresh data
                                        });
                                      }
                                    });
                          },
                          // onTap: () => _showJoinGroupDialog(context),
                          isTablet: isTablet,
                          screenWidth: screenWidth,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                        left: screenWidth * 0.06,
                        top: screenHeight * 0.05,
                        bottom: screenHeight * 0.02),
                    child: Text(
                      'Gullak',
                      style: GoogleFonts.orbitron(
                        color: const Color(0xFFE0E0E0).withOpacity(0.3),
                        fontSize: screenWidth * 0.11,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(duration: 1000.ms),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isTablet,
    required double screenWidth,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: screenWidth * 0.9,
        padding: EdgeInsets.symmetric(
            vertical: screenWidth * 0.045, horizontal: screenWidth * 0.04),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B0B45), Color(0xFF1A237E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFFFFD700), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFFFD700).withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Color(0xFFFFD700),
              size: screenWidth * 0.08,
            ),
            SizedBox(width: screenWidth * 0.03),
            Text(
              label,
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ).animate().scale(
            duration: 400.ms,
            begin: Offset(1.0, 1.0),
            end: Offset(0.95, 0.95),
            curve: Curves.easeInOut,
          ).fadeIn(duration: 400.ms).shimmer(
            duration: 2000.ms,
            color: Color(0xFFFFD700).withOpacity(0.2),
          ),
    );
  }

}