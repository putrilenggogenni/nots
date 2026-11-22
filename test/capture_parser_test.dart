import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nots/features/capture/capture_parser.dart';

void main() {
  final now = DateTime(2026, 10, 26);

  test('test 1', () {
    final r = const CaptureParser().parse(
      'Pagi rek! Tugas bab 2 tinjauan pustaka dikumpul paling lambat Senin 26 Oktober jam 23.59 WIB ya.',
      now: now,
    );
    expect(r.date, DateTime(2026, 10, 26));
    expect(r.time, const TimeOfDay(hour: 23, minute: 59));
  });

  test('test 2', () {
    final r = const CaptureParser().parse(
      'Laporan Fisika besok jam 3 sore ya!',
      now: now,
    );
    expect(r.date, DateTime(2026, 10, 27));
    expect(r.time, const TimeOfDay(hour: 15, minute: 0));
  });

  test('test 3', () {
    final r = const CaptureParser().parse(
      'Kumpul 5 Nov pukul 08:30',
      now: now,
    );
    expect(r.date, DateTime(2026, 11, 5));
    expect(r.time, const TimeOfDay(hour: 8, minute: 30));
  });

  test('test 4', () {
    final r = const CaptureParser().parse('UTS hari Jumat', now: now);
    expect(r.date, DateTime(2026, 10, 30));
    expect(r.time, isNull);
  });

  test('test 5', () {
    final r = const CaptureParser().parse('lusa jam 9 pagi', now: now);
    expect(r.date, DateTime(2026, 10, 28));
    expect(r.time, const TimeOfDay(hour: 9, minute: 0));
  });

  test('test 6', () {
    final r = const CaptureParser().parse('Jumat depan jam 13.00 WIB', now: now);
    expect(r.date, DateTime(2026, 11, 6));
    expect(r.time, const TimeOfDay(hour: 13, minute: 0));
  });

  test('test 7', () {
    final r = const CaptureParser().parse('tidak ada tanggal di sini', now: now);
    expect(r.date, isNull);
    expect(r.time, isNull);
  });

  test('test 8', () {
    final r = const CaptureParser().parse('deadline 31 Februari', now: now);
    expect(r.date, isNull);
  });

  test('test 9', () {
    final r = const CaptureParser().parse(
      '5 Januari',
      now: DateTime(2026, 11, 20),
    );
    expect(r.date, DateTime(2027, 1, 5));
  });

  test('formatDateChip', () {
    expect(formatDateChip(DateTime(2026, 10, 26)), 'Senin, 26 Okt');
  });

  test('formatTimeChip', () {
    expect(formatTimeChip(const TimeOfDay(hour: 23, minute: 59)), '23.59 WIB');
  });

  test('suggestTitle skips greeting', () {
    final t = suggestTitle(
      'Pagi rek! Tugas bab 2 tinjauan pustaka dikumpul paling lambat Senin 26 Oktober.',
    );
    expect(t.startsWith('Tugas bab 2'), isTrue);
  });

  test('suggestTitle cuts at 60', () {
    final long = 'a' * 80;
    final t = suggestTitle(long);
    expect(t.length, 61); // 60 chars + ellipsis
    expect(t.endsWith('…'), isTrue);
  });
}
