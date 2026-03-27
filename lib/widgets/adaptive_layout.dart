import 'package:flutter/material.dart';

class AdaptiveLayout {
  static const double mobileMax = 600;
  static const double tabletMax = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileMax;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= mobileMax && w < tabletMax;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletMax;

  static int gridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 600) return 2;
    if (w < 900) return 3;
    if (w < 1200) return 4;
    return 5;
  }

  static double cardWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 600) return 160;
    if (w < 1200) return 200;
    return 240;
  }

  static double featuredCardHeight(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 600) return 160;
    if (w < 1200) return 200;
    return 200;
  }
}
