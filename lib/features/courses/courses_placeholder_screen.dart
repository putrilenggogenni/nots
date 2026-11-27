import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../core/widgets/nots_common.dart';

class CoursesPlaceholderScreen extends StatelessWidget {
  const CoursesPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NotsBackAppBar(),
      backgroundColor: NotsColors.background,
      body: Center(
        child: Text(
          'Halaman mata kuliah menyusul.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            height: 24 / 16,
            fontWeight: FontWeight.w600,
            color: NotsColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// TODO(mata-kuliah): replace with the Detail Mata Kuliah / course CRUD screens (teammate).
