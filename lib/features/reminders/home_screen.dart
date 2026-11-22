import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../core/widgets/nots_buttons.dart';
import '../auth/auth_service.dart';
import '../capture/capture_screen.dart';
import '../tasks/task_model.dart';
import '../tasks/task_repository.dart';
import 'task_detail_screen.dart';

/// Layar "Pengingat" (halaman awal setelah login).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _filters = ['Hari ini', 'Besok', '7 hari', 'Semua'];
  static const _days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];
  static const _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  final _auth = AuthService();
  final _repo = TaskRepository();
  int _filter = 3; // Semua
  late Future<List<Task>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchAll();
  }

  void _reload() {
    setState(() => _future = _repo.fetchAll());
  }

  String get _dateLabel {
    final now = DateTime.now();
    return '${_days[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]} ${now.year}';
  }

  void _openCapture({String? initialText}) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => CaptureScreen(initialText: initialText),
          ),
        )
        .then((_) {
          if (mounted) _reload();
        });
  }

  Future<void> _toggleDone(Task t) async {
    try {
      await _repo.setDone(t.id, !t.isDone);
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _openDetail(Task t) async {
    final changed = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => TaskDetailScreen(task: t)));
    if (changed == true) _reload();
  }

  Future<void> _confirmDelete(Task t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus pengingat?'),
        content: Text('"${t.title}" akan dihapus dan tidak bisa dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.deleteTask(t.id);
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!mounted) return;
    if (text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Clipboard kosong.')));
      return;
    }
    _openCapture(initialText: text);
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Keluar'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await _auth.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _auth.firstName ?? 'kamu';

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: NotsColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'NOTS',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            height: 24 / 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.45,
            color: NotsColors.primaryDark,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _dateLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                  color: NotsColors.dateText,
                ),
              ),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Halo, '),
                    TextSpan(
                      text: '$name.',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 30,
                  height: 38 / 30,
                  letterSpacing: -0.75,
                  color: NotsColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Siap menata jadwal kuliah dan tugasmu hari ini?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  height: 16 / 12,
                  color: NotsColors.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              _SearchBar(),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    for (var i = 0; i < _filters.length; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      _FilterChip(
                        label: _filters[i],
                        selected: i == _filter,
                        onTap: () => setState(() => _filter = i),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FutureBuilder<List<Task>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text('${snap.error}')),
                    );
                  }
                  final tasks = snap.data ?? [];
                  if (tasks.isEmpty) {
                    return Column(
                      children: [
                        const _EmptyStateCard(),
                        const SizedBox(height: 24),
                        _PasteHintCard(onPaste: _paste),
                        const SizedBox(height: 24),
                        NotsPrimaryButton(
                          label: 'Tangkap tugas pertamamu',
                          leadingIcon: Icons.add_task,
                          trailingIcon: Icons.arrow_forward,
                          onPressed: () => _openCapture(),
                        ),
                      ],
                    );
                  }
                  final active = tasks.where((t) => !t.isDone).length;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProgressCard(tasks: tasks),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Daftar Pengingat',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: NotsColors.textPrimary,
                            ),
                          ),
                          Text(
                            '$active Aktif',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: NotsColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      for (final t in tasks)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TaskCard(
                            task: t,
                            onTap: () => _openDetail(t),
                            onToggle: () => _toggleDone(t),
                            onEdit: () => _openDetail(t),
                            onDelete: () => _confirmDelete(t),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        onCreate: () => _openCapture(),
        onSettings: _openSettings,
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.plusJakartaSans(
      fontSize: 14,
      color: NotsColors.textPrimary,
    );
    return Container(
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
        style: style,
        cursorColor: NotsColors.primary,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: 'Cari tugas atau mata kuliah...',
          hintStyle: style.copyWith(color: NotsColors.textMuted),
          prefixIcon: const Icon(
            Icons.search,
            size: 18,
            color: NotsColors.textMuted,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? NotsColors.mint : NotsColors.surfaceMuted,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: NotsColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? NotsColors.primary
                      : NotsColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = tasks.where((t) {
      final d = t.dueAt;
      return d != null &&
          d.year == now.year &&
          d.month == now.month &&
          d.day == now.day;
    }).toList();
    final done = today.where((t) => t.isDone).length;
    final percent = today.isEmpty ? 0 : (done * 100 / today.length).round();
    final text = today.isEmpty
        ? 'Belum ada tugas hari ini'
        : '$done dari ${today.length} tugas selesai';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NotsColors.mint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: NotsColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progres Hari Ini',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: NotsColors.primaryDark,
                  ),
                ),
                Text(
                  text,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: NotsColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$percent%',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: NotsColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onTap,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const _mon = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  String _dueLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = day.difference(today).inDays;
    final time =
        '${d.hour.toString().padLeft(2, '0')}.${d.minute.toString().padLeft(2, '0')} WIB';
    if (diff == 0) return 'Hari ini, $time';
    if (diff == 1) return 'Besok, $time';
    return '${d.day} ${_mon[d.month - 1]} ${d.year}, $time';
  }

  /// Label kecil di pojok kanan atas kartu.
  String? get _badge {
    if (task.isDone) return 'Selesai';
    final now = DateTime.now();
    final d = task.dueAt;
    if (d != null) {
      final left = d.difference(now);
      if (!left.isNegative && left.inHours < 3) return 'Tenggat Dekat';
    }
    final c = task.createdAt;
    if (c != null && now.difference(c).inHours < 24) return 'Baru';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final d = task.dueAt;
    final urgent =
        !task.isDone && d != null && d.difference(DateTime.now()).inHours < 3;
    final badge = _badge;
    final isNew = badge == 'Baru';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: onToggle,
                    child: Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: task.isDone
                            ? NotsColors.primary
                            : NotsColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: task.isDone
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            height: 24 / 18,
                            fontWeight: FontWeight.w600,
                            color: NotsColors.textPrimary,
                            decoration: task.isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          task.courseName ?? 'Tanpa mata kuliah',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: NotsColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (badge != null)
                    Container(
                      margin: const EdgeInsets.only(left: 8, right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isNew
                            ? NotsColors.mint
                            : NotsColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isNew
                              ? NotsColors.primaryDark
                              : NotsColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const SizedBox(width: 34),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: urgent
                          ? const Color(0xFFFFE9E9)
                          : NotsColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: urgent
                              ? const Color(0xFFC00000)
                              : NotsColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          d == null ? 'Tanpa tenggat' : _dueLabel(d),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: urgent
                                ? const Color(0xFFC00000)
                                : NotsColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (task.rawText != null)
                    const Icon(
                      Icons.attach_file,
                      size: 18,
                      color: NotsColors.textSecondary,
                    ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      size: 20,
                      color: NotsColors.textPrimary,
                    ),
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Ubah')),
                      PopupMenuItem(value: 'delete', child: Text('Hapus')),
                    ],
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

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          const _EmptyIllustration(),
          const SizedBox(height: 16),
          Text(
            'Belum ada pengingat',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              height: 24 / 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.45,
              color: NotsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 270),
            child: Text(
              'Tempel pesan tugasmu, NOTS bantu jadwalkan otomatis.',
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xB3F5F3EE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  size: 20,
                  color: NotsColors.primaryDark,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tips Mahasiswa Santai',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          height: 14 / 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.22,
                          color: NotsColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Salin teks WhatsApp dosen atau grup kelas, lalu jadikan jadwal sekali klik.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          height: 15 / 12,
                          color: NotsColors.textSecondary,
                        ),
                      ),
                    ],
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

class _EmptyIllustration extends StatelessWidget {
  const _EmptyIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          const Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(10, 11, 11, 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0x99F5F3EE),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Transform.rotate(
            angle: -3 * math.pi / 180,
            child: Container(
              width: 96,
              height: 112,
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
              decoration: BoxDecoration(
                color: NotsColors.buttonNeutral,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  _NoteRow(done: true, bar: 44, opacity: 1),
                  SizedBox(height: 10),
                  _NoteRow(done: false, bar: 38, opacity: 0.8),
                  SizedBox(height: 10),
                  _NoteRow(done: false, bar: 42, opacity: 0.6),
                ],
              ),
            ),
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: Transform.rotate(
              angle: 6 * math.pi / 180,
              child: SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: NotsColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 6,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.notifications,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 9,
                      top: 14,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: NotsColors.mintBright,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: NotsColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({
    required this.done,
    required this.bar,
    required this.opacity,
  });

  final bool done;
  final double bar;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: done ? NotsColors.mint : NotsColors.divider,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: done
                  ? const Icon(
                      Icons.check,
                      size: 9,
                      color: NotsColors.primaryDark,
                    )
                  : Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: NotsColors.inputIcon,
                        shape: BoxShape.circle,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: bar,
            height: 8,
            decoration: BoxDecoration(
              color: NotsColors.divider,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasteHintCard extends StatelessWidget {
  const _PasteHintCard({required this.onPaste});

  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: NotsColors.mint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.content_paste,
              size: 16,
              color: NotsColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ada teks tugas di clipboard?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    height: 18 / 13,
                    fontWeight: FontWeight.w600,
                    color: NotsColors.textPrimary,
                  ),
                ),
                Text(
                  'Tempel langsung untuk deteksi tenggat',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    height: 16 / 12,
                    color: NotsColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: NotsColors.buttonNeutral,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onPaste,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                child: Text(
                  'Tempel',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    height: 18 / 13,
                    fontWeight: FontWeight.w600,
                    color: NotsColors.primaryDark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.onCreate, required this.onSettings});

  final VoidCallback onCreate;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xE6FBF9F4),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F1B3F37),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.checklist, label: 'Pengingat', onTap: () {}),
              _NavItem(
                icon: Icons.add_circle_outline,
                label: 'Buat',
                onTap: onCreate,
              ),
              _NavItem(
                icon: Icons.tune,
                label: 'Pengaturan',
                onTap: onSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: NotsColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                height: 18 / 13,
                fontWeight: FontWeight.w600,
                color: NotsColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
