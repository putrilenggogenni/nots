import 'dart:async';
import 'dart:math' as math;

import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/theme.dart';
import 'capture_parser.dart';

/// Isi tab "Suara" di layar Tangkap: rekam, ubah jadi teks, lalu tampilkan
/// tanggal, jam, kegiatan, dan lokasi yang terdeteksi. Teks hasil rekaman
/// disimpan di [controller] supaya bisa diedit dan dianalisis CaptureScreen.
class VoiceCaptureCard extends StatefulWidget {
  const VoiceCaptureCard({
    super.key,
    required this.controller,
    required this.parsed,
  });

  final TextEditingController controller;
  final ParsedCapture parsed;

  @override
  State<VoiceCaptureCard> createState() => _VoiceCaptureCardState();
}

class _VoiceCaptureCardState extends State<VoiceCaptureCard> {
  static const _barCount = 28;

  final _speech = SpeechToText();
  final _rng = math.Random();

  bool _ready = false;
  bool _listening = false;
  String _localeId = 'id_ID';
  String? _error;
  int _seconds = 0;
  Timer? _clock;
  Timer? _wave;
  List<double> _bars = List<double>.filled(_barCount, 6.0);

  @override
  void initState() {
    super.initState();
    if (widget.controller.text.trim().isNotEmpty) {
      _bars = _randomBars();
    }
  }

  @override
  void dispose() {
    _clock?.cancel();
    _wave?.cancel();
    _speech.cancel();
    super.dispose();
  }

  List<double> _randomBars() {
    return List<double>.generate(_barCount, (i) {
      final envelope = math.sin(math.pi * (i + 0.5) / _barCount);
      return 6.0 + envelope * _rng.nextDouble() * 34;
    });
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _stop();
    } else {
      await _start();
    }
  }

  Future<void> _start() async {
    setState(() => _error = null);

    if (!_ready) {
      try {
        _ready = await _speech.initialize(
          onStatus: _onStatus,
          onError: _onError,
        );
      } catch (_) {
        _ready = false;
      }
      if (!mounted) return;
      if (!_ready) {
        setState(() {
          _error =
              'Pengenalan suara tidak tersedia di sini. Pakai Chrome dan izinkan mikrofon, atau ketik di tab Teks.';
        });
        return;
      }
      try {
        final locales = await _speech.locales();
        final id =
            locales.where((l) => l.localeId.toLowerCase().startsWith('id'));
        if (id.isNotEmpty) _localeId = id.first.localeId;
      } catch (_) {
        // tetap pakai bawaan 'id_ID'
      }
    }

    if (!mounted) return;
    widget.controller.clear();
    _seconds = 0;

    await _speech.listen(
      onResult: _onResult,
      listenOptions: SpeechListenOptions(
        localeId: _localeId,
        listenFor: const Duration(seconds: 90),
        pauseFor: const Duration(seconds: 8),
      ),
    );

    _startTimers();
    if (!mounted) return;
    setState(() => _listening = true);
  }

  Future<void> _stop() async {
    await _speech.stop();
    _finish();
  }

  void _onStatus(String status) {
    if (status == 'notListening' || status == 'done') {
      _finish();
    }
  }

  void _onError(SpeechRecognitionError e) {
    _finish();
    if (!mounted) return;
    setState(() => _error = _friendlyError(e.errorMsg));
  }

  void _onResult(SpeechRecognitionResult r) {
    final text = r.recognizedWords.trim();
    if (text.isEmpty) return;
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _startTimers() {
    _clock?.cancel();
    _wave?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds++);
    });
    _wave = Timer.periodic(const Duration(milliseconds: 140), (_) {
      if (!mounted) return;
      setState(() => _bars = _randomBars());
    });
  }

  void _finish() {
    _clock?.cancel();
    _wave?.cancel();
    if (!mounted) return;
    setState(() {
      _listening = false;
      if (widget.controller.text.trim().isEmpty) {
        _bars = List<double>.filled(_barCount, 6.0);
      }
    });
  }

  String get _clockLabel {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final raw = widget.controller.text;
    final hasText = raw.trim().isNotEmpty;
    final spoken = normalizeSpokenNumbers(raw);
    final date = widget.parsed.date;
    final time = widget.parsed.time;
    final item = _findItem(spoken);
    final place = _findLocation(spoken);
    final hasEntities =
        date != null || time != null || item != null || place != null;
    final cardTop = NotsColors.mint50;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _micCard(hasText, cardTop),
        const SizedBox(height: 16),
        _transcriptCard(hasText, date),
        if (hasEntities) ...[
          const SizedBox(height: 16),
          _entitiesCard(widget.parsed, item, place),
        ],
      ],
    );
  }

  Widget _micCard(bool hasText, Color top) {
    final hint = _listening
        ? 'Ucapkan tugasmu dengan jelas. Ketuk lagi untuk berhenti.'
        : hasText
            ? 'Ketuk mikrofon untuk merekam ulang'
            : 'Ketuk mikrofon, lalu ucapkan tugasmu';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _listening ? NotsColors.mint60 : Colors.transparent,
            ),
            child: Material(
              color: _listening ? NotsColors.primaryDark : NotsColors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _toggle,
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Icon(
                    _listening ? Icons.stop : Icons.mic,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _statusChip(hasText),
          const SizedBox(height: 6),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              height: 16 / 12,
              color: NotsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (var i = 0; i < _bars.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 3,
                    height: _bars[i],
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: (_listening || hasText)
                          ? (i.isEven
                              ? NotsColors.primary
                              : NotsColors.primaryDark)
                          : NotsColors.mint60,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                height: 16 / 12,
                color: NotsColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(bool hasText) {
    if (!_listening && !hasText) return const SizedBox.shrink();
    final label = _listening ? 'Rekaman aktif' : 'Rekaman selesai';
    final suffix = _seconds > 0 ? ' · $_clockLabel' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: NotsColors.mint60,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _listening ? NotsColors.error : NotsColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label$suffix',
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

  Widget _transcriptCard(bool hasText, DateTime? date) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide.none,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.record_voice_over_outlined,
                size: 18,
                color: NotsColors.primaryDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hasil Transkripsi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    height: 20 / 15,
                    fontWeight: FontWeight.w600,
                    color: NotsColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.edit_outlined,
                size: 13,
                color: NotsColors.primaryDark,
              ),
              const SizedBox(width: 4),
              Text(
                'DAPAT DIEDIT',
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
          const SizedBox(height: 12),
          TextField(
            controller: widget.controller,
            minLines: 3,
            maxLines: null,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              height: 24 / 15,
              color: NotsColors.textPrimary,
            ),
            cursorColor: NotsColors.primary,
            decoration: InputDecoration(
              filled: true,
              fillColor: NotsColors.buttonNeutral,
              hintText: 'Hasil rekaman akan muncul di sini…',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                height: 24 / 15,
                color: NotsColors.textMuted,
              ),
              contentPadding: const EdgeInsets.all(16),
              border: border,
              enabledBorder: border,
              focusedBorder: border,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.info_outline,
                  size: 14,
                  color: NotsColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kamu bisa edit teks langsung jika ada nama dosen atau istilah yang salah dengar.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    height: 16 / 11,
                    color: NotsColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (hasText && date == null) ...[
            const SizedBox(height: 8),
            Text(
              'Tanggal belum terdeteksi. Coba sebut, misalnya, "besok jam 9 pagi".',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                height: 16 / 11,
                color: NotsColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _entitiesCard(
    ParsedCapture parsed,
    String? item,
    String? place,
  ) {
    final date = parsed.date;
    final time = parsed.time;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'ENTITAS TERDETEKSI OTOMATIS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    height: 14 / 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.55,
                    color: NotsColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Tersinkronisasi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  height: 14 / 11,
                  fontWeight: FontWeight.w600,
                  color: NotsColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (date != null)
                _VoiceChip(
                  icon: Icons.event_outlined,
                  label: formatDateChip(date),
                ),
              if (time != null)
                _VoiceChip(
                  icon: Icons.schedule,
                  label: formatTimeChip(time),
                ),
              if (item != null)
                _VoiceChip(icon: Icons.school_outlined, label: item),
              if (place != null)
                _VoiceChip(
                  icon: Icons.place_outlined,
                  label: place,
                  neutral: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoiceChip extends StatelessWidget {
  const _VoiceChip({
    required this.icon,
    required this.label,
    this.neutral = false,
  });

  final IconData icon;
  final String label;
  final bool neutral;

  @override
  Widget build(BuildContext context) {
    final fg = neutral ? NotsColors.textSecondary : NotsColors.mintText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: neutral ? NotsColors.buttonNeutral : NotsColors.mint60,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              height: 14 / 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.22,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bantuan untuk teks hasil ucapan
// ---------------------------------------------------------------------------

const Map<String, int> _numberWords = {
  'satu': 1,
  'dua': 2,
  'tiga': 3,
  'empat': 4,
  'lima': 5,
  'enam': 6,
  'tujuh': 7,
  'delapan': 8,
  'sembilan': 9,
  'sepuluh': 10,
  'sebelas': 11,
  'dua belas': 12,
};

/// Mengubah angka yang diucapkan setelah kata kunci jadi digit, supaya bisa
/// dibaca CaptureParser: "jam sembilan" jadi "jam 9", "lab dua" jadi "lab 2".
String normalizeSpokenNumbers(String text) {
  return text.replaceAllMapped(
    RegExp(
      r'\b(jam|pukul|pkl|lab|laboratorium|ruang|ruangan|bab)\s+(dua belas|sepuluh|sebelas|satu|dua|tiga|empat|lima|enam|tujuh|delapan|sembilan)\b',
      caseSensitive: false,
    ),
    (m) => '${m[1]} ${_numberWords[m[2]!.toLowerCase()]}',
  );
}

const Set<String> _itemKeywords = {
  'kuis',
  'quiz',
  'ujian',
  'uts',
  'uas',
  'laporan',
  'praktikum',
  'presentasi',
  'proposal',
};

const Set<String> _stopWords = {
  'jam', 'pukul', 'pkl', 'di', 'ke', 'besok', 'lusa', 'hari', 'ini', 'ya',
  'yang', 'dan', 'untuk', 'bawa', 'dibawa', 'pagi', 'siang', 'sore', 'malam',
  'jangan', 'lupa', 'kapan', 'dikumpulkan', 'dikumpul', 'akan', 'diadakan',
  'ada', 'senin', 'selasa', 'rabu', 'kamis', 'jumat', 'sabtu', 'minggu',
  'lab', 'ruang', 'ruangan', 'gedung', 'paling', 'lambat',
};

String _capWords(String s) {
  return s
      .trim()
      .split(RegExp(r'\s+'))
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

/// Nama kegiatan sederhana, misalnya "Kuis Struktur Data".
String? _findItem(String text) {
  final words = text.split(RegExp(r'\s+'));
  for (var i = 0; i < words.length; i++) {
    final key = words[i].toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (!_itemKeywords.contains(key)) continue;
    final picked = <String>[_capWords(key)];
    for (var j = i + 1; j < words.length && picked.length < 5; j++) {
      final next = words[j].replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
      if (next.isEmpty) break;
      if (_stopWords.contains(next.toLowerCase())) break;
      if (RegExp(r'^\d').hasMatch(next)) break;
      picked.add(_capWords(next));
    }
    if (picked.length >= 2) return picked.join(' ');
  }
  return null;
}

/// Lokasi sederhana: "Lab 2", "Ruang 302", "Gedung C".
String? _findLocation(String text) {
  final lab = RegExp(
    r'\blab(?:oratorium)?\s+[A-Za-z]?\d+[A-Za-z]?\b',
    caseSensitive: false,
  ).firstMatch(text);
  if (lab != null) return _capWords(lab.group(0)!);

  final room = RegExp(
    r'\b(?:ruang(?:an)?|gedung)\s+(?!lab\b)[A-Za-z0-9.\-]+',
    caseSensitive: false,
  ).firstMatch(text);
  if (room != null) return _capWords(room.group(0)!);
  return null;
}

String _friendlyError(String msg) {
  final m = msg.toLowerCase();
  if (m.contains('permission') ||
      m.contains('not-allowed') ||
      m.contains('not_allowed')) {
    return 'Izin mikrofon ditolak. Klik ikon gembok di address bar Chrome, izinkan mikrofon, lalu coba lagi.';
  }
  if (m.contains('no_match') ||
      m.contains('no-speech') ||
      m.contains('speech_timeout')) {
    return 'Suara belum terdengar. Coba bicara lebih dekat ke mikrofon.';
  }
  if (m.contains('network')) {
    return 'Pengenalan suara butuh koneksi internet.';
  }
  if (m.contains('audio-capture') || m.contains('audio_capture')) {
    return 'Mikrofon tidak terdeteksi. Periksa mikrofon laptopmu.';
  }
  return 'Gagal merekam ($msg). Coba lagi atau ketik di tab Teks.';
}