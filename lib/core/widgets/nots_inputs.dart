import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme.dart';

/// Kolom isian kartu putih (layar Daftar): label di atas, error/helper di bawah.
class NotsFormField extends StatelessWidget {
  const NotsFormField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.errorText,
    this.helperText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.suffix,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    final textStyle = GoogleFonts.plusJakartaSans(
      fontSize: 16,
      height: 20 / 16,
      color: hasError ? NotsColors.error : NotsColors.textPrimary,
    );
    OutlineInputBorder border(Color? color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              color == null ? BorderSide.none : BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 18 / 13,
              fontWeight: FontWeight.w600,
              color: NotsColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onChanged: onChanged,
            style: textStyle,
            cursorColor: NotsColors.primary,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: hint,
              hintStyle: textStyle.copyWith(color: NotsColors.textMuted),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              suffixIcon: suffix ??
                  (hasError
                      ? const Icon(Icons.error_outline,
                          size: 18, color: NotsColors.error)
                      : null),
              border: border(null),
              enabledBorder: hasError ? border(NotsColors.error) : border(null),
              focusedBorder: border(hasError ? NotsColors.error : NotsColors.primary),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
            child: Text(
              errorText!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                height: 16 / 12,
                color: NotsColors.error,
              ),
            ),
          )
        else if (helperText != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
            child: Text(
              helperText!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                height: 16 / 12,
                color: NotsColors.textMuted,
              ),
            ),
          ),
      ],
    );
  }
}

/// Kolom isian bentuk pil abu muda (layar Masuk & Lupa kata sandi).
/// Kolom password otomatis dapat tombol mata, kolom lain dapat tombol hapus.
class NotsPillField extends StatefulWidget {
  const NotsPillField({
    super.key,
    required this.label,
    required this.controller,
    required this.leadingIcon,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.labelAction,
    this.labelWeight = FontWeight.w400,
    this.height = 44,
    this.leadingColor = NotsColors.textMuted,
    this.errorText,
  });

  final String label;
  final TextEditingController controller;
  final IconData leadingIcon;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? labelAction;
  final FontWeight labelWeight;
  final double height;
  final Color leadingColor;
  final String? errorText;

  @override
  State<NotsPillField> createState() => _NotsPillFieldState();
}

class _NotsPillFieldState extends State<NotsPillField> {
  late bool _obscured = widget.obscureText;

  Widget _trailing() {
    if (widget.obscureText) {
      return IconButton(
        tooltip: _obscured ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
        onPressed: () => setState(() => _obscured = !_obscured),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        icon: Icon(
          _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 18,
          color: NotsColors.textMuted,
        ),
      );
    }
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, _) {
        if (value.text.isEmpty) return const SizedBox.shrink();
        return IconButton(
          tooltip: 'Hapus',
          onPressed: () {
            widget.controller.clear();
            widget.onChanged?.call('');
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: const Icon(Icons.highlight_off,
              size: 16, color: NotsColors.textMuted),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.plusJakartaSans(
      fontSize: 14,
      height: 20 / 14,
      color: NotsColors.textPrimary,
    );
    final pill = OutlineInputBorder(
      borderRadius: BorderRadius.circular(32),
      borderSide: BorderSide.none,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                height: 18 / 13,
                fontWeight: widget.labelWeight,
                color: NotsColors.textPrimary,
              ),
            ),
            if (widget.labelAction != null) widget.labelAction!,
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          style: style,
          cursorColor: NotsColors.primary,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: NotsColors.surfaceMuted,
            hintText: widget.hint,
            hintStyle: style.copyWith(color: NotsColors.textMuted),
            contentPadding:
                EdgeInsets.symmetric(vertical: (widget.height - 20) / 2),
            prefixIcon:
                Icon(widget.leadingIcon, size: 16, color: widget.leadingColor),
            prefixIconConstraints:
                BoxConstraints(minWidth: 40, minHeight: widget.height),
            suffixIcon: _trailing(),
            suffixIconConstraints:
                BoxConstraints(minWidth: 40, minHeight: widget.height),
            border: pill,
            enabledBorder: pill,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
              borderSide:
                  const BorderSide(color: NotsColors.primary, width: 1.5),
            ),
          ),
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Text(
              widget.errorText!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                height: 16 / 12,
                color: NotsColors.error,
              ),
            ),
          ),
      ],
    );
  }
}
