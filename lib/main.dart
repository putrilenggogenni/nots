import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


import 'core/theme.dart';
import 'features/auth/welcome_screen.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);

    // Tes koneksi sementara, hapus setelah berhasil
    final res = await Supabase.instance.client.from('courses').select().limit(1);
    debugPrint('Supabase OK: $res');
  }

  runApp(const NotsApp());
}

class NotsApp extends StatelessWidget {
  const NotsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOTS',
      debugShowCheckedModeBanner: false,
      theme: buildNotsTheme(),
      home: WelcomeScreen(
        onRegister: () {
          // TODO: navigasi ke layar Daftar
        },
        onLogin: () {
          // TODO: navigasi ke layar Masuk
        },
      ),
    );
  }
}