import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/theme/driba_theme.dart';
import 'main_shell.dart';
import 'modules/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI style for immersive experience
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFF050B14),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  
  // Enable edge-to-edge
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Anonymous auth for frictionless entry
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  runApp(const ProviderScope(child: DribaApp()));
}

class DribaApp extends ConsumerWidget {
  const DribaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Driba OS',
      debugShowCheckedModeBanner: false,
      theme: DribaTheme.darkTheme,
      home: const AppRouter(),
    );
  }
}

/// Routes between onboarding and main app
class AppRouter extends ConsumerWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For now, go directly to main shell
    // In production, check if user has completed onboarding
    return const MainShell();
  }
}
