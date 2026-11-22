import 'dart:typed_data';

import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';

class PhotoCaptureCard extends StatelessWidget {
  const PhotoCaptureCard({
    super.key,
    required this.controller,
    required this.imageBytes,
    required this.imageName,
    required this.scanning,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
  });

  final TextEditingController controller;
  final Uint8List? imageBytes;
  final String? imageName;
  final bool scanning;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _PickButton(
                icon: Icons.photo_camera_outlined,
                label: 'Ambil foto',
                onTap: scanning ? null : onCamera,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PickButton(
                icon: Icons.photo_library_outlined,
                label: 'Pilih galeri',
                onTap: scanning ? null : onGallery,
              ),
            ),
          ],
        ),
        if (imageBytes != null) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Image.memory(
                  imageBytes!,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
                if (imageName != null)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        imageName!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (scanning) ...[
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Memindai teks…',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: NotsColors.primaryDark,
                  ),
                ),
              ] else ...[
                const Icon(Icons.check_circle_outline,
                    size: 14, color: NotsColors.primaryDark),
                const SizedBox(width: 6),
                Text(
                  'Foto siap digunakan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: NotsColors.primaryDark,
                  ),
                ),
              ],
              const Spacer(),
              IconButton(
                onPressed: scanning ? null : onRemove,
                icon: const Icon(Icons.delete_outline, size: 18),
                color: NotsColors.textSecondary,
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Teks catatan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: NotsColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Perbaiki hasil pemindaian atau isi teks secara manual:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: NotsColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                minLines: 3,
                maxLines: null,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  height: 22 / 15,
                  color: NotsColors.textPrimary,
                ),
                cursorColor: NotsColors.primary,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Teks dari foto atau ketik manual di sini…',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: NotsColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PickButton extends StatelessWidget {
  const _PickButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Material(
        color: NotsColors.buttonNeutral,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: NotsColors.primaryDark),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: NotsColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}