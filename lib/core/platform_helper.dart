import 'package:flutter/foundation.dart';

class PlatformHelper {
  /// Running in a browser (Flutter Web)
  static bool get isWeb => kIsWeb;

  /// Mobile phones (Android / iOS)
  static bool get isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Desktop (Windows / macOS / Linux)
  static bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  /// Use backend proxy on web; native youtube_explode_dart everywhere else
  static bool get useBackendProxy => kIsWeb;
}
