import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gullak/screens/group_details_screen.dart';
import 'package:gullak/screens/join_group_screen.dart';
import 'package:gullak/screens/leave_group_screen.dart';
import 'package:gullak/screens/saving_records_screen.dart';
import 'screens/home_screen.dart';
import 'screens/group_screen.dart';
import 'screens/create_group_screen.dart';
import 'screens/profile.dart';

class Navbar extends StatefulWidget {
  const Navbar({Key? key}) : super(key: key);

  @override
  _NavbarState createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int _selectedIndex = 0;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  DateTime? _lastPressed;

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      // Pop to root of current tab
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _selectedIndex = index;
      });
      final routeName = index == 0 ? '/home' : '/groups';
      _navigatorKey.currentState?.pushReplacementNamed(routeName);
    }
  }

  Future<bool> _handleBackPress() async {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return true;

    // Check if there are routes to pop in the current tab
    if (navigator.canPop()) {
      navigator.pop();
      return false; // Don't exit app
    }

    // On GroupScreen (index 1), switch to HomeScreen
    if (_selectedIndex == 1) {
      setState(() {
        _selectedIndex = 0;
      });
      _navigatorKey.currentState?.pushReplacementNamed('/home');
      return false; // Don't exit app
    }

    // On HomeScreen (index 0)
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
        return false; // Don't exit app
      }
      return true; // Exit app
    }
    return true; // iOS: Allow exit
  }

  @override
  Widget build(BuildContext context) {
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
        body: Navigator(
          key: _navigatorKey,
          initialRoute: '/home',
          onGenerateRoute: (settings) {
            Widget page;
            switch (settings.name) {
              case '/home':
                page = HomeScreen();
                break;
              case '/groups':
                page = GroupScreen();
                break;
              case '/create-group':
                page = CreateGroupScreen();
                break;
              case '/join-group':
                page = const JoinGroupScreen();
                break;
              case '/leave_group':
                page = const LeaveGroupScreen();
                break;
              case '/profile':
                page = const ProfileScreen();
                break;
              case '/group_details':
                page = const GroupDetailsScreen();
                break;
              case '/saving_records':
                page = const SavingRecordsScreen();
                break;
              default:
                return null; // Prevent unintended screens
            }
            return MaterialPageRoute(
              builder: (_) => page,
              settings: settings,
            );
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(0xFF1A237E),
          selectedItemColor: const Color(0xFFFFD700),
          unselectedItemColor: const Color(0xFFE0E0E0),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          elevation: 8,
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.home,
                size: 28,
                color: _selectedIndex == 0 ? const Color(0xFFFFD700) : const Color(0xFFE0E0E0),
              ),
              label: 'Home',
              backgroundColor: const Color(0xFF000000),
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.group,
                size: 28,
                color: _selectedIndex == 1 ? const Color(0xFFFFD700) : const Color(0xFFE0E0E0),
              ),
              label: 'Groups',
              backgroundColor: const Color(0xFF000000),
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}