import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../screens/home_screen.dart';
import '../screens/library_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/search_screen.dart';
import '../widgets/desktop_player_bar.dart';

class DesktopLayout extends StatefulWidget {
  const DesktopLayout({super.key});

  @override
  State<DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends State<DesktopLayout> {
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
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Left sidebar (240px)
                SizedBox(width: kSidebarW, child: _buildSidebar()),
                const VerticalDivider(width: 1, color: kDivider),
                // Main content
                Expanded(child: _pages[_currentIndex]),
              ],
            ),
          ),
          // Bottom player bar (full width)
          const DesktopPlayerBar(),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      color: kDesktopSidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo / app name
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kAccent, kAccentCyan],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.music_note_rounded,
                      color: kTextPrimary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  kAppName,
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          _navItem(Icons.home_rounded, 'Home', 0),
          _navItem(Icons.search_rounded, 'Search', 1),
          _navItem(Icons.library_music_rounded, 'Library', 2),
          _navItem(Icons.person_rounded, 'Profile', 3),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'v1.0.0',
              style: TextStyle(color: kTextSecondary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: isActive
            ? BoxDecoration(
                color: kAccent.withAlpha(38),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kAccent.withAlpha(76), width: 1),
              )
            : BoxDecoration(borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(icon,
                color: isActive ? kAccent : kTextSecondary, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isActive ? kTextPrimary : kTextSecondary,
                fontSize: 14,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
