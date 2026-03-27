class ApiConfig {
  /// ⚠️ Change to your deployed backend URL after deployment.
  /// For local testing use: http://localhost:3000
  /// For production: https://your-app.railway.app
  static const String backendBaseUrl = 'http://localhost:3000';

  static String get searchUrl  => '$backendBaseUrl/api/search';
  static String get streamUrl  => '$backendBaseUrl/api/stream-url';
  static String get trendingUrl => '$backendBaseUrl/api/trending';
  static String get songUrl    => '$backendBaseUrl/api/song';
}
