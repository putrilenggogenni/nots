import 'package:flutter/material.dart';

/// Hasil parsing tanggal & waktu dari teks tugas.
class ParsedCapture {
  const ParsedCapture({this.date, this.time});

  final DateTime? date; // lokal, hanya tanggal (jam/menit = 0)
  final TimeOfDay? time;
}

class CaptureParser {
  const CaptureParser();

  ParsedCapture parse(String text, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final date = _parseDate(text, n);
    final time = _parseTime(text);
    return ParsedCapture(date: date, time: time);
  }
}

const Map<String, int> _monthNumbers = {
  'jan': 1,
  'januari': 1,
  'feb': 2,
  'februari': 2,
  'mar': 3,
  'maret': 3,
  'apr': 4,
  'april': 4,
  'mei': 5,
  'jun': 6,
  'juni': 6,
  'jul': 7,
  'juli': 7,
  'agu': 8,
  'agt': 8,
  'agustus': 8,
  'sep': 9,
  'sept': 9,
  'september': 9,
  'okt': 10,
  'oktober': 10,
  'nov': 11,
  'november': 11,
  'des': 12,
  'desember': 12,
};

const List<String> _monthShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

const List<String> _weekdays = [
  'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
];

const Map<String, int> _weekdayNumbers = {
  'senin': 1,
  'selasa': 2,
  'rabu': 3,
  'kamis': 4,
  'jumat': 5,
  'sabtu': 6,
  'ahad': 7,
  'minggu': 7,
};

String formatDateChip(DateTime d) {
  final wd = _weekdays[d.weekday - 1];
  final mon = _monthShort[d.month - 1];
  return '$wd, ${d.day} $mon';
}

String formatTimeChip(TimeOfDay t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h.$m WIB';
}

DateTime? _parseDate(String text, DateTime now) {
  final abs = _parseAbsoluteDate(text, now);
  if (abs != null) return abs;

  final rel = _parseRelativeDate(text, now);
  if (rel != null) return rel;

  return _parseWeekdayDate(text, now);
}

DateTime? _parseAbsoluteDate(String text, DateTime now) {
  final candidates = <_DateCandidate>[];

  for (final m in RegExp(r'\b(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2}|\d{4})\b')
      .allMatches(text)) {
    final d = int.tryParse(m.group(1)!);
    final mo = int.tryParse(m.group(2)!);
    var y = int.tryParse(m.group(3)!);
    if (d == null || mo == null || y == null) continue;
    if (y < 100) y = 2000 + y;
    final dt = _validDate(y, mo, d);
    if (dt != null) {
      candidates.add(_DateCandidate(m.start, dt));
    }
  }

  final monthAlt = (_monthNumbers.keys.toList()
        ..sort((a, b) => b.length.compareTo(a.length)))
      .join('|');
  final reB = RegExp(
    '\\b(\\d{1,2})\\s+($monthAlt)(?:\\s+(\\d{2}|\\d{4}))?\\b',
    caseSensitive: false,
  );
  for (final m in reB.allMatches(text)) {
    final d = int.tryParse(m.group(1)!);
    final mon = _monthNumbers[m.group(2)!.toLowerCase()];
    if (d == null || mon == null) continue;
    int year;
    bool hasYear = false;
    if (m.group(3) != null) {
      var y = int.parse(m.group(3)!);
      if (y < 100) y = 2000 + y;
      year = y;
      hasYear = true;
    } else {
      year = now.year;
      hasYear = false;
    }
    final dt = _validDate(year, mon, d);
    if (dt == null) continue;
    DateTime result = dt;
    if (!hasYear) {
      final diff = now.difference(DateTime(result.year, result.month, result.day)).inDays;
      if (diff > 60) {
        result = DateTime(result.year + 1, result.month, result.day);
      }
    }
    candidates.add(_DateCandidate(m.start, result));
  }

  if (candidates.isEmpty) return null;
  candidates.sort((a, b) => a.pos.compareTo(b.pos));
  return candidates.first.date;
}

class _DateCandidate {
  _DateCandidate(this.pos, this.date);
  final int pos;
  final DateTime date;
}

DateTime? _validDate(int y, int m, int d) {
  if (m < 1 || m > 12) return null;
  if (d < 1) return null;
  final daysInMonth = DateTime(y, m + 1, 0).day;
  if (d > daysInMonth) return null;
  if (y < 1) return null;
  try {
    return DateTime(y, m, d);
  } catch (_) {
    return null;
  }
}

DateTime? _parseRelativeDate(String text, DateTime now) {
  final lower = text.toLowerCase();
  final keys = ['hari ini', 'besok', 'lusa'];
  int? bestPos;
  String? bestKey;
  for (final k in keys) {
    final idx = lower.indexOf(k);
    if (idx >= 0 && (bestPos == null || idx < bestPos)) {
      bestPos = idx;
      bestKey = k;
    }
  }
  if (bestKey == null) return null;
  final today = DateTime(now.year, now.month, now.day);
  if (bestKey == 'hari ini') return today;
  if (bestKey == 'besok') return today.add(const Duration(days: 1));
  if (bestKey == 'lusa') return today.add(const Duration(days: 2));
  return null;
}

DateTime? _parseWeekdayDate(String text, DateTime now) {
  final alt = _weekdayNumbers.keys.join('|');
  final re = RegExp('\\b($alt)\\b(?:\\s+(depan))?', caseSensitive: false);
  final matches = re.allMatches(text).toList();

  final validMatches = <RegExpMatch>[];
  for (final m in matches) {
    final word = m.group(1)!.toLowerCase();
    if (word == 'minggu') {
      final start = m.start;
      final prefix = text.substring(0, start).toLowerCase();
      if (!prefix.trimRight().endsWith('hari')) {
        continue;
      }
    }
    validMatches.add(m);
  }
  if (validMatches.isEmpty) return null;

  validMatches.sort((a, b) => a.start.compareTo(b.start));
  final m = validMatches.first;
  final word = m.group(1)!.toLowerCase();
  final target = _weekdayNumbers[word];
  if (target == null) return null;

  final today = DateTime(now.year, now.month, now.day);
  int daysAhead = (target - today.weekday + 7) % 7;
  if (daysAhead == 0) daysAhead = 7;
  if (m.group(2) != null) daysAhead += 7;
  return today.add(Duration(days: daysAhead));
}

TimeOfDay? _parseTime(String text) {
  final candidates = <_TimeCandidate>[];

  for (final m in RegExp(
        r'\b(jam|pukul|pkl)\s*(\d{1,2})(?:[.:](\d{2}))?',
        caseSensitive: false,
      ).allMatches(text)) {
    final h = int.tryParse(m.group(2)!);
    final min = m.group(3) != null ? int.tryParse(m.group(3)!) : 0;
    if (h == null || min == null) continue;
    final pod = _partOfDayAfter(text, m.end);
    candidates.add(_TimeCandidate(m.start, h, min, pod));
  }

  for (final m in RegExp(r'\b(\d{1,2}):(\d{2})\b').allMatches(text)) {
    final h = int.tryParse(m.group(1)!);
    final min = int.tryParse(m.group(2)!);
    if (h == null || min == null) continue;
    final pod = _partOfDayAfter(text, m.end);
    candidates.add(_TimeCandidate(m.start, h, min, pod));
  }

  for (final m in RegExp(r'\b(\d{1,2})\.(\d{2})\b').allMatches(text)) {
    final after = text.substring(m.end);
    if (!RegExp(r'^\s*(WIB|WITA|WIT)\b', caseSensitive: false).hasMatch(after)) {
      continue;
    }
    final h = int.tryParse(m.group(1)!);
    final min = int.tryParse(m.group(2)!);
    if (h == null || min == null) continue;
    final pod = _partOfDayAfter(text, m.end);
    candidates.add(_TimeCandidate(m.start, h, min, pod));
  }

  if (candidates.isEmpty) return null;

  final seen = <int>{};
  final unique = <_TimeCandidate>[];
  for (final c in candidates) {
    if (seen.add(c.start)) unique.add(c);
  }
  unique.sort((a, b) => a.start.compareTo(b.start));

  for (final c in unique) {
    if (c.hour < 0 || c.hour > 23) continue;
    if (c.minute < 0 || c.minute > 59) continue;
    final shifted = _applyPartOfDay(c.hour, c.partOfDay);
    return TimeOfDay(hour: shifted, minute: c.minute);
  }
  return null;
}

class _TimeCandidate {
  _TimeCandidate(this.start, this.hour, this.minute, this.partOfDay);
  final int start;
  final int hour;
  final int minute;
  final String? partOfDay;
}

String? _partOfDayAfter(String text, int end) {
  final rest = text.substring(end);
  final m = RegExp(r'^\s*([A-Za-z]+)').firstMatch(rest);
  if (m == null) return null;
  final word = m.group(1)!.toLowerCase();
  if (word == 'pagi' || word == 'siang' || word == 'sore' || word == 'malam') {
    return word;
  }
  return null;
}

int _applyPartOfDay(int hour, String? pod) {
  if (pod == null) return hour;
  switch (pod) {
    case 'pagi':
      return hour;
    case 'siang':
      if (hour >= 1 && hour <= 5) return hour + 12;
      return hour;
    case 'sore':
      if (hour >= 1 && hour <= 11) return hour + 12;
      return hour;
    case 'malam':
      if (hour >= 6 && hour <= 11) return hour + 12;
      if (hour == 12) return 0;
      return hour;
  }
  return hour;
}

String suggestTitle(String text) {
  final sentences = text.split(RegExp(r'[.!?]+|\n'));
  int i = 0;
  while (i < sentences.length && _isGreetingOnly(sentences[i])) {
    i++;
  }
  String chosen = '';
  if (i < sentences.length) {
    chosen = sentences[i].trim();
  }
  if (chosen.isEmpty) {
    chosen = text.trim();
  }
  chosen = chosen.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (chosen.length > 60) {
    chosen = '${chosen.substring(0, 60)}…';
  }
  return chosen;
}

bool _isGreetingOnly(String s) {
  final norm = s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').trim();
  if (norm.isEmpty) return true;
  final words = norm.split(RegExp(r'\s+'));
  if (words.length > 3) return false;
  const greetings = {'pagi', 'halo', 'hai', 'assalamualaikum', 'selamat', 'rek'};
  if (!greetings.contains(words.first)) return false;
  return true;
}
