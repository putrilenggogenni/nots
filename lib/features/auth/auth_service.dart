import 'package:supabase_flutter/supabase_flutter.dart';

bool isValidEmail(String value) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());

enum AuthErrorField { email, password, general }

/// Error auth dengan pesan berbahasa Indonesia, siap ditampilkan di UI.
class AuthFailure implements Exception {
  const AuthFailure(this.message, [this.field = AuthErrorField.general]);

  final String message;
  final AuthErrorField field;

  @override
  String toString() => message;
}

class AuthService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Nama depan dari data akun (dipakai untuk sapaan "Halo, Naya.").
  String? get firstName {
    final name = _client.auth.currentUser?.userMetadata?['name'];
    if (name is! String || name.trim().isEmpty) return null;
    return name.trim().split(RegExp(r'\s+')).first;
  }

  /// Mengembalikan true kalau langsung login, false kalau perlu verifikasi email.
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      // Saat konfirmasi email aktif, email yang sudah ada tidak melempar error
      // tapi mengembalikan user tanpa identities.
      if (res.user?.identities?.isEmpty ?? false) {
        throw const AuthFailure(
          'Email ini sudah terdaftar. Coba masuk.',
          AuthErrorField.email,
        );
      }
      return res.session != null;
    } on AuthFailure {
      rethrow;
    } on AuthException catch (e) {
      throw _map(e);
    } catch (_) {
      throw const AuthFailure('Tidak bisa terhubung. Cek koneksi internetmu.');
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw _map(e);
    } catch (_) {
      throw const AuthFailure('Tidak bisa terhubung. Cek koneksi internetmu.');
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw _map(e);
    } catch (_) {
      throw const AuthFailure('Tidak bisa terhubung. Cek koneksi internetmu.');
    }
  }

  Future<void> signOut() => _client.auth.signOut();

  AuthFailure _map(AuthException e) {
    final code = e.code ?? '';
    final msg = e.message.toLowerCase();

    if (code == 'user_already_exists' || msg.contains('already registered')) {
      return const AuthFailure(
        'Email ini sudah terdaftar. Coba masuk.',
        AuthErrorField.email,
      );
    }
    if (code == 'weak_password') {
      return const AuthFailure(
        'Kata sandi terlalu lemah. Coba kombinasi lain.',
        AuthErrorField.password,
      );
    }
    if (code == 'email_address_invalid' || code == 'validation_failed') {
      return const AuthFailure(
        'Format email belum benar.',
        AuthErrorField.email,
      );
    }
    if (code == 'invalid_credentials' || msg.contains('invalid login')) {
      return const AuthFailure('Email atau kata sandi salah.');
    }
    if (code == 'email_not_confirmed') {
      return const AuthFailure('Email belum diverifikasi. Cek inbox-mu.');
    }
    if (code.contains('rate_limit')) {
      return const AuthFailure('Terlalu banyak percobaan. Coba lagi sebentar.');
    }
    return AuthFailure(e.message);
  }
}
