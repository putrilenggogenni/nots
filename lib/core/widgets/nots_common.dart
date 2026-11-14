import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme.dart';

/// Lingkaran hijau berisi lonceng NOTS. Butuh assets/images/logo_bell.svg.
class NotsLogo extends StatelessWidget {
  const NotsLogo({super.key, this.size = 92});

  final double size;

  @override
  Widget build(BuildContext context) {
    final s = size / 92;
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: NotsColors.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SvgPicture.asset(
          'assets/images/logo_bell.svg',
          width: 51 * s,
          height: 60 * s,
        ),
      ),
    );
  }
}

/// App bar polos dengan tombol kembali (layar Daftar, Masuk, Lupa sandi).
class NotsBackAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NotsBackAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 64,
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
    );
  }
}
