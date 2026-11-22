import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Error data layer dengan pesan berbahasa Indonesia.
class TaskFailure implements Exception {
  const TaskFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class TaskRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<void> createTask({
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
      await _client.from('tasks').insert(payload);
    } on PostgrestException catch (e) {
      debugPrint('TaskRepository createTask PostgrestException: ${e.code}');
      throw const TaskFailure('Gagal menyimpan tugas. Coba lagi.');
    } catch (e) {
      debugPrint('TaskRepository createTask network error: ${e.runtimeType}');
      throw const TaskFailure('Tidak bisa terhubung. Cek koneksi internetmu.');
    }
  }
}
