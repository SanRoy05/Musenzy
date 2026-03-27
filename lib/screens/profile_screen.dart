import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'onboarding_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            backgroundColor: kBackground,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kAccent, kAccentCyan],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person_rounded,
                            color: kTextPrimary, size: 44),
                      ),
                      SizedBox(height: 12),
                      Text('Music Lover',
                          style: TextStyle(
                              color: kTextPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('⚙️ Settings',
                      style: TextStyle(
                          color: kTextPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _SettingTile(
                    icon: Icons.music_note_rounded,
                    title: 'Audio Quality',
                    subtitle: 'High (256kbps)',
                    onTap: () {},
                  ),
                  _SettingTile(
                    icon: Icons.download_rounded,
                    title: 'Downloads',
                    subtitle: 'Manage offline songs',
                    onTap: () {},
                  ),
                  _SettingTile(
                    icon: Icons.notifications_rounded,
                    title: 'Notifications',
                    subtitle: 'Manage alerts',
                    onTap: () {},
                  ),
                  _SettingTile(
                    icon: Icons.personal_video_rounded,
                    title: 'Music Preferences',
                    subtitle: 'Edit your favourite singers',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OnboardingScreen(isEditing: true),
                        ),
                      );
                    },
                  ),
                  _SettingTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About',
                    subtitle: '$kAppName v1.0.0',
                    onTap: () {},
                  ),
                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: kAccent.withAlpha(38),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: kAccent, size: 22),
      ),
      title: Text(title,
          style: const TextStyle(color: kTextPrimary, fontSize: 15)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: kTextSecondary, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded, color: kTextSecondary),
      onTap: onTap,
    );
  }
}
