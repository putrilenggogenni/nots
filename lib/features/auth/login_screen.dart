import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../core/widgets/nots_buttons.dart';
import '../../core/widgets/nots_common.dart';
import '../../core/widgets/nots_inputs.dart';
import 'auth_service.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

/// Layar "Masuk - Akun Terdaftar".
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final emailErr =
        isValidEmail(_email.text) ? null : 'Format email belum benar.';
    final passErr = _password.text.isEmpty ? 'Kata sandi wajib diisi.' : null;
    setState(() {
      _emailError = emailErr;
      _passwordError = passErr;
      _generalError = null;
    });
    if (emailErr != null || passErr != null) return;

    setState(() => _loading = true);
    final nav = Navigator.of(context);

    try {
      await _auth.signIn(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      nav.popUntil((route) => route.isFirst);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _generalError = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NotsBackAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 38, 20, 32),
        child: Column(
          children: [
            const NotsLogo(),
            const SizedBox(height: 8),
            Text(
              'Masuk ke NOTS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                height: 24 / 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
                color: NotsColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Lanjutkan kelola tugas dan jadwal kuliahmu.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 20 / 14,
                color: NotsColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(48),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  NotsPillField(
                    label: 'Email',
                    controller: _email,
                    hint: 'nama@email.com',
                    leadingIcon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    errorText: _emailError,
                    onChanged: (_) {
                      if (_emailError != null) {
                        setState(() => _emailError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  NotsPillField(
                    label: 'Kata Sandi',
                    controller: _password,
                    hint: 'Kata sandimu',
                    leadingIcon: Icons.lock_outline,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    errorText: _passwordError,
                    onSubmitted: (_) => _submit(),
                    onChanged: (_) {
                      if (_passwordError != null) {
                        setState(() => _passwordError = null);
                      }
                    },
                    labelAction: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      ),
                      child: Text(
                        'Lupa kata sandi?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          height: 14 / 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.22,
                          color: NotsColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                  if (_generalError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _generalError!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: NotsColors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  NotsPrimaryButton(
                    label: 'Masuk ke Akun',
                    height: 46,
                    fontSize: 13,
                    loading: _loading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Belum punya akun?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: NotsColors.textSecondary,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: Text(
                    'Daftar',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: NotsColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
