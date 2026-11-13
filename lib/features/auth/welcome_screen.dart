import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme.dart';
import '../../core/widgets/nots_buttons.dart';

/// Layar "Selamat Datang - NOTS".
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onRegister,
    required this.onLogin,
  });

  final VoidCallback onRegister;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 37),
          child: Column(
            children: [
              const _BrandHeader(),
              const SizedBox(height: 20),
              const _TransformationCard(),
              const SizedBox(height: 24),
              const _StepsRow(),
              const SizedBox(height: 32),
              NotsPrimaryButton(label: 'Daftar Akun Baru', onPressed: onRegister),
              const SizedBox(height: 12),
              NotsSecondaryButton(
                label: 'Sudah Punya Akun? Masuk',
                onPressed: onLogin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: const BoxDecoration(
            color: NotsColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/images/logo_bell.svg',
              width: 51,
              height: 60,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'NOTS',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.55,
            color: NotsColors.primaryDark,
          ),
        ),
      ],
    );
  }
}

class _TransformationCard extends StatelessWidget {
  const _TransformationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NotsColors.heroBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const _ChatBubble(),
          const SizedBox(height: 10),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: NotsColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_downward, size: 14, color: Colors.white),
          ),
          const SizedBox(height: 10),
          const _ReminderCard(),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: NotsColors.mint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 11,
                      color: NotsColors.mintText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Dari grup kelas',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.22,
                        color: NotsColors.mintText,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '14.12 WIB',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: NotsColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '“Laporan Fisika besok jam 3 sore ya!”',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              height: 24 / 18,
              fontWeight: FontWeight.w600,
              color: NotsColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NotsColors.primaryDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 46),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: NotsColors.primary,
              borderRadius: BorderRadius.circular(48),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'OKT',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    height: 14 / 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.55,
                    color: NotsColors.mintLight,
                  ),
                ),
                Text(
                  '27',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    height: 22.5 / 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kumpulkan laporan Fisika',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    height: 20 / 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 12, color: NotsColors.mintBright),
                    const SizedBox(width: 6),
                    Text(
                      'Besok · 15.00 WIB',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        height: 18 / 13,
                        fontWeight: FontWeight.w600,
                        color: NotsColors.mintBright,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: NotsColors.checkBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 15,
              color: NotsColors.mint,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepsRow extends StatelessWidget {
  const _StepsRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NotsColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Step(icon: Icons.content_paste, title: 'Tangkap', subtitle: 'Koleksi\nteks'),
          _StepSeparator(),
          _Step(icon: Icons.rule, title: 'Konfirmasi', subtitle: 'Atur jadwal'),
          _StepSeparator(),
          _Step(
            icon: Icons.notifications_active_outlined,
            title: 'Diingatkan',
            subtitle: 'Tepat\nwaktu',
          ),
        ],
      ),
    );
  }
}

class _StepSeparator extends StatelessWidget {
  const _StepSeparator();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(top: 19, left: 4, right: 4),
        height: 2,
        color: NotsColors.divider,
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: NotsColors.primary),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            height: 18 / 13,
            fontWeight: FontWeight.w600,
            color: NotsColors.textPrimary,
          ),
        ),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            height: 16 / 12,
            color: NotsColors.textSecondary,
          ),
        ),
      ],
    );
  }
}