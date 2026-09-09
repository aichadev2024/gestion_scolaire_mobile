import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
          title: Text('Configuration IP serveur', style: AppTheme.display(fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entrez l\'adresse IP Wi-Fi de votre ordinateur pour connecter le téléphone au backend Spring Boot.',
                style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ipController,
                decoration: const InputDecoration(
                  labelText: 'Adresse IP du serveur (ex: 172.20.14.254)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
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
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paper,
      body: Stack(
        children: [
          // Halos d'ambiance
          Positioned(
            top: -90,
            right: -90,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.indigo.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -70,
            left: -70,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.laterite.withValues(alpha: 0.08),
              ),
            ),
          ),

          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 10,
                  right: 12,
                  child: IconButton(
                    icon: const Icon(Icons.settings_outlined, color: AppTheme.indigo),
                    tooltip: 'Configurer l\'IP du serveur',
                    onPressed: _showIpConfigDialog,
                  ),
                ),

                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset('assets/brand/netaa-mark.svg', width: 64, height: 64),
                        const SizedBox(height: 14),
                        Text(
                          'Netaa École',
                          style: AppTheme.display(fontSize: 26, color: AppTheme.indigo, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Portail mobile officiel',
                          style: AppTheme.mono(fontSize: 10, color: AppTheme.laterite, letterSpacing: 3),
                        ),
                        const SizedBox(height: 32),

                        // Carte de connexion
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: AppTheme.cardDecoration(borderRadius: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Connexion',
                                style: AppTheme.display(fontSize: 20, color: AppTheme.indigo),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Entrez vos identifiants pour accéder à votre espace',
                                style: AppTheme.body(fontSize: 12, color: AppTheme.inkMuted),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),

                              if (_infoMessage != null) ...[
                                _MessageBox(
                                  text: '📧 $_infoMessage',
                                  color: AppTheme.flagGreen,
                                ),
                                const SizedBox(height: 16),
                              ],

                              if (_errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.danger.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.danger.withValues(alpha: 0.35)),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        _errorMessage!,
                                        style: AppTheme.body(color: AppTheme.danger, fontSize: 13),
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
                                              const Icon(Icons.settings_rounded, size: 16, color: AppTheme.laterite),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  'Changer l\'IP du serveur ($_currentIp)',
                                                  textAlign: TextAlign.center,
                                                  style: AppTheme.body(
                                                    color: AppTheme.laterite,
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
                                const Icon(Icons.vpn_key_rounded, size: 44, color: AppTheme.mil),
                                const SizedBox(height: 12),
                                Text(
                                  'Validation première connexion',
                                  style: AppTheme.display(fontSize: 17, color: AppTheme.indigo),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Entrez le code OTP à 6 chiffres envoyé par mail',
                                  style: AppTheme.body(fontSize: 12, color: AppTheme.inkMuted),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                TextField(
                                  controller: _otpController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  textAlign: TextAlign.center,
                                  style: AppTheme.mono(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 8, color: AppTheme.indigo),
                                  decoration: const InputDecoration(
                                    hintText: '123456',
                                    counterText: '',
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleOtpVerify,
                                    child: _isLoading
                                        ? const SpinKitThreeBounce(color: AppTheme.paper, size: 20)
                                        : Text('Valider le code & entrer', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton.icon(
                                      onPressed: _isLoading ? null : _handleResendOtp,
                                      icon: const Icon(Icons.mark_email_read_outlined, size: 16, color: AppTheme.laterite),
                                      label: Text('Renvoyer le mail', style: AppTheme.body(color: AppTheme.laterite, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                    TextButton(
                                      onPressed: () => setState(() { _requiresOtp = false; _errorMessage = null; _infoMessage = null; }),
                                      child: Text('← Annuler', style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                TextField(
                                  controller: _usernameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nom d\'utilisateur / email',
                                    prefixIcon: Icon(Icons.person_outline, color: AppTheme.indigo),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Mot de passe',
                                    prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.indigo),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                        color: AppTheme.inkMuted,
                                      ),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : () => _handleLogin(),
                                    child: _isLoading
                                        ? const SpinKitThreeBounce(color: AppTheme.paper, size: 20)
                                        : Text(
                                            'Se connecter',
                                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                                          ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        Text('Accès démo rapide', style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 12)),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            _demoChip('Parent / élève', 'parent', '123456'),
                            _demoChip('Enseignant', 'enseignant', '123456'),
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
      label: Text(label),
      onPressed: () {
        _usernameController.text = user;
        _passwordController.text = pass;
        _handleLogin(user, pass);
      },
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: AppTheme.body(color: color, fontSize: 13, fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
    );
  }
}
