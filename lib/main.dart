import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'core/theme/driba_theme.dart';
import 'core/shell/shell_state.dart';
import 'main_shell.dart';
import 'modules/onboarding/onboarding_flow.dart';

/// SharedPreferences instance — initialized before runApp
late final SharedPreferences prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFF050B14),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Load prefs before app starts
  prefs = await SharedPreferences.getInstance();

  // Pass prefs to shell so it can load onboarding screen selections
  ShellNotifier.setPrefs(prefs);

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

/// Routes based on onboarding status (local, no auth wall)
class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  bool _checking = true;
  bool _onboarded = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final done = prefs.getBool('onboarding_complete') ?? false;
    if (done) {
      // Ensure anonymous auth for Firestore reads
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    }
    if (mounted) {
      setState(() {
        _onboarded = done;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFF050B14),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00E1FF)),
        ),
      );
    }

    if (_onboarded) {
      return const MainShell();
    }

    return OnboardingFlow(
      onComplete: () async {
        // Anonymous auth after onboarding — frictionless entry
        if (FirebaseAuth.instance.currentUser == null) {
          await FirebaseAuth.instance.signInAnonymously();
        }
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainShell()),
            (_) => false,
          );
        }
      },
    );
  }
}
