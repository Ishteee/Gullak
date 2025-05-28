import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class GroupScreen extends StatefulWidget {
  const GroupScreen({Key? key}) : super(key: key);

  @override
  State<GroupScreen> createState() => GroupScreenState();
}

class GroupScreenState extends State<GroupScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  Future<List<Map<String, dynamic>>> _fetchGroups() async {
    // Fetch user's memberships
    final userMembers = await Supabase.instance.client
        .from('members')
        .select()
        .eq('user_id', Supabase.instance.client.auth.currentUser!.id);
    debugPrint('User members: ${userMembers.length}, Data: $userMembers');

    final groupIds = userMembers.map((m) => m['group_id'] as int).toList();
    debugPrint('Group IDs: $groupIds');

    if (groupIds.isEmpty) {
      return [];
    }

    // Fetch groups
    final groups = await Supabase.instance.client
        .from('groups')
        .select()
        .inFilter('id', groupIds);
    debugPrint('Groups: ${groups.length}, Data: $groups');

    // Fetch all members for these groups
    final allMembers = await Supabase.instance.client
        .from('members')
        .select('group_id, total_savings')
        .inFilter('group_id', groupIds);
    debugPrint('All members: ${allMembers.length}, Data: $allMembers');

    // Aggregate stats
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

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B45),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
          color: Color(0xFFFFD700),
          backgroundColor: Color(0xFF0B0B45),
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
                  'Your Groups',
                  style: TextStyle(
                    color: const Color(0xFFFFD700),
                    fontSize: math.min(screenWidth * 0.06, 28),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
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
              expandedHeight: screenHeight * 0.2,
              floating: true,
              pinned: true,
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchGroups(),
                    builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.07),
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
                                      Navigator.pushNamed(context, '/create-group');
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
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/group_details',
                                      arguments: {'groupId': group['id'], 'groupName': group['name'], 'joining_code': group['joining_code']},
                                    );
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
          ],
        ),
      ),
    );
  }
}