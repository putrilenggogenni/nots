import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme.dart';

class _NotsButton extends StatelessWidget {
  const _NotsButton({
    required this.label,
    required this.onPressed,
    required this.background,
    required this.foreground,
    this.leadingIcon,
    this.trailingIcon,
    this.height = 56,
    this.fontSize = 15,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double height;
  final double fontSize;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background,
          disabledForegroundColor: foreground,
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foreground,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 8),
                    Icon(trailingIcon, size: 14),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Tombol hijau berbentuk pil. Warna & tinggi bisa disesuaikan per layar.
class NotsPrimaryButton extends StatelessWidget {
  const NotsPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.showArrow = true,
    this.trailingIcon = Icons.arrow_forward,
    this.leadingIcon,
    this.background = NotsColors.primary,
    this.height = 56,
    this.fontSize = 15,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool showArrow;
  final IconData trailingIcon;
  final IconData? leadingIcon;
  final Color background;
  final double height;
  final double fontSize;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return _NotsButton(
      label: label,
      onPressed: onPressed,
      background: background,
      foreground: Colors.white,
      leadingIcon: leadingIcon,
      trailingIcon: showArrow ? trailingIcon : null,
      height: height,
      fontSize: fontSize,
      loading: loading,
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
