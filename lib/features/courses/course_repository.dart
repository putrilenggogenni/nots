import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Nama kolom di tabel `courses`. Sesuaikan di sini kalau di Supabase beda.
const _nameColumn = 'name';
const _lecturerColumn = 'lecturer';
const _colorColumn = 'color';

class Course {
  const Course({
    required this.id,
    required this.name,
    this.lecturer,
    this.colorHex,
  });

  factory Course.fromMap(Map<String, dynamic> m) {
    return Course(
      id: '${m['id']}',
      name: (m[_nameColumn] as String?) ?? 'Tanpa nama',
      lecturer: m[_lecturerColumn] as String?,
      colorHex: m[_colorColumn] as String?,
    );
  }

  final String id;
  final String name;
  final String? lecturer;

  /// Format '#RRGGBB'.
  final String? colorHex;
}

/// Error data layer dengan pesan berbahasa Indonesia.
class CourseFailure implements Exception {
  const CourseFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class CourseRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Course>> fetchAll() async {
    try {
      final data = await _client.from('courses').select().order(
            _nameColumn,
            ascending: true,
          );
      return (data as List)
          .map((e) => Course.fromMap(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      debugPrint('CourseRepository fetchAll error: ${e.code} ${e.message}');
      throw CourseFailure('Gagal memuat mata kuliah (kode ${e.code}).');
    } catch (e) {
      debugPrint('CourseRepository fetchAll network error: ${e.runtimeType}');
      throw const CourseFailure(
        'Tidak bisa terhubung. Cek koneksi internetmu.',
      );
    }
  }

  Future<void> create({
    required String name,
    required String colorHex,
    String? lecturer,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const CourseFailure('Kamu belum masuk. Masuk dulu ya.');
    }
    try {
      final payload = <String, dynamic>{
        'user_id': user.id,
        _nameColumn: name,
        _colorColumn: colorHex,
      };
      if (lecturer != null && lecturer.isNotEmpty) {
        payload[_lecturerColumn] = lecturer;
      }
      await _client.from('courses').insert(payload);
    } on PostgrestException catch (e) {
      debugPrint('CourseRepository create error: ${e.code} ${e.message}');
      throw CourseFailure(_saveMessage(e));
    } catch (e) {
      debugPrint('CourseRepository create network error: ${e.runtimeType}');
      throw const CourseFailure(
        'Tidak bisa terhubung. Cek koneksi internetmu.',
      );
    }
  }

  String _saveMessage(PostgrestException e) {
    switch (e.code) {
      case 'PGRST204': // kolom tidak ditemukan
      case '42703':
        return 'Kolom tabel courses belum sesuai: ${e.message}';
      case '42501': // ditolak aturan RLS
        return 'Belum diizinkan menyimpan. Cek aturan RLS tabel courses.';
      default:
        return 'Gagal menyimpan mata kuliah (kode ${e.code}).';
    }
  }
}
