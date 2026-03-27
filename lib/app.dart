import 'package:flutter/material.dart';

import 'core/constants.dart';
import 'layouts/desktop_layout.dart';
import 'layouts/mobile_layout.dart';
import 'layouts/tablet_layout.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const ResponsiveLayout(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: kBackground,
      colorScheme: const ColorScheme.dark(
        primary: kAccent,
        secondary: kAccentCyan,
        surface: kSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: kBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: kTextPrimary),
        titleTextStyle: TextStyle(
          color: kTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      fontFamily: 'Roboto',
      sliderTheme: const SliderThemeData(
        activeTrackColor: kAccent,
        inactiveTrackColor: kSurface,
        thumbColor: kTextPrimary,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: kSurface,
        contentTextStyle: TextStyle(color: kTextPrimary),
      ),
    );
  }
}

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200) {
          return const DesktopLayout();
        } else if (constraints.maxWidth >= 600) {
          return const TabletLayout();
        } else {
          return const MobileLayout();
        }
      },
    );
  }
}
