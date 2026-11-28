import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';

/// Pilihan "Warna Label Catatan" sesuai Figma.
class CourseColor {
  const CourseColor(this.label, this.hex, this.color);

  final String label;
  final String hex;
  final Color color;
}

const courseColors = [
  CourseColor('Teal Alam', '#176B5D', NotsColors.primary),
  CourseColor('Sage Hangat', '#42655C', NotsColors.tealText),
  CourseColor('Amber', '#D97706', Color(0xFFD97706)),
  CourseColor('Lavender', '#6B5B95', Color(0xFF6B5B95)),
  CourseColor('Terakota', '#B3402F', Color(0xFFB3402F)),
];

/// Warna dari teks '#RRGGBB'; kembali ke hijau utama kalau kosong atau salah.
Color courseColorFromHex(String? hex) {
  final digits = hex?.replaceFirst('#', '') ?? '';
  if (digits.length != 6) return NotsColors.primary;
  final value = int.tryParse(digits, radix: 16);
  return value == null ? NotsColors.primary : Color(0xFF000000 | value);
}
