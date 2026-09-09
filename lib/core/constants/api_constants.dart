class ApiConstants {
  // URL de base de l'API.
  // TODO (Phase 3) : externaliser via --dart-define / flavors (dev, staging, prod)
  //                  au lieu d'une constante compilée.
  //   - Émulateur Android : http://10.0.2.2:8089/api
  //   - Web / desktop      : http://localhost:8089/api
  //   - Appareil physique  : http://<IP-LAN-du-poste>:8089/api
  static const String productionUrl =
      'https://gestion-scolaire-backend-x0hy.onrender.com/api';
  static const String emulatorUrl = 'http://10.0.2.2:8089/api';
  static const String localWebUrl = 'http://localhost:8089/api';

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
