import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../core/widgets/nots_buttons.dart';
import '../auth/auth_service.dart';
import '../capture/capture_screen.dart';
import '../settings/profile_repository.dart';
import '../settings/settings_screen.dart';
import '../tasks/task_model.dart';
import '../tasks/task_repository.dart';
import 'task_detail_screen.dart';
import 'task_logic.dart';
import 'task_widgets.dart';

/// Layar "Pengingat" (halaman awal setelah login).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _days = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
  ];
  static const _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  final _auth = AuthService();
  final _repo = TaskRepository();
  final _profileRepo = ProfileRepository();
  String _profileName = '';
  int _tab = 0;
  final _searchController = TextEditingController();
  final _toggling = <String>{};

  List<Task>? _tasks; // null = belum selesai dimuat
  String? _loadError;
  int _loadCount = 0;
  String? _newTaskId; // tugas yang baru disimpan, ditaruh paling atas

  int _filter = filterToday;
  String _query = '';
  int _category = 0;
  bool _hideDone = false;

  @override
  void initState() {
    super.initState();
    _reload();
    _loadProfileName();
  }

  Future<void> _loadProfileName() async {
    try {
      final p = await _profileRepo.loadProfile();
      if (!mounted) return;
      setState(() => _profileName = p.name);
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final current = ++_loadCount;
    try {
      final tasks = await _repo.fetchAll();
      if (!mounted || current != _loadCount) return;
      setState(() {
        _tasks = tasks;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted || current != _loadCount) return;
      if (_tasks == null) {
        setState(() {
          _loadError = '$e';
        });
      } else {
        _snack('$e');
      }
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _runAndReload(Future<void> Function() action) async {
    try {
      await action();
      if (mounted) await _reload();
    } catch (e) {
      _snack('$e');
    }
  }

  String get _dateLabel {
    final now = DateTime.now();
    return '${_days[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]} ${now.year}';
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _query = '';
      _category = 0;
      _hideDone = false;
    });
  }

  Future<void> _openCapture({String? initialText}) async {
    final savedId = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => CaptureScreen(initialText: initialText),
      ),
    );
    if (!mounted) return;
    if (savedId != null) {
      _newTaskId = savedId;
      _clearSearch();
    }
    await _reload();
    if (!mounted || savedId == null) return;

    // Kalau tugas baru tidak masuk filter aktif, pindah ke "Semua".
    final now = DateTime.now();
    final hidden = (_tasks ?? <Task>[]).any(
      (t) => t.id == savedId && !matchesDateFilter(t, _filter, now),
    );
    if (hidden) setState(() => _filter = filterAll);

    _showToast(
      'Pengingat disimpan',
      () => _runAndReload(() => _repo.deleteTask(savedId)),
    );
  }

  /// Notifikasi di atas navigasi bawah, dengan tombol "Urungkan".
  void _showToast(String message, VoidCallback onUndo) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: NotsColors.primary,
        shape: const StadiumBorder(),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            const CircleAvatar(
              radius: 14,
              backgroundColor: NotsColors.mintBright,
              child: Icon(Icons.check, size: 16, color: NotsColors.primaryDark),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                messenger.hideCurrentSnackBar();
                onUndo();
              },
              child: Text(
                'Urungkan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: NotsColors.mintBright,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Tutup notifikasi',
              onPressed: () => messenger.hideCurrentSnackBar(),
              icon: const Icon(
                Icons.close,
                size: 18,
                color: NotsColors.mintBright,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleDone(Task task) async {
    if (!_toggling.add(task.id)) return; // cegah ketuk dobel
    final done = !task.isDone;
    try {
      await _repo.setDone(task.id, done);
      if (!mounted) return;
      await _reload();
      if (!mounted || !done) return;
      _showToast(
        'Tugas selesai',
        () => _runAndReload(() => _repo.setDone(task.id, false)),
      );
    } catch (e) {
      _snack('$e');
    } finally {
      _toggling.remove(task.id);
    }
  }

  Future<void> _openDetail(Task task) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => TaskDetailScreen(task: task)),
    );
    if (changed == true && mounted) await _reload();
  }

  Future<void> _confirmDelete(Task task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus pengingat?'),
        content: Text(
          '"${task.title}" akan dihapus dan tidak bisa dikembalikan.',
        ),
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
    if (ok != true || !mounted) return;
    await _runAndReload(() => _repo.deleteTask(task.id));
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!mounted) return;
    if (text.isEmpty) {
      _snack('Clipboard kosong.');
      return;
    }
    await _openCapture(initialText: text);
  }

  void _selectTab(int index) {
    if (index == 1) {
      _openCapture();
      return;
    }
    setState(() => _tab = index);
    if (index == 0) _loadProfileName();
  }

  @override
  Widget build(BuildContext context) {
    final name = _profileName.isNotEmpty
        ? _profileName.trim().split(RegExp(r'\\s+')).first
        : (_auth.firstName ?? 'kamu');
    final searching = _query.trim().isNotEmpty;

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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'Pengaturan akun',
              onPressed: () => _selectTab(2),
              icon: const CircleAvatar(
                radius: 16,
                backgroundColor: NotsColors.primaryDark,
                child: Icon(
                  Icons.person_outline,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _tab == 0
          ? RefreshIndicator(
              onRefresh: _reload,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    searching ? _compactGreeting(name) : _greeting(name),
                    SizedBox(height: searching ? 12 : 24),
                    _SearchBar(
                      key: const ValueKey('search'),
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      onClear: _clearSearch,
                    ),
                    if (searching) ..._searchSection() else ..._homeSection(),
                  ],
                ),
              ),
            )
          : SettingsScreen(
              onNameChanged: (newName) {
                if (!mounted) return;
                setState(() => _profileName = newName);
              },
            ),
      bottomNavigationBar: _BottomNav(
        selected: _tab == 0 ? 0 : 2,
        onSelect: _selectTab,
      ),
    );
  }

  Widget _greeting(String name) {
    return Column(
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
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: NotsColors.primaryDark,
                ),
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
      ],
    );
  }

  Widget _compactGreeting(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Halo, $name.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            height: 28 / 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.55,
            color: NotsColors.textPrimary,
          ),
        ),
        Text(
          _dateLabel,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w500,
            color: NotsColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Isi halaman saat tidak sedang mencari.
  List<Widget> _homeSection() {
    return [
      const SizedBox(height: 8),
      _chipRow([
        for (var i = 0; i < dateFilterLabels.length; i++)
          _FilterChip(
            label: dateFilterLabels[i],
            icon: i == filterToday ? Icons.calendar_today_outlined : null,
            selected: i == _filter,
            onTap: () => setState(() => _filter = i),
          ),
      ]),
      const SizedBox(height: 24),
      ..._taskList(),
    ];
  }

  List<Widget> _taskList() {
    final tasks = _tasks;
    if (tasks == null) return [_loadingOrError()];

    if (tasks.isEmpty) {
      return [
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
      ];
    }

    final now = DateTime.now();
    final inFilter =
        tasks.where((t) => matchesDateFilter(t, _filter, now)).toList();
    final active = inFilter.where((t) => !t.isDone).toList();
    final newIndex = active.indexWhere((t) => t.id == _newTaskId);
    if (newIndex > 0) active.insert(0, active.removeAt(newIndex));
    // Tugas selesai hanya ditampilkan di filter "Semua".
    final visible = [
      ...active,
      if (_filter == filterAll) ...inFilter.where((t) => t.isDone),
    ];

    return [
      ProgressCard(progress: todayProgress(tasks, now)),
      const SizedBox(height: 24),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Daftar Pengingat',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              height: 20 / 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.375,
              color: NotsColors.textPrimary,
            ),
          ),
          Text(
            '${active.length} Aktif',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: NotsColors.tealText,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      if (visible.isEmpty)
        _message(
          'Tidak ada tugas aktif di "${dateFilterLabels[_filter]}". '
          'Cek filter lain.',
        ),
      for (final task in visible)
        Padding(
          key: ValueKey(task.id),
          padding: const EdgeInsets.only(bottom: 16),
          child: TaskCard(
            task: task,
            justSaved: task.id == _newTaskId,
            onOpen: () => _openDetail(task),
            onToggle: () => _toggleDone(task),
            onDelete: () => _confirmDelete(task),
          ),
        ),
    ];
  }

  /// Isi halaman saat kotak pencarian terisi.
  List<Widget> _searchSection() {
    final tasks = _tasks;
    if (tasks == null) {
      return [const SizedBox(height: 24), _loadingOrError()];
    }

    final terms = searchTerms(_query);
    final found = tasks.where((t) => matchesSearch(t, terms)).toList();
    final shown = found.where((t) => matchesCategory(t, _category)).toList();
    final upcoming = shown.where((t) => !t.isDone).toList();
    final done = shown.where((t) => t.isDone).toList();

    Widget card(Task task) => Padding(
          key: ValueKey(task.id),
          padding: const EdgeInsets.only(bottom: 12),
          child: SearchTaskCard(
            task: task,
            terms: terms,
            onOpen: () => _openDetail(task),
            onToggle: () => _toggleDone(task),
            onDelete: () => _confirmDelete(task),
          ),
        );

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 0, 4),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 3,
              backgroundColor: NotsColors.primaryDark,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Ditemukan '),
                    TextSpan(
                      text: '${found.length} pengingat',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: NotsColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: NotsColors.textSecondary,
                ),
              ),
            ),
            _textButton('Reset Filter', _clearSearch),
          ],
        ),
      ),
      _chipRow([
        for (var i = 0; i < searchCategoryLabels.length; i++)
          _FilterChip(
            label: '${searchCategoryLabels[i]} '
                '(${found.where((t) => matchesCategory(t, i)).length})',
            selected: i == _category,
            onTap: () => setState(() => _category = i),
          ),
      ]),
      const SizedBox(height: 20),
      if (shown.isEmpty)
        _message('Tidak ada pengingat yang cocok dengan "${_query.trim()}".'),
      if (upcoming.isNotEmpty) ...[
        _groupHeader(
          'Mendatang',
          upcoming.length,
          trailing: Text(
            'Urut waktu',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: NotsColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...upcoming.map(card),
        const SizedBox(height: 12),
      ],
      if (done.isNotEmpty) ...[
        _groupHeader(
          'Selesai',
          done.length,
          trailing: _textButton(
            _hideDone ? 'Tampilkan' : 'Sembunyikan',
            () => setState(() => _hideDone = !_hideDone),
          ),
        ),
        const SizedBox(height: 12),
        if (!_hideDone) ...done.map(card),
      ],
    ];
  }

  Widget _loadingOrError() {
    final error = _loadError;
    if (error == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      children: [
        _message(error),
        _textButton('Coba lagi', () {
          setState(() {
            _loadError = null;
          });
          _reload();
        }),
      ],
    );
  }

  Widget _message(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: NotsColors.textMuted,
        ),
      ),
    );
  }

  Widget _textButton(String label, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: NotsColors.primaryDark,
        ),
      ),
    );
  }

  Widget _chipRow(List<Widget> chips) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            chips[i],
          ],
        ],
      ),
    );
  }

  Widget _groupHeader(String title, int count, {required Widget trailing}) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            height: 24 / 18,
            fontWeight: FontWeight.w600,
            color: NotsColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: NotsColors.mint,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count pengingat',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: NotsColors.mintText,
            ),
          ),
        ),
        const Spacer(),
        trailing,
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

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
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: style,
        cursorColor: NotsColors.primary,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: 'Cari tugas atau mata kuliah...',
          hintStyle: style.copyWith(color: NotsColors.textMuted),
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: NotsColors.primaryDark,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  onPressed: onClear,
                  icon: const CircleAvatar(
                    radius: 14,
                    backgroundColor: NotsColors.buttonNeutral,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: NotsColors.textSecondary,
                    ),
                  ),
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
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : NotsColors.textSecondary;
    return Material(
      color: selected ? NotsColors.primary : NotsColors.buttonNeutral,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: foreground),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
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
        // Pendar mint tipis di pojok kartu, sesuai Figma.
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFF0FCF9), Colors.white, Color(0xFFF2F9F6)],
        ),
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
  const _BottomNav({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

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
              _NavItem(
                icon: Icons.checklist,
                label: 'Pengingat',
                selected: selected == 0,
                onTap: () => onSelect(0),
              ),
              _NavItem(
                icon: Icons.add_circle_outline,
                label: 'Buat',
                onTap: () => onSelect(1),
              ),
              _NavItem(
                icon: Icons.tune,
                label: 'Pengaturan',
                selected: selected == 2,
                onTap: () => onSelect(2),
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
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final foreground =
        selected ? NotsColors.mintText : NotsColors.textSecondary;
    return Material(
      color: selected ? NotsColors.mint : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
