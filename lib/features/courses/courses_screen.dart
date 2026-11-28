import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../core/widgets/nots_buttons.dart';
import 'add_course_sheet.dart';
import 'course_colors.dart';
import 'course_repository.dart';
import 'courses_empty_view.dart';

/// Layar "Mata Kuliah", dibuka dari Pengaturan.
class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final _repo = CourseRepository();

  List<Course>? _courses; // null = belum selesai dimuat
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final courses = await _repo.fetchAll();
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (_courses == null) {
        setState(() {
          _error = '$e';
        });
      } else {
        _snack('$e');
      }
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addCourse() async {
    final saved = await showAddCourseSheet(context);
    if (saved != true || !mounted) return;
    _snack('Mata kuliah ditambahkan.');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final courses = _courses;

    return Scaffold(
      backgroundColor: NotsColors.background,
      appBar: AppBar(
        toolbarHeight: 64,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: NotsColors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, size: 20),
          color: NotsColors.textPrimary,
        ),
        title: Text(
          'Mata Kuliah',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            height: 24 / 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.45,
            color: NotsColors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'Profil',
              onPressed: () => Navigator.of(context).maybePop(),
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
      body: SafeArea(
        top: false,
        child: courses == null ? _loadingOrError() : _content(courses),
      ),
    );
  }

  Widget _loadingOrError() {
    final error = _error;
    if (error == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: NotsColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _error = null;
                });
                _load();
              },
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(List<Course> courses) {
    return Column(
      children: [
        Expanded(
          child: courses.isEmpty ? _emptyState() : _courseList(courses),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: NotsPrimaryButton(
            label: 'Tambah mata kuliah',
            leadingIcon: Icons.add,
            showArrow: false,
            onPressed: _addCourse,
          ),
        ),
      ],
    );
  }

  /// Di tengah layar, tapi tetap bisa digulir di layar pendek.
  Widget _emptyState() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Center(child: CoursesEmptyView()),
          ),
        ),
      ),
    );
  }

  Widget _courseList(List<Course> courses) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daftar Mata Kuliah',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        height: 24 / 18,
                        fontWeight: FontWeight.w600,
                        color: NotsColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${courses.length} mata kuliah',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        height: 16 / 12,
                        color: NotsColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const CircleAvatar(
                radius: 20,
                backgroundColor: NotsColors.mint,
                child: Icon(
                  Icons.school_outlined,
                  size: 20,
                  color: NotsColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final course in courses)
            Padding(
              key: ValueKey(course.id),
              padding: const EdgeInsets.only(bottom: 16),
              child: _CourseCard(course: course),
            ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final lecturer = course.lecturer?.trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 14,
            height: 40,
            decoration: BoxDecoration(
              color: courseColorFromHex(course.colorHex),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    height: 20 / 15,
                    fontWeight: FontWeight.w600,
                    color: NotsColors.textPrimary,
                  ),
                ),
                if (lecturer.isNotEmpty)
                  Text(
                    lecturer,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      height: 16 / 12,
                      color: NotsColors.textSecondary,
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
