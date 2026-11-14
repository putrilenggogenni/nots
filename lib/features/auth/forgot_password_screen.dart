import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../core/widgets/nots_buttons.dart';
import '../../core/widgets/nots_common.dart';
import '../../core/widgets/nots_inputs.dart';
import 'auth_service.dart';

/// Layar "Pemulihan - Lupa Kata Sandi".
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  String? _emailError;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!isValidEmail(_email.text)) {
      setState(() => _emailError = 'Format email belum benar.');
      return;
    }

    setState(() {
      _loading = true;
      _emailError = null;
    });
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await _auth.sendPasswordReset(_email.text.trim());
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(
        content: Text('Jika email terdaftar, tautan atur ulang sudah dikirim.'),
      ));
      nav.pop();
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _emailError = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NotsBackAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          children: [
            const _RecoveryBadge(),
            const SizedBox(height: 16),
            Text(
              'Atur ulang kata sandi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                height: 24 / 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
                color: NotsColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                'Masukkan email yang kamu pakai untuk mendaftar. Kami akan mengirimkan tautan untuk membuat kata sandi baru.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  height: 23 / 14,
                  color: NotsColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 24),
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
                    labelWeight: FontWeight.w600,
                    controller: _email,
                    hint: 'nama@email.com',
                    leadingIcon: Icons.mail,
                    leadingColor: NotsColors.primaryDark,
                    height: 52,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    errorText: _emailError,
                    onSubmitted: (_) => _submit(),
                    onChanged: (_) {
                      if (_emailError != null) {
                        setState(() => _emailError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  NotsPrimaryButton(
                    label: 'Kirim Tautan Atur Ulang',
                    background: NotsColors.primaryDark,
                    trailingIcon: Icons.send,
                    height: 48,
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
                  'Ingat kata sandi?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: NotsColors.textSecondary,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(
                    'Masuk sekarang',
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

class _RecoveryBadge extends StatelessWidget {
  const _RecoveryBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0x80C1E8DC),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.lock_reset,
                    size: 30, color: NotsColors.primaryDark),
              ),
            ),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: NotsColors.primaryDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.vpn_key, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
