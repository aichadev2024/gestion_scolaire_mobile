class ApiConstants {
  // Base URL for API requests.
  // Physical Phone Wi-Fi IP (Computer IP): 172.20.14.254
  // Emulator: 10.0.2.2
  // Web/Windows: localhost
  static const String physicalPhoneUrl = 'http://172.20.14.254:8089/api';
  static const String emulatorUrl = 'http://10.0.2.2:8089/api';
  static const String localWebUrl = 'http://localhost:8089/api';
  
  static const String baseUrl = physicalPhoneUrl;

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
