class ApiConstants {
  /// URL de base de l'API — toujours le backend de production. L'application
  /// ne permet plus de la reconfigurer depuis l'écran de connexion (un ancien
  /// réglage de développement qui empêchait certains téléphones de se
  /// connecter s'ils avaient une adresse locale enregistrée par erreur).
  ///
  /// Pour un build de développement pointant vers un autre serveur, utiliser
  /// exclusivement `--dart-define` au moment du build :
  ///   flutter build web --dart-define=API_BASE_URL=http://localhost:8089/api
  ///   flutter build apk --dart-define=API_BASE_URL=http://10.0.2.2:8089/api
  static const String _defaultUrl =
      'https://gestion-scolaire-backend-x0hy.onrender.com/api';

  static const String productionUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultUrl,
  );

  static const String baseUrl = productionUrl;
  // Endpoints
  static const String login = '/auth/login';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String eleves = '/eleves';
  static const String enseignants = '/enseignants';
  static const String classes = '/classes';
  static const String bulletins = '/bulletins';
  static const String paiements = '/paiements';
  static const String presences = '/presences';
  static const String matieres = '/matieres';
  static const String notes = '/notes';
}
