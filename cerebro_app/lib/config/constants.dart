class AppConstants {
  // api
  static const String apiBaseUrl = 'http://localhost:8000/api/v1';
  static const int apiTimeout = 30000;

  // google oauth (macOS uses iOS client type)
  static const String googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
  static const String googleClientSecret = String.fromEnvironment('GOOGLE_CLIENT_SECRET');

  // shared prefs keys
  static const String accessTokenKey = 'cerebro_access_token';
  static const String refreshTokenKey = 'cerebro_refresh_token';
  static const String userIdKey = 'cerebro_user_id';
  static const String themeKey = 'cerebro_theme_mode';
  static const String onboardingCompleteKey = 'cerebro_onboarding_done';
  static const String setupCompleteKey = 'cerebro_setup_done';
  static const String avatarCreatedKey = 'cerebro_avatar_created';
  static const String avatarConfigKey = 'cerebro_avatar_config';

  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration cardAnimation = Duration(milliseconds: 200);
}
