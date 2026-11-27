import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../core/widgets/nots_buttons.dart';
import 'profile_repository.dart';

class EditNameSheet extends StatefulWidget {
  const EditNameSheet({
    super.key,
    required this.initialName,
    this.onSaved,
  });

  final String initialName;
  final ValueChanged<String>? onSaved;

  @override
  State<EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends State<EditNameSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialName);
  final _repo = ProfileRepository();
  bool _saving = false;
  String? _error;
  String? _validation;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {
      _validate(_controller.text);
    });
  }

  void _validate(String value) {
    final t = value.trim();
    if (t.isEmpty) {
      _validation = 'Nama minimal 2 karakter.';
    } else if (t.length < 2) {
      _validation = 'Nama minimal 2 karakter.';
    } else if (t.length > 50) {
      _validation = 'Nama maksimal 50 karakter.';
    } else {
      _validation = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSave {
    final t = _controller.text.trim();
    if (t.length < 2 || t.length > 50) return false;
    if (_saving) return false;
    return true;
  }

  Future<void> _save() async {
    final trimmed = _controller.text.trim();
    if (trimmed == widget.initialName.trim()) {
      Navigator.of(context).pop();
      return;
    }
    _validate(_controller.text);
    if (_validation != null) {
      setState(() {});
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repo.updateName(trimmed);
      if (!mounted) return;
      widget.onSaved?.call(trimmed);
      Navigator.of(context).pop();
    } on ProfileFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Tidak bisa terhubung. Cek koneksi internetmu.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: NotsColors.mint100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.edit_note,
                      size: 24,
                      color: NotsColors.primaryDark,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: NotsColors.segmentTrack,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: NotsColors.primaryDark,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Akun Mahasiswa',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            height: 14 / 11,
                            fontWeight: FontWeight.w600,
                            color: NotsColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Ubah nama',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  height: 28 / 22,
                  fontWeight: FontWeight.w700,
                  color: NotsColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Perbarui nama tampilan akun NOTS kamu agar mudah dikenali rekan kelompok belajar.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 19 / 13,
                  color: NotsColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'NAMA LENGKAP',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  height: 14 / 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.55,
                  color: NotsColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: NotsColors.buttonNeutral,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => _save(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: NotsColors.textPrimary,
                  ),
                  cursorColor: NotsColors.primary,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _controller,
                      builder: (context, value, _) {
                        if (value.text.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return IconButton(
                          tooltip: 'Hapus',
                          onPressed: () => _controller.clear(),
                          icon: const Icon(
                            Icons.cancel_outlined,
                            size: 20,
                            color: NotsColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              if (_validation != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _validation!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      height: 16 / 12,
                      color: NotsColors.error,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 12,
                    color: NotsColors.primaryDark,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Nama ini akan muncul pada kartu tugas dan jadwal',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        height: 16 / 12,
                        color: NotsColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    height: 16 / 12,
                    color: NotsColors.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: Material(
                        color: NotsColors.divider,
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: _saving
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Center(
                            child: Text(
                              'Batal',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                height: 20 / 15,
                                fontWeight: FontWeight.w600,
                                color: NotsColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NotsPrimaryButton(
                      label: 'Simpan',
                      onPressed: _canSave ? _save : null,
                      loading: _saving,
                      showArrow: false,
                      background: NotsColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
