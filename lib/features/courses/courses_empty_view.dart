import 'dart:math' as math;

import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';

/// Isi layar "Mata Kuliah - Belum Ada Data".
class CoursesEmptyView extends StatelessWidget {
  const CoursesEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Pendar mint lembut di belakang ilustrasi.
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0x40C1E8DC), Color(0x00C1E8DC)],
          radius: 0.8,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ExcludeSemantics(
            child: CustomPaint(
              size: Size(256, 224),
              painter: _BooksPainter(),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum ada mata kuliah',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              height: 28 / 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.55,
              color: NotsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              'Tambahkan agar pengingatmu rapi dan jadwal kuliah tetap teratur.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 22.75 / 14,
                color: NotsColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: NotsColors.mint60,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.tips_and_updates_outlined,
                  size: 15,
                  color: NotsColors.tealText,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Bisa sinkron dengan jadwal semester',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      height: 14 / 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.22,
                      color: NotsColors.tealText,
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

/// Topi wisuda di atas tumpukan buku, digambar pada kanvas 256 x 224.
class _BooksPainter extends CustomPainter {
  const _BooksPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 256, size.height / 224);
    Paint fill(Color color) => Paint()..color = color;
    Paint line(Color color, double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = width;
    void box(Rect rect, double radius, Color color) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius)),
        fill(color),
      );
    }

    // Bayangan lantai.
    canvas.drawOval(
      const Rect.fromLTWH(24, 177, 208, 28),
      fill(const Color(0xFFEAE8E3)),
    );

    // Buku bawah.
    box(const Rect.fromLTWH(48, 153, 161, 26), 7, NotsColors.tealText);
    box(const Rect.fromLTWH(48, 153, 14, 26), 6, NotsColors.primaryDark);
    canvas.drawLine(
      const Offset(72, 166),
      const Offset(186, 166),
      line(NotsColors.inputIcon, 3),
    );

    // Buku tengah.
    box(const Rect.fromLTWH(60, 130, 140, 23), 5, Colors.white);
    box(const Rect.fromLTWH(60, 132, 11, 19), 2, NotsColors.divider);
    canvas.drawLine(
      const Offset(78, 141),
      const Offset(166, 141),
      line(NotsColors.mint, 3),
    );
    final bookmark = Path()
      ..moveTo(165, 141)
      ..lineTo(178, 141)
      ..lineTo(178, 168)
      ..lineTo(171.5, 162)
      ..lineTo(165, 168)
      ..close();
    canvas.drawPath(bookmark, fill(NotsColors.mint));

    // Buku terbuka.
    box(const Rect.fromLTWH(70, 94, 50, 36), 4, Colors.white);
    box(const Rect.fromLTWH(122, 95, 50, 35), 4, NotsColors.surfaceMuted);
    final text = line(NotsColors.inputIcon, 2);
    for (var i = 0; i < 3; i++) {
      final y = 103.0 + i * 6;
      canvas.drawLine(Offset(80, y), Offset(i == 2 ? 100 : 109, y), text);
      if (i < 2) {
        canvas.drawLine(Offset(131, y), Offset(158, y), text);
      }
    }
    canvas.drawCircle(const Offset(141, 117), 2.5, fill(NotsColors.mintLight));
    canvas.drawCircle(const Offset(150, 117), 2.5, fill(NotsColors.mint));

    // Daun kecil di depan buku.
    canvas.drawOval(
      const Rect.fromLTWH(48, 160, 15, 11),
      fill(NotsColors.mint),
    );
    canvas.drawOval(
      const Rect.fromLTWH(62, 161, 13, 10),
      fill(NotsColors.mintBright),
    );

    // Topi wisuda.
    canvas.drawArc(
      const Rect.fromLTWH(95, 33, 44, 30),
      0,
      math.pi,
      false,
      fill(NotsColors.primaryDark),
    );
    final cap = Path()
      ..moveTo(74, 40)
      ..lineTo(115, 25)
      ..lineTo(159, 37)
      ..lineTo(118, 52)
      ..close();
    canvas.drawPath(cap, fill(NotsColors.primary));
    canvas.drawCircle(const Offset(117, 40), 4, fill(NotsColors.mint));
    final tassel = Path()
      ..moveTo(119, 41)
      ..quadraticBezierTo(137, 53, 141, 64);
    canvas.drawPath(tassel, line(NotsColors.mint, 2));
    canvas.drawCircle(const Offset(141, 66), 4, fill(NotsColors.mintBright));

    // Gelembung dan kilau.
    canvas.drawCircle(const Offset(31, 39), 5, fill(NotsColors.mint));
    canvas.drawCircle(const Offset(228, 28), 8, fill(NotsColors.mint));
    _sparkle(canvas, const Offset(37, 147), 8, fill(NotsColors.mintLight));
    _sparkle(canvas, const Offset(221, 112), 6, fill(NotsColors.tealText));
  }

  void _sparkle(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BooksPainter oldDelegate) => false;
}
