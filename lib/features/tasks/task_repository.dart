import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'task_model.dart';

/// Error data layer dengan pesan berbahasa Indonesia.
class TaskFailure implements Exception {
  const TaskFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class TaskRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// Mengembalikan id tugas yang baru disimpan.
  Future<String> createTask({
    required String title,
    DateTime? dueAt,
    String? rawText,
    String source = 'clipboard',
    String? courseId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const TaskFailure('Kamu belum masuk. Masuk dulu ya.');
    }

    try {
      final payload = <String, dynamic>{
        'user_id': user.id,
        'title': title,
        'raw_text': rawText,
        'source': source,
      };
      if (dueAt != null) {
        payload['due_at'] = dueAt.toUtc().toIso8601String();
      }
      if (courseId != null) {
        payload['course_id'] = courseId;
      }
      final row = await _client
          .from('tasks')
          .insert(payload)
          .select('id')
          .single();
      return row['id'] as String;
    } on PostgrestException catch (e) {
      debugPrint('TaskRepository createTask error: ${e.code} ${e.message}');
      throw const TaskFailure('Gagal menyimpan tugas. Coba lagi.');
    } catch (e) {
      debugPrint('TaskRepository createTask network error: ${e.runtimeType}');
      throw const TaskFailure('Tidak bisa terhubung. Cek koneksi internetmu.');
    }
  }

  Future<List<Task>> fetchAll() async {
    try {
      final data = await _client
          .from('tasks')
          .select('*, courses(name)')
          .order('due_at', ascending: true, nullsFirst: false);
      return (data as List)
          .map((e) => Task.fromMap(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      debugPrint('TaskRepository fetchAll error: ${e.code} ${e.message}');
      throw const TaskFailure('Gagal memuat tugas. Coba lagi.');
    } catch (e) {
      debugPrint('TaskRepository fetchAll network error: ${e.runtimeType}');
      throw const TaskFailure('Tidak bisa terhubung. Cek koneksi internetmu.');
    }
  }

  Future<void> setDone(String id, bool done) async {
    await _write(
      () => _client
          .from('tasks')
          .update({
            'status': done ? 'done' : 'todo',
            'completed_at': done
                ? DateTime.now().toUtc().toIso8601String()
                : null,
          })
          .eq('id', id)
          .select(),
      'Gagal mengubah status tugas.',
    );
  }

  Future<void> updateTask(
    String id, {
    required String title,
    DateTime? dueAt,
    String? notes,
  }) async {
    await _write(
      () => _client
          .from('tasks')
          .update({
            'title': title,
            'due_at': dueAt?.toUtc().toIso8601String(),
            'notes': notes,
          })
          .eq('id', id)
          .select(),
      'Gagal menyimpan perubahan.',
    );
  }

  Future<void> deleteTask(String id) async {
    await _write(
      () => _client.from('tasks').delete().eq('id', id).select(),
      'Gagal menghapus tugas.',
    );
  }

  /// Jika tidak ada baris yang berubah, biasanya aturan RLS belum diizinkan.
  Future<void> _write(
    Future<List<Map<String, dynamic>>> Function() action,
    String failMessage,
  ) async {
    try {
      final rows = await action();
      if (rows.isEmpty) throw TaskFailure(failMessage);
    } on TaskFailure {
      rethrow;
    } on PostgrestException catch (e) {
      debugPrint('TaskRepository write error: ${e.code} ${e.message}');
      throw TaskFailure(failMessage);
    } catch (e) {
      debugPrint('TaskRepository write network error: ${e.runtimeType}');
      throw const TaskFailure('Tidak bisa terhubung. Cek koneksi internetmu.');
    }
  }
}
