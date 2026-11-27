import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../tasks/task_model.dart';
import 'task_logic.dart';

const _overdueBackground = Color(0x4DFFDAD6);
const _warningBackground = Color(0xFFFBEBD6);
const _warningText = Color(0xFFB5651D);

/// Kartu "Progres Hari Ini".
class ProgressCard extends StatelessWidget {
  const ProgressCard({super.key, required this.progress});

  final DayProgress progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [NotsColors.mint60, Color(0x4DA5F1DF)],
        ),
        borderRadius: BorderRadius.circular(16),
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
              size: 22,
              color: NotsColors.primaryDark,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progres Hari Ini',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    height: 18 / 13,
                    fontWeight: FontWeight.w700,
                    color: NotsColors.primaryDark,
                  ),
                ),
                Text(
                  progress.total == 0
                      ? 'Belum ada tugas hari ini'
                      : '${progress.done} dari ${progress.total} tugas selesai diserahkan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    height: 16 / 12,
                    color: NotsColors.tealText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _Pill(
            label: '${progress.percent}%',
            background: Colors.white,
            foreground: NotsColors.primaryDark,
          ),
        ],
      ),
    );
  }
}

/// Kartu tugas di daftar utama.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.justSaved,
    required this.onOpen,
    required this.onToggle,
    required this.onDelete,
  });

  final Task task;
  final bool justSaved;
  final VoidCallback onOpen;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final due = task.dueAt;
    final created = task.createdAt;
    final isNew = justSaved ||
        (created != null && now.difference(created).inHours < 24);
    final soon = isDueSoon(task, now, const Duration(hours: 3));
    final urgent = soon ||
        isOverdue(task, now) ||
        (!task.isDone &&
            justSaved &&
            due != null &&
            daysFromToday(due, now) == 0);

    String? badge;
    if (task.isDone) {
      badge = 'Selesai';
    } else if (soon) {
      badge = 'Tenggat Dekat';
    } else if (isNew) {
      badge = 'Baru';
    } else if (task.title.toLowerCase().contains('kuis')) {
      badge = 'Kuis';
    }
    final highlightBadge = badge == 'Baru';

    return _CardShell(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CheckButton(done: task.isDone, onTap: onToggle, size: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        height: 22.5 / 18,
                        fontWeight: FontWeight.w600,
                        color: NotsColors.textPrimary,
                        decoration:
                            task.isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (task.courseName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        task.courseName!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          height: 16 / 12,
                          color: NotsColors.tealText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                _Pill(
                  label: badge,
                  background: highlightBadge
                      ? NotsColors.mint
                      : NotsColors.buttonNeutral,
                  foreground: highlightBadge
                      ? NotsColors.primaryDark
                      : NotsColors.tealText,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 28),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _Pill(
                    icon: Icons.schedule,
                    label: due == null ? 'Tanpa tenggat' : dueLabel(due, now),
                    fontSize: 13,
                    background:
                        urgent ? _overdueBackground : NotsColors.surfaceMuted,
                    foreground:
                        urgent ? NotsColors.error : NotsColors.textSecondary,
                  ),
                ),
              ),
              _TaskMenu(
                icon: Icons.more_vert,
                onEdit: onOpen,
                onDelete: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Kartu hasil pencarian, kata kunci diberi sorotan.
class SearchTaskCard extends StatelessWidget {
  const SearchTaskCard({
    super.key,
    required this.task,
    required this.terms,
    required this.onOpen,
    required this.onToggle,
    required this.onDelete,
  });

  final Task task;
  final List<String> terms;
  final VoidCallback onOpen;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  bool _hasTerm(String text) {
    final lower = text.toLowerCase();
    return terms.any((w) => lower.contains(w));
  }

  /// Mata kuliah & catatan. Kalau kata kunci cuma ada di teks asli,
  /// tampilkan teks aslinya.
  String get _subtitle {
    final info = [task.courseName, task.notes]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .join(' · ');
    final raw = task.rawText;
    if (raw != null &&
        !_hasTerm(task.title) &&
        !_hasTerm(info) &&
        _hasTerm(raw)) {
      return raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    }
    return info;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final due = task.dueAt;
    final completed = task.completedAt;
    final done = task.isDone;
    final late = isOverdue(task, now);
    final soon = isDueSoon(task, now, const Duration(hours: 24));
    final subtitle = [
      _subtitle,
      if (done && completed != null) 'Selesai ${shortDate(completed)}',
    ].where((s) => s.isNotEmpty).join(' · ');
    final decoration = done ? TextDecoration.lineThrough : null;

    return Opacity(
      opacity: done ? 0.75 : 1,
      child: _CardShell(
        onTap: onOpen,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CheckButton(
                  done: done,
                  onTap: onToggle,
                  size: 24,
                  circle: true,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: HighlightText(
                              text: task.title,
                              terms: terms,
                              maxLines: 2,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                height: 24 / 18,
                                fontWeight:
                                    done ? FontWeight.w500 : FontWeight.w700,
                                color: NotsColors.textPrimary,
                                decoration: decoration,
                              ),
                            ),
                          ),
                          if (due != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              done ? clockLabel(due) : shortDueLabel(due, now),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: done ? 12 : 13,
                                height: 18 / 13,
                                fontWeight:
                                    done ? FontWeight.w400 : FontWeight.w700,
                                color: done
                                    ? NotsColors.textMuted
                                    : NotsColors.primaryDark,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        HighlightText(
                          text: subtitle,
                          terms: terms,
                          maxLines: 2,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            height: 20 / 14,
                            color: NotsColors.textSecondary,
                            decoration: decoration,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 36),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (late)
                        const _Pill(
                          icon: Icons.warning_amber_rounded,
                          label: 'Lewat tenggat',
                          background: _overdueBackground,
                          foreground: NotsColors.error,
                        ),
                      if (soon)
                        const _Pill(
                          icon: Icons.warning_amber_rounded,
                          label: 'Mendekati tenggat',
                          background: _warningBackground,
                          foreground: _warningText,
                        ),
                      if (isPraktikum(task))
                        const _Pill(
                          icon: Icons.science_outlined,
                          label: 'Praktikum',
                          background: NotsColors.buttonNeutral,
                          foreground: NotsColors.tealText,
                        ),
                      if (done)
                        const _Pill(
                          icon: Icons.check_circle_outline,
                          label: 'Selesai',
                          background: NotsColors.surfaceMuted,
                          foreground: NotsColors.textMuted,
                        ),
                    ],
                  ),
                ),
                _TaskMenu(
                  icon: Icons.more_horiz,
                  onEdit: onOpen,
                  onDelete: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Teks dengan sorotan mint pada bagian yang cocok dengan [terms].
class HighlightText extends StatelessWidget {
  const HighlightText({
    super.key,
    required this.text,
    required this.terms,
    required this.style,
    required this.maxLines,
  });

  final String text;
  final List<String> terms;
  final TextStyle style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    var last = 0;
    if (terms.isNotEmpty) {
      final pattern = RegExp(
        terms.map((w) => RegExp.escape(w)).join('|'),
        caseSensitive: false,
      );
      for (final m in pattern.allMatches(text)) {
        if (m.start > last) {
          spans.add(TextSpan(text: text.substring(last, m.start)));
        }
        spans.add(
          TextSpan(
            text: text.substring(m.start, m.end),
            style: const TextStyle(
              backgroundColor: NotsColors.mint,
              color: NotsColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
        last = m.end;
      }
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));

    return Text.rich(
      TextSpan(children: spans),
      style: style,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0.5,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: child,
        ),
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  const _CheckButton({
    required this.done,
    required this.onTap,
    required this.size,
    this.circle = false,
  });

  final bool done;
  final VoidCallback onTap;
  final double size;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: done,
      label: done ? 'Batalkan tanda selesai' : 'Tandai selesai',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 2, 8, 8),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: done ? NotsColors.primaryDark : NotsColors.buttonNeutral,
              shape: circle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: circle ? null : BorderRadius.circular(6),
            ),
            child: done
                ? Icon(Icons.check, size: size - 6, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
    this.fontSize = 11,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 1, color: foreground),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskMenu extends StatelessWidget {
  const _TaskMenu({
    required this.icon,
    required this.onEdit,
    required this.onDelete,
  });

  final IconData icon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Rincian',
      icon: Icon(icon, size: 20, color: NotsColors.textSecondary),
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('Ubah')),
        PopupMenuItem(value: 'delete', child: Text('Hapus')),
      ],
    );
  }
}
