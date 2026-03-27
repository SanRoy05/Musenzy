import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../screens/home_screen.dart';
import '../screens/library_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/search_screen.dart';
import '../widgets/mini_player.dart';

class MobileLayout extends StatefulWidget {
  const MobileLayout({super.key});

  @override
  State<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<MobileLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _pages),
          // Mini player above bottom nav
          const Positioned(
            bottom: kBottomNavH + 4,
            left: 0,
            right: 0,
            child: MiniPlayer(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: kBottomNavH,
      color: kSurface2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_rounded, 'Home', 0),
          _navItem(Icons.search_rounded, 'Search', 1),
          _navItem(Icons.library_music_rounded, 'Library', 2),
          _navItem(Icons.person_rounded, 'Profile', 3),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: kAccent,
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? kTextPrimary : kTextSecondary, size: 22),
            if (!isActive) ...[
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(color: kTextSecondary, fontSize: 10)),
            ],
          ],
        ),
      ),
    );
  }
}
