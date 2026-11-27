import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileFailure implements Exception {
  const ProfileFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProfileRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<({String name, String email})> loadProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const ProfileFailure('Sesi berakhir. Silakan masuk lagi.');
    }
    final email = user.email ?? '';
    try {
      final row = await _client
          .from('profiles')
          .select('name')
          .eq('id', user.id)
          .maybeSingle();
      final name = (row?['name'] as String?)?.trim();
      if (name != null && name.isNotEmpty) {
        return (name: name, email: email);
      }
      return (name: _fallbackName(email), email: email);
    } on PostgrestException catch (e) {
      debugPrint('ProfileRepository loadProfile PostgrestException: ${e.code}');
      return (name: _fallbackName(email), email: email);
    } catch (e) {
      debugPrint('ProfileRepository loadProfile error: ${e.runtimeType}');
      return (name: _fallbackName(email), email: email);
    }
  }

  Future<void> updateName(String name) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const ProfileFailure('Sesi berakhir. Silakan masuk lagi.');
    }
    final trimmed = name.trim();
    try {
      final res = await _client
          .from('profiles')
          .update({'name': trimmed})
          .eq('id', user.id)
          .select('id');
      if ((res as List).isEmpty) {
        throw const ProfileFailure('Gagal menyimpan nama. Coba lagi.');
      }
    } on PostgrestException catch (e) {
      debugPrint('ProfileRepository updateName PostgrestException: ${e.code}');
      throw const ProfileFailure('Gagal menyimpan nama. Coba lagi.');
    } on ProfileFailure {
      rethrow;
    } catch (e) {
      debugPrint('ProfileRepository updateName error: ${e.runtimeType}');
      throw const ProfileFailure('Tidak bisa terhubung. Cek koneksi internetmu.');
    }
  }

  Future<int> countCourses() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;
    try {
      final res = await _client.from('courses').select('id');
      return (res as List).length;
    } catch (e) {
      debugPrint('ProfileRepository countCourses error: ${e.runtimeType}');
      return 0;
    }
  }

  Future<int> countTodoThisWeek() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      final end = start.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
      final res = await _client
          .from('tasks')
          .select('id')
          .eq('status', 'todo')
          .gte('due_at', start.toUtc().toIso8601String())
          .lte('due_at', end.toUtc().toIso8601String());
      return (res as List).length;
    } catch (e) {
      debugPrint('ProfileRepository countTodoThisWeek error: ${e.runtimeType}');
      return 0;
    }
  }

  String _fallbackName(String email) {
    final prefix = email.split('@').first.trim();
    return prefix.isEmpty ? 'Mahasiswa' : prefix;
  }
}
