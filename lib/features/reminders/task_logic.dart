/// Logika filter, progres, pencarian, dan label tanggal untuk layar Pengingat.
library;

import '../tasks/task_model.dart';

const dateFilterLabels = ['Hari ini', 'Besok', '7 Hari', 'Semua'];
const filterToday = 0;
const filterTomorrow = 1;
const filterAll = 3;

const searchCategoryLabels = ['Semua', 'Tenggat Tugas', 'Praktikum'];

const _weekdays = [
  'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// Selisih hari kalender dari [now] ke [date].
int daysFromToday(DateTime date, DateTime now) =>
    DateTime.utc(date.year, date.month, date.day)
        .difference(DateTime.utc(now.year, now.month, now.day))
        .inDays;

bool matchesDateFilter(Task task, int filter, DateTime now) {
  if (filter == filterAll) return true;
  final due = task.dueAt;
  if (due == null) return false;
  final days = daysFromToday(due, now);
  if (filter == filterToday) return days == 0;
  if (filter == filterTomorrow) return days == 1;
  return days >= 0 && days < 7;
}

class DayProgress {
  const DayProgress(this.done, this.total);

  final int done;
  final int total;

  int get percent => total == 0 ? 0 : (done * 100 / total).round();
}

/// Dihitung dari tugas bertenggat hari ini + tugas yang diselesaikan hari ini.
DayProgress todayProgress(List<Task> tasks, DateTime now) {
  var done = 0;
  var total = 0;
  for (final t in tasks) {
    final due = t.dueAt;
    final completed = t.completedAt;
    final dueToday = due != null && daysFromToday(due, now) == 0;
    final completedToday =
        t.isDone && completed != null && daysFromToday(completed, now) == 0;
    if (!dueToday && !completedToday) continue;
    total++;
    if (t.isDone) done++;
  }
  return DayProgress(done, total);
}

/// Kata kunci pencarian. Kata "tugas" diabaikan kalau ada kata lain.
List<String> searchTerms(String query) {
  final words = query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  final specific = words.where((w) => w != 'tugas').toList();
  return specific.isEmpty ? words : specific;
}

String _searchableText(Task t) => [t.title, t.courseName, t.notes, t.rawText]
    .whereType<String>()
    .join(' ')
    .toLowerCase();

bool matchesSearch(Task task, List<String> terms) {
  final text = _searchableText(task);
  return terms.every((w) => text.contains(w));
}

bool isPraktikum(Task task) => _searchableText(task).contains('praktikum');

bool matchesCategory(Task task, int category) {
  if (category == 1) return !task.isDone && task.dueAt != null;
  if (category == 2) return !task.isDone && isPraktikum(task);
  return true;
}

bool isOverdue(Task task, DateTime now) {
  final due = task.dueAt;
  return !task.isDone && due != null && due.isBefore(now);
}

/// Belum lewat dan tinggal kurang dari [within].
bool isDueSoon(Task task, DateTime now, Duration within) {
  final due = task.dueAt;
  if (task.isDone || due == null || due.isBefore(now)) return false;
  return due.difference(now) < within;
}

String shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

String clockLabel(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}.'
    '${d.minute.toString().padLeft(2, '0')} WIB';

/// Contoh: "Hari ini, 23.59 WIB" atau "2 Nov 2026, 09.00 WIB".
String dueLabel(DateTime due, DateTime now) {
  final days = daysFromToday(due, now);
  final day = days == 0
      ? 'Hari ini'
      : days == 1
          ? 'Besok'
          : '${shortDate(due)} ${due.year}';
  return '$day, ${clockLabel(due)}';
}

/// Versi ringkas untuk hasil pencarian, contoh: "Jumat, 08.00 WIB".
String shortDueLabel(DateTime due, DateTime now) {
  final days = daysFromToday(due, now);
  final String day;
  if (days == 0) {
    day = 'Hari ini';
  } else if (days == 1) {
    day = 'Besok';
  } else if (days > 1 && days < 7) {
    day = _weekdays[due.weekday - 1];
  } else {
    day = shortDate(due);
  }
  return '$day, ${clockLabel(due)}';
}
