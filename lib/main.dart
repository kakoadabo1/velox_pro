import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/velox_theme.dart';
import 'auth_screen.dart';

/// Mode de thème global (sombre par défaut). Le bouton soleil/lune de l'écran
/// d'accueil bascule entre clair et sombre.
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.dark);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const VeloxProApp());
}

class VeloxProApp extends StatelessWidget {
  const VeloxProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'VELOX Pro',
          debugShowCheckedModeBanner: false,
          theme: veloxTheme(Brightness.light),
          darkTheme: veloxTheme(Brightness.dark),
          themeMode: mode,
          home: const AuthScreen(),
        );
      },
    );
  }
}
