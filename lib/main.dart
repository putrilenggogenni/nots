import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'features/reminders/home_screen.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final ready = _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty;
  if (ready) {
    await Supabase.initialize(url: _supabaseUrl, publishableKey: _supabaseAnonKey);
  }

  runApp(NotsApp(supabaseReady: ready));
}

class NotsApp extends StatelessWidget {
  const NotsApp({super.key, required this.supabaseReady});

  final bool supabaseReady;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOTS',
      debugShowCheckedModeBanner: false,
      theme: buildNotsTheme(),
      home: AuthGate(supabaseReady: supabaseReady),
    );
  }
}

/// Sudah login -> halaman awal, belum -> layar Selamat Datang.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.supabaseReady});

  final bool supabaseReady;

  @override
  Widget build(BuildContext context) {
    final welcome = WelcomeScreen(
      onRegister: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RegisterScreen()),
      ),
      onLogin: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      ),
    );

    if (!supabaseReady) return welcome;

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, _) {
        final session = Supabase.instance.client.auth.currentSession;
        return session != null ? const HomeScreen() : welcome;
      },
    );
  }
}