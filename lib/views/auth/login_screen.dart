import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../parent_eleve/parent_dashboard.dart';
import '../parent_eleve/eleve_dashboard.dart';
import '../enseignant/enseignant_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _requiresOtp = false;
  int? _otpUserId;
  String? _errorMessage;
  String? _infoMessage;
  String _currentIp = '172.20.14.254';

  @override
  void initState() {
    super.initState();
    _loadCurrentIp();
  }

  Future<void> _loadCurrentIp() async {
    final ip = await ApiService.getCustomIp();
    if (mounted && ip != null && ip.trim().isNotEmpty) {
      setState(() => _currentIp = ip.trim());
    }
  }

  Future<void> _handleLogin([String? customUser, String? customPass]) async {
    final username = customUser ?? _usernameController.text.trim();
    final password = customPass ?? _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Veuillez saisir votre nom d\'utilisateur et mot de passe.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final response = await AuthService.login(username, password);
      if (response != null && response['requiresOtp'] == true) {
        setState(() {
          _requiresOtp = true;
          _otpUserId = response['utilisateurId'];
          _infoMessage = response['message'] ?? 'Un code OTP à 6 chiffres a été envoyé sur votre adresse email.';
        });
        return;
      }

      if (response != null && response['token'] != null && mounted) {
        final user = await AuthService.getUserData();
        final role = user?['role'] ?? 'ELEVE';

        if (role == 'ENSEIGNANT') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const EnseignantDashboard()),
          );
        } else if (role == 'ELEVE') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const EleveDashboard()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ParentDashboard()),
          );
        }
      } else if (mounted) {
        setState(() => _errorMessage = 'Identifiants invalides.');
      }
    } catch (e) {
      if (mounted) {
        final err = e.toString();
        if (err.contains('SocketException') || err.contains('timed out') || err.contains('Connection refused')) {
          setState(() => _errorMessage = 'Impossible de joindre le serveur Spring Boot. Vérifiez que votre téléphone et l\'ordinateur sont sur le même réseau Wi-Fi.');
        } else {
          setState(() => _errorMessage = err.replaceAll('Exception: ', ''));
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleOtpVerify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Le code OTP doit contenir 6 chiffres.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AuthService.verifyOtp(_otpUserId!, otp);
      if (response != null && response['token'] != null && mounted) {
        final user = await AuthService.getUserData();
        final role = user?['role'] ?? 'ELEVE';

        if (role == 'ENSEIGNANT') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const EnseignantDashboard()),
          );
        } else if (role == 'ELEVE') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const EleveDashboard()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ParentDashboard()),
          );
        }
      } else if (mounted) {
        setState(() => _errorMessage = 'Code OTP invalide.');
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResendOtp() async {
    if (_otpUserId == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final response = await AuthService.resendOtp(_otpUserId!);
      if (mounted) {
        setState(() {
          _infoMessage = response?['message'] ?? 'Un nouveau code OTP a été envoyé par email.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showIpConfigDialog() async {
    final currentIp = await ApiService.getCustomIp() ?? _currentIp;
    final ipController = TextEditingController(text: currentIp);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Configuration IP Serveur', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entrez l\'adresse IP Wi-Fi de votre ordinateur pour connecter le téléphone au backend Spring Boot.',
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ipController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Adresse IP du Serveur (ex: 172.20.14.254)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newIp = ipController.text.trim();
                await ApiService.saveCustomIp(newIp);
                if (mounted) setState(() => _currentIp = newIp);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Adresse IP enregistrée : $newIp')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
              child: const Text('Enregistrer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          // Background ambient gradient circles
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryNavy.withValues(alpha: 0.5),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryGold.withValues(alpha: 0.2),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Stack(
              children: [
                // Top Right Settings Icon Button
                Positioned(
                  top: 10,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.settings_outlined, color: AppTheme.primaryGold),
                    tooltip: 'Configurer IP Serveur',
                    onPressed: _showIpConfigDialog,
                  ),
                ),

                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Brand Icon & Badge
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.goldGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryGold.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: const Icon(Icons.school_rounded, size: 48, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'NETAA ÉCOLE',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          'Portail Mobile Officiel 🇲🇱',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: AppTheme.primaryGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 35),

                        // Glassmorphic Login Form Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: AppTheme.glassDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Connexion d\'Accès',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Entrez vos identifiants pour accéder à votre espace',
                                style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),

                              if (_infoMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentEmerald.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.accentEmerald.withValues(alpha: 0.4)),
                                  ),
                                  child: Text(
                                    '📧 $_infoMessage',
                                    style: GoogleFonts.outfit(color: AppTheme.accentEmerald, fontSize: 13, fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              if (_errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentRose.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.accentRose.withValues(alpha: 0.4)),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        _errorMessage!,
                                        style: const TextStyle(color: AppTheme.accentRose, fontSize: 13),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: _showIpConfigDialog,
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.settings_rounded, size: 16, color: AppTheme.primaryGold),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  'Changer l\'IP du Serveur ($_currentIp)',
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.outfit(
                                                    color: AppTheme.primaryGold,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              if (_requiresOtp) ...[
                                const Icon(Icons.vpn_key_rounded, size: 44, color: AppTheme.primaryGold),
                                const SizedBox(height: 12),
                                Text(
                                  'Validation Première Connexion',
                                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Entrez le code OTP à 6 chiffres envoyé par mail',
                                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                TextField(
                                  controller: _otpController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 8, color: AppTheme.primaryGold),
                                  decoration: InputDecoration(
                                    hintText: '123456',
                                    hintStyle: TextStyle(color: Colors.white24, letterSpacing: 8),
                                    counterText: '',
                                    filled: true,
                                    fillColor: Colors.white.withValues(alpha: 0.05),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleOtpVerify,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryGold,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    child: _isLoading
                                        ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                                        : Text('Valider le code & Entrer', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                 const SizedBox(height: 10),
                                 Row(
                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                   children: [
                                     TextButton.icon(
                                       onPressed: _isLoading ? null : _handleResendOtp,
                                       icon: const Icon(Icons.mark_email_read_outlined, size: 16, color: AppTheme.primaryGold),
                                       label: const Text('Renvoyer le mail', style: TextStyle(color: AppTheme.primaryGold, fontSize: 12, fontWeight: FontWeight.bold)),
                                     ),
                                     TextButton(
                                       onPressed: () => setState(() { _requiresOtp = false; _errorMessage = null; _infoMessage = null; }),
                                       child: const Text('← Annuler', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                     ),
                                   ],
                                 ),
                              ] else ...[

                              // Username Field
                              TextField(
                                controller: _usernameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Nom d\'utilisateur / Email',
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryGold),
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.05),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppTheme.primaryGold),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Password Field
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Mot de passe',
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryGold),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.white54,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.05),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppTheme.primaryGold),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Login Submit Button
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : () => _handleLogin(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryGold,
                                    foregroundColor: Colors.white,
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: _isLoading
                                      ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                                      : Text(
                                          'Se Connecter',
                                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Quick Demo Shortcuts
                        Text('Accès Démo Rapide', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            _demoChip('👪 Parent / Élève', 'parent', '123456'),
                            _demoChip('👨‍🏫 Enseignant', 'enseignant', '123456'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _demoChip(String label, String user, String pass) {
    return ActionChip(
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      onPressed: () {
        _usernameController.text = user;
        _passwordController.text = pass;
        _handleLogin(user, pass);
      },
    );
  }
}
