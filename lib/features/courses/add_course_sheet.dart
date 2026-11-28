import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../core/widgets/nots_buttons.dart';
import 'course_colors.dart';
import 'course_repository.dart';

/// Bottom sheet "Tambah Mata Kuliah". Mengembalikan `true` kalau tersimpan.
Future<bool?> showAddCourseSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Geser-untuk-tutup dimatikan supaya sheet tidak hilang saat menyimpan.
    enableDrag: false,
    backgroundColor: Colors.white,
    barrierColor: const Color(0x6630312E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
    ),
    builder: (_) => const _AddCourseSheet(),
  );
}

class _AddCourseSheet extends StatefulWidget {
  const _AddCourseSheet();

  @override
  State<_AddCourseSheet> createState() => _AddCourseSheetState();
}

class _AddCourseSheetState extends State<_AddCourseSheet> {
  final _repo = CourseRepository();
  final _name = TextEditingController();
  final _lecturer = TextEditingController();

  int _color = 0;
  bool _saving = false;
  String? _nameError;
  String? _saveError;

  @override
  void dispose() {
    _name.dispose();
    _lecturer.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Nama mata kuliah wajib diisi.');
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await _repo.create(
        name: name,
        lecturer: _lecturer.text.trim(),
        colorHex: courseColors[_color].hex,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = '$e';
      });
    }
  }

  void _close() {
    if (!_saving) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          32 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: NotsColors.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _header(),
            const SizedBox(height: 24),
            _label('Nama Mata Kuliah', _tag('Wajib')),
            const SizedBox(height: 6),
            _field(
              controller: _name,
              icon: Icons.book_outlined,
              hint: 'Contoh: Metodologi Penelitian',
              maxLength: 100,
              errorText: _nameError,
              action: TextInputAction.next,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: 16),
            _label(
              'Dosen Pengampu',
              Text(
                'Opsional',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  height: 16 / 12,
                  color: NotsColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            _field(
              controller: _lecturer,
              icon: Icons.badge_outlined,
              hint: 'Contoh: Dr. Rina Kartika',
              maxLength: 100,
              action: TextInputAction.done,
              onSubmitted: (_) => _save(),
              suffix: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _lecturer,
                builder: (context, value, _) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    tooltip: 'Hapus nama dosen',
                    onPressed: _lecturer.clear,
                    icon: const CircleAvatar(
                      radius: 14,
                      backgroundColor: NotsColors.buttonNeutral,
                      child: Icon(
                        Icons.highlight_off,
                        size: 16,
                        color: NotsColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            _label('Warna Label Catatan', _tag(courseColors[_color].label)),
            const SizedBox(height: 8),
            _colorPicker(),
            if (_saveError != null) ...[
              const SizedBox(height: 12),
              Text(
                _saveError!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: NotsColors.error,
                ),
              ),
            ],
            const SizedBox(height: 32),
            NotsPrimaryButton(
              label: 'Simpan',
              showArrow: false,
              loading: _saving,
              onPressed: _save,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 56,
              child: TextButton(
                onPressed: _saving ? null : _close,
                style: TextButton.styleFrom(
                  backgroundColor: NotsColors.segmentTrack,
                  foregroundColor: NotsColors.textPrimary,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'Batal',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tambah Mata Kuliah',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  height: 24 / 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.45,
                  color: NotsColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tambah rincian jadwal dan dosen pengampu kamu',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  height: 16 / 12,
                  color: NotsColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Tutup form',
          onPressed: _saving ? null : _close,
          style: IconButton.styleFrom(
            backgroundColor: NotsColors.surfaceMuted,
          ),
          icon: const Icon(
            Icons.close,
            size: 18,
            color: NotsColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _label(String text, Widget trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            height: 18 / 13,
            fontWeight: FontWeight.w600,
            color: NotsColors.textPrimary,
          ),
        ),
        trailing,
      ],
    );
  }

  Widget _tag(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        height: 14 / 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.22,
        color: NotsColors.primaryDark,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required int maxLength,
    required TextInputAction action,
    String? errorText,
    Widget? suffix,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    final style = GoogleFonts.plusJakartaSans(
      fontSize: 14,
      color: NotsColors.textPrimary,
    );
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color),
        );

    return TextField(
      controller: controller,
      enabled: !_saving,
      maxLength: maxLength,
      textCapitalization: TextCapitalization.words,
      textInputAction: action,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: style,
      cursorColor: NotsColors.primary,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        counterText: '',
        hintText: hint,
        hintStyle: style.copyWith(color: NotsColors.textMuted),
        errorText: errorText,
        prefixIcon: Icon(icon, size: 18, color: NotsColors.textSecondary),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: border(NotsColors.inputIcon),
        enabledBorder: border(NotsColors.inputIcon),
        disabledBorder: border(NotsColors.inputIcon),
        focusedBorder: border(NotsColors.primary),
        errorBorder: border(NotsColors.error),
        focusedErrorBorder: border(NotsColors.error),
      ),
    );
  }

  Widget _colorPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: NotsColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < courseColors.length; i++)
            Semantics(
              button: true,
              selected: i == _color,
              label: 'Warna ${courseColors[i].label}',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _saving ? null : () => setState(() => _color = i),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: courseColors[i].color,
                  child: i == _color
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
