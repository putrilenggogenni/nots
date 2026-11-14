import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../core/widgets/nots_buttons.dart';
import '../../core/widgets/nots_common.dart';
import '../../core/widgets/nots_inputs.dart';
import 'auth_service.dart';
import 'login_screen.dart';

/// Layar "Daftar - Buat Akun".
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();

  bool _obscure = true;
  bool _loading = false;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _validate() {
    final pass = _password.text;
    final nameErr = _name.text.trim().isEmpty ? 'Nama wajib diisi.' : null;
    final emailErr =
        isValidEmail(_email.text) ? null : 'Format email belum benar.';
    final passOk = pass.length >= 6 &&
        RegExp(r'[A-Za-z]').hasMatch(pass) &&
        RegExp(r'\d').hasMatch(pass);
    final passErr =
        passOk ? null : 'Minimal 6 karakter, kombinasi huruf dan angka.';

    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
      _passwordError = passErr;
      _generalError = null;
    });
    return nameErr == null && emailErr == null && passErr == null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;

    setState(() => _loading = true);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final signedIn = await _auth.signUp(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      if (signedIn) {
        // AuthGate di main.dart otomatis menampilkan halaman awal.
        nav.popUntil((route) => route.isFirst);
      } else {
        messenger.showSnackBar(const SnackBar(
          content: Text('Akun dibuat. Cek emailmu untuk verifikasi, lalu masuk.'),
        ));
        nav.pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() {
        switch (e.field) {
          case AuthErrorField.email:
            _emailError = e.message;
          case AuthErrorField.password:
            _passwordError = e.message;
          case AuthErrorField.general:
            _generalError = e.message;
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NotsBackAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: NotsLogo(),
            ),
            const SizedBox(height: 20),
            Text(
              'Buat akun',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 30,
                height: 38 / 30,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.75,
                color: NotsColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Cukup satu kali, lalu tenggatmu aman.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 20 / 14,
                color: NotsColors.tealText,
              ),
            ),
            const SizedBox(height: 24),
            const _WelcomeNote(),
            const SizedBox(height: 24),
            NotsFormField(
              label: 'Nama',
              controller: _name,
              hint: 'Nama lengkap',
              errorText: _nameError,
              textInputAction: TextInputAction.next,
              suffix: const Icon(Icons.badge_outlined,
                  size: 18, color: NotsColors.inputIcon),
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: 20),
            NotsFormField(
              label: 'Email',
              controller: _email,
              hint: 'nama@email.com',
              errorText: _emailError,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onChanged: (_) {
                if (_emailError != null) setState(() => _emailError = null);
              },
            ),
            const SizedBox(height: 20),
            NotsFormField(
              label: 'Password',
              controller: _password,
              hint: 'Buat kata sandi',
              obscureText: _obscure,
              errorText: _passwordError,
              helperText: 'Minimal 6 karakter kombinasi huruf dan angka',
              textInputAction: TextInputAction.done,
              suffix: IconButton(
                tooltip: _obscure
                    ? 'Tampilkan kata sandi'
                    : 'Sembunyikan kata sandi',
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: NotsColors.textMuted,
                ),
              ),
              onChanged: (_) {
                if (_passwordError != null) {
                  setState(() => _passwordError = null);
                }
              },
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
              child: Text(
                'Dengan mendaftar, kamu menyetujui ketentuan privasi data studi & notifikasi pengingat NOTS.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  height: 20 / 12,
                  color: NotsColors.tealText,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_generalError != null) ...[
              Center(
                child: Text(
                  _generalError!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: NotsColors.error,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            NotsPrimaryButton(
              label: 'Daftar Akun',
              background: NotsColors.primaryDark,
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sudah punya akun?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: NotsColors.tealText,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: Text(
                    'Masuk',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: NotsColors.primaryDark,
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

class _WelcomeNote extends StatelessWidget {
  const _WelcomeNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NotsColors.heroBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.coffee_outlined,
                size: 20, color: NotsColors.primaryDark),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tenang bareng NOTS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    height: 18 / 13,
                    fontWeight: FontWeight.w600,
                    color: NotsColors.textOnMint,
                  ),
                ),
                Text(
                  'Semua jadwal kuliah & tugas tersusun rapi.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    height: 16 / 12,
                    color: NotsColors.tealText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
