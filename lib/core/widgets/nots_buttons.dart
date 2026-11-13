import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme.dart';

class _NotsButton extends StatelessWidget {
  const _NotsButton({
    required this.label,
    required this.onPressed,
    required this.background,
    required this.foreground,
    this.showArrow = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (showArrow) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 14),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tombol hijau tua, contoh: "Daftar Akun Baru →".
class NotsPrimaryButton extends StatelessWidget {
  const NotsPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.showArrow = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return _NotsButton(
      label: label,
      onPressed: onPressed,
      background: NotsColors.primary,
      foreground: Colors.white,
      showArrow: showArrow,
    );
  }
}

/// Tombol mint, contoh: "Sudah Punya Akun? Masuk".
class NotsSecondaryButton extends StatelessWidget {
  const NotsSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return _NotsButton(
      label: label,
      onPressed: onPressed,
      background: NotsColors.mint,
      foreground: NotsColors.mintText,
    );
  }
}