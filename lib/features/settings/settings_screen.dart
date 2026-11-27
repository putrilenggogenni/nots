import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../auth/auth_service.dart';
import '../courses/courses_placeholder_screen.dart';
import 'edit_name_sheet.dart';
import 'profile_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.onNameChanged});

  final ValueChanged<String>? onNameChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _repo = ProfileRepository();
  bool _loading = true;
  String _name = '';
  String _email = '';
  int _courseCount = 0;
  int _todoCount = 0;
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await _repo.loadProfile();
      final courses = await _repo.countCourses();
      final todos = await _repo.countTodoThisWeek();
      if (!mounted) return;
      setState(() {
        _name = profile.name;
        _email = profile.email;
        _courseCount = courses;
        _todoCount = todos;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _reloadCounts() async {
    final courses = await _repo.countCourses();
    final todos = await _repo.countTodoThisWeek();
    if (!mounted) return;
    setState(() {
      _courseCount = courses;
      _todoCount = todos;
    });
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = <String>[];
    for (final p in parts) {
      if (p.isEmpty) continue;
      letters.add(p[0].toUpperCase());
      if (letters.length == 2) break;
    }
    if (letters.isEmpty) return '?';
    return letters.join();
  }

  Future<void> _openEditName() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => EditNameSheet(
        initialName: _name,
        onSaved: (newName) {
          if (!mounted) return;
          setState(() => _name = newName);
          widget.onNameChanged?.call(newName);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nama diperbarui.')),
          );
        },
      ),
    );
  }

  Future<void> _openCourses() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CoursesPlaceholderScreen()),
    );
    if (mounted) await _reloadCounts();
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Kamu perlu masuk lagi untuk membuka tugasmu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Keluar', style: TextStyle(color: NotsColors.error)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await AuthService().signOut();
      // rely on auth state change in main.dart
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _loading ? '...' : (_name.isEmpty ? 'Mahasiswa' : _name);
    final email = _loading ? '' : _email;
    final quote = _todoCount > 0
        ? 'Tersisa $_todoCount tugas pekan ini. Kamu sudah melangkah sejauh ini, jangan lupa istirahat cukup ya!'
        : 'Belum ada tugas pekan ini. Nikmati waktu luangmu!';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pengaturan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              height: 40 / 32,
              fontWeight: FontWeight.w800,
              color: NotsColors.primaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kelola preferensi dan akun belajarmu di NOTS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              height: 20 / 14,
              color: NotsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          _ProfileCard(
            name: name,
            email: email,
            initials: _initials(name),
            quote: quote,
            onEdit: _openEditName,
          ),
          const SizedBox(height: 24),
          Text(
            'AKADEMIK & APLIKASI',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: NotsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _ListCard(
            courseCount: _courseCount,
            notifications: _notifications,
            onNotificationsChanged: (v) => setState(() => _notifications = v),
            onCoursesTap: _openCourses,
            onAboutTap: () => showAboutDialog(
              context: context,
              applicationName: 'NOTS',
              applicationVersion: '1.0',
            ),
          ),
          const SizedBox(height: 24),
          _Banner(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: Material(
              color: NotsColors.errorContainerSoft,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _confirmLogout,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout, size: 20, color: NotsColors.error),
                    const SizedBox(width: 8),
                    Text(
                      'Keluar dari Akun',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        height: 20 / 16,
                        fontWeight: FontWeight.w600,
                        color: NotsColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'NOTS Studio • Dirancang untuk Mahasiswa Indonesia',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                height: 16 / 12,
                fontWeight: FontWeight.w600,
                color: NotsColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.email,
    required this.initials,
    required this.quote,
    required this.onEdit,
  });

  final String name;
  final String email;
  final String initials;
  final String quote;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: NotsColors.mint,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          height: 24 / 18,
                          fontWeight: FontWeight.w800,
                          color: NotsColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: NotsColors.primaryDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        height: 24 / 18,
                        fontWeight: FontWeight.w700,
                        color: NotsColors.textPrimary,
                      ),
                    ),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        height: 18 / 13,
                        color: NotsColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: NotsColors.buttonNeutral,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onEdit,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: NotsColors.buttonNeutral,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: NotsColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: NotsColors.buttonNeutral,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.sentiment_satisfied_alt_outlined,
                  size: 16,
                  color: NotsColors.primaryDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    quote,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      height: 19 / 13,
                      fontStyle: FontStyle.italic,
                      color: NotsColors.textSecondary,
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

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.courseCount,
    required this.notifications,
    required this.onNotificationsChanged,
    required this.onCoursesTap,
    required this.onAboutTap,
  });

  final int courseCount;
  final bool notifications;
  final ValueChanged<bool> onNotificationsChanged;
  final VoidCallback onCoursesTap;
  final VoidCallback onAboutTap;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          _Row(
            icon: Icons.menu_book_outlined,
            title: 'Mata kuliah',
            subtitle: 'Jadwal & modul aktif',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: NotsColors.segmentTrack,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$courseCount mata kuliah',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      height: 16 / 12,
                      fontWeight: FontWeight.w600,
                      color: NotsColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 20, color: NotsColors.textSecondary),
              ],
            ),
            onTap: onCoursesTap,
          ),
          const Divider(height: 1, color: NotsColors.segmentTrack, indent: 80),
          _Row(
            icon: Icons.notifications_active_outlined,
            title: 'Notifikasi',
            subtitle: 'Pengingat tenggat (WIB)',
            trailing: Switch(
              value: notifications,
              onChanged: onNotificationsChanged,
              activeTrackColor: NotsColors.primaryDark,
              thumbColor: WidgetStateProperty.all(Colors.white),
              thumbIcon: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Icon(Icons.check, size: 16, color: NotsColors.primaryDark);
                }
                return null;
              }),
              // TODO(notifikasi): persist and schedule reminders
            ),
            onTap: null,
          ),
          const Divider(height: 1, color: NotsColors.segmentTrack, indent: 80),
          _Row(
            icon: Icons.info_outline,
            title: 'Tentang NOTS',
            subtitle: 'Catatan & jadwal mahasiswa',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: NotsColors.mint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Versi 1.0',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      height: 16 / 12,
                      fontWeight: FontWeight.w600,
                      color: NotsColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 20, color: NotsColors.textSecondary),
              ],
            ),
            onTap: onAboutTap,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: NotsColors.mint,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, size: 22, color: NotsColors.primaryDark),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      height: 22 / 16,
                      fontWeight: FontWeight.w600,
                      color: NotsColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      height: 18 / 13,
                      color: NotsColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 144,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [NotsColors.primaryDark, NotsColors.primary],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ruang Belajar Tenang',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    height: 26 / 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fokus lebih jernih tanpa distraksi deadline menumpuk.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    height: 18 / 13,
                    color: Colors.white70,
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
