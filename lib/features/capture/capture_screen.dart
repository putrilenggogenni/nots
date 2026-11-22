import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../core/widgets/nots_buttons.dart';
import '../../core/widgets/nots_common.dart';
import '../../core/widgets/nots_inputs.dart';
import '../tasks/task_repository.dart';
import 'capture_parser.dart';
import 'voice_capture_card.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key, this.initialText});

  final String? initialText;

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _textController = TextEditingController();
  final _voiceController = TextEditingController();
  String _source = 'manual';
  ParsedCapture _parsed = const ParsedCapture();
  int _selectedTab = 0;

  // Kolom teks di tab yang sedang aktif (Teks atau Suara).
  TextEditingController get _active =>
      _selectedTab == 2 ? _voiceController : _textController;

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null) {
      _textController.text = widget.initialText!;
      _source = 'clipboard';
    }
    _parsed = CaptureParser().parse(_textController.text);
    _textController.addListener(_onTextChanged);
    _voiceController.addListener(_onVoiceChanged);
  }

  void _onTextChanged() {
    if (!mounted) return;
    setState(() {
      _parsed = CaptureParser().parse(_textController.text);
    });
  }

  void _onVoiceChanged() {
    if (!mounted) return;
    setState(() {
      _parsed = CaptureParser()
          .parse(normalizeSpokenNumbers(_voiceController.text));
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _voiceController.dispose();
    super.dispose();
  }

  bool get _hasText => _active.text.trim().isNotEmpty;

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (!mounted) return;
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clipboard kosong.')),
      );
      return;
    }
    _textController.text = text;
    _textController.selection =
        TextSelection.collapsed(offset: text.length);
    setState(() {
      _source = 'clipboard';
    });
  }

  void _onTabTap(int index) {
    if (index == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Segera hadir.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedTab = index;
      _parsed = index == 2
          ? CaptureParser()
              .parse(normalizeSpokenNumbers(_voiceController.text))
          : CaptureParser().parse(_textController.text);
    });
  }

  void _analyze() {
    FocusScope.of(context).unfocus();
    final text = _active.text;
    final parsed = _parsed;
    final source = _selectedTab == 2 ? 'voice' : _source;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: _ResultSheet(
            text: text,
            source: source,
            parsed: parsed,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NotsBackAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ada tugas apa?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      height: 28 / 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.55,
                      color: NotsColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tempel pesan tugasmu. Kami bantu temukan tanggal dan jamnya.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      height: 20 / 14,
                      color: NotsColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SegmentedControl(
                    selected: _selectedTab,
                    onTap: _onTabTap,
                  ),
                  const SizedBox(height: 20),
                  if (_selectedTab == 2) ...[
                    VoiceCaptureCard(
                      controller: _voiceController,
                      parsed: _parsed,
                    ),
                    const SizedBox(height: 20),
                    _AutoDetectCard(),
                  ] else ...[
                    _InputCard(
                      controller: _textController,
                      charCount: _textController.text.length,
                      parsed: _parsed,
                      onPaste: _pasteFromClipboard,
                    ),
                    const SizedBox(height: 20),
                    _TipsCard(),
                    const SizedBox(height: 20),
                    _AutoDetectCard(),
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: _hasText ? 1.0 : 0.5,
                    child: NotsPrimaryButton(
                      label: 'Analisis Catatan',
                      leadingIcon: Icons.auto_awesome,
                      trailingIcon: Icons.arrow_forward,
                      onPressed: _hasText ? _analyze : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedTab == 2
                        ? 'Suara diubah jadi teks oleh layanan pengenalan suara browser'
                        : 'Dianalisis secara lokal & aman di perangkatmu',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      height: 14 / 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.22,
                      color: NotsColors.captionMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({required this.selected, required this.onTap});

  final int selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (Icons.notes, 'Teks', 14.0),
      (Icons.photo_camera_outlined, 'Foto', 15.0),
      (Icons.mic_none, 'Suara', 14.0),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: NotsColors.segmentTrack,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: 0),
            Expanded(
              child: _Tab(
                icon: tabs[i].$1,
                label: tabs[i].$2,
                iconSize: tabs[i].$3,
                selected: selected == i,
                onTap: () => onTap(i),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.iconSize,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final double iconSize;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? NotsColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      elevation: selected ? 0 : 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? NotsColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 1,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: iconSize,
                color: selected ? Colors.white : NotsColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : NotsColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Note: spec says selected tab bg #176B5D = primary, yes.

class _InputCard extends StatefulWidget {
  const _InputCard({
    required this.controller,
    required this.charCount,
    required this.parsed,
    required this.onPaste,
  });

  final TextEditingController controller;
  final int charCount;
  final ParsedCapture parsed;
  final VoidCallback onPaste;

  @override
  State<_InputCard> createState() => _InputCardState();
}

class _InputCardState extends State<_InputCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: NotsColors.primaryDark,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
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
                          'TEKS SUMBER',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            height: 14 / 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.55,
                            color: NotsColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: NotsColors.buttonNeutral,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.keyboard_alt_outlined,
                              size: 11, color: NotsColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.charCount} karakter',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              height: 14 / 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.22,
                              color: NotsColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: widget.controller,
                  minLines: 4,
                  maxLines: null,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    height: 26 / 16,
                    color: NotsColors.textPrimary,
                  ),
                  cursorColor: NotsColors.primary,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Tempel atau ketik pesan tugasmu di sini…',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      height: 26 / 16,
                      color: NotsColors.textMuted,
                    ),
                  ),
                ),
                if (widget.parsed.date != null ||
                    widget.parsed.time != null) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (widget.parsed.date != null)
                        _DetectionChip(
                          icon: Icons.event_outlined,
                          label: formatDateChip(widget.parsed.date!),
                        ),
                      if (widget.parsed.time != null)
                        _DetectionChip(
                          icon: Icons.schedule,
                          label: formatTimeChip(widget.parsed.time!),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: Material(
                    color: NotsColors.mint70,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: widget.onPaste,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.content_paste,
                              size: 14, color: NotsColors.primaryDark),
                          const SizedBox(width: 8),
                          Text(
                            'Tempel dari clipboard',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              height: 18 / 13,
                              fontWeight: FontWeight.w600,
                              color: NotsColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
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
}

class _DetectionChip extends StatelessWidget {
  const _DetectionChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: NotsColors.mint60,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: NotsColors.mintText),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              height: 14 / 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.22,
              color: NotsColors.mintText,
            ),
          ),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NotsColors.mint50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(Icons.lightbulb_outline,
                size: 16, color: NotsColors.primaryDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips Mahasiswa',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    height: 18 / 13,
                    fontWeight: FontWeight.w600,
                    color: NotsColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tugasnya ada di WhatsApp? Salin pesannya, lalu tempel di sini. NOTS akan langsung menjadwalkannya.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    height: 19.5 / 12,
                    color: NotsColors.mintText,
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

class _AutoDetectCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NotsColors.buttonNeutral,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome,
                    size: 13, color: NotsColors.primaryDark),
              ),
              const SizedBox(width: 10),
              Text(
                'Auto-deteksi mata kuliah & deadline',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  height: 14 / 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.22,
                  color: NotsColors.textSecondary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                'Aktif',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  height: 14 / 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.22,
                  color: NotsColors.primaryDark,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.check_circle_outline,
                  size: 12, color: NotsColors.primaryDark),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultSheet extends StatefulWidget {
  const _ResultSheet({
    required this.text,
    required this.source,
    required this.parsed,
  });

  final String text;
  final String source;
  final ParsedCapture parsed;

  @override
  State<_ResultSheet> createState() => _ResultSheetState();
}

class _ResultSheetState extends State<_ResultSheet> {
  final _titleController = TextEditingController();
  final _repo = TaskRepository();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleController.text = suggestTitle(widget.text);
    _titleController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _titleController.text.trim().isNotEmpty && !_saving;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    DateTime? dueAt;
    if (widget.parsed.date != null) {
      final t = widget.parsed.time;
      final hour = t?.hour ?? 23;
      final minute = t?.minute ?? 59;
      dueAt = DateTime(
        widget.parsed.date!.year,
        widget.parsed.date!.month,
        widget.parsed.date!.day,
        hour,
        minute,
      );
    }

    try {
      await _repo.createTask(
        title: _titleController.text.trim(),
        dueAt: dueAt,
        rawText: widget.text,
        source: widget.source,
      );
      if (!mounted) return;
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      navigator.pop(); // close sheet
      navigator.pop(); // back to previous (Home)
      messenger.showSnackBar(
        const SnackBar(content: Text('Tugas tersimpan.')),
      );
    } on TaskFailure catch (e) {
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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hasil sementara',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  height: 24 / 18,
                  fontWeight: FontWeight.w700,
                  color: NotsColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              NotsFormField(
                label: 'Judul tugas',
                controller: _titleController,
                hint: 'Judul tugas',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              if (widget.parsed.date != null || widget.parsed.time != null)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (widget.parsed.date != null)
                      _DetectionChip(
                        icon: Icons.event_outlined,
                        label: formatDateChip(widget.parsed.date!),
                      ),
                    if (widget.parsed.time != null)
                      _DetectionChip(
                        icon: Icons.schedule,
                        label: formatTimeChip(widget.parsed.time!),
                      ),
                  ],
                )
              else
                Text(
                  'Tanggal belum terdeteksi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    height: 16 / 12,
                    color: NotsColors.textMuted,
                  ),
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
              const SizedBox(height: 16),
              Opacity(
                opacity: _canSave ? 1.0 : 0.5,
                child: NotsPrimaryButton(
                  label: 'Simpan tugas',
                  onPressed: _canSave ? _save : null,
                  loading: _saving,
                  showArrow: false,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Layar konfirmasi menyusul.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    height: 14 / 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.22,
                    color: NotsColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}