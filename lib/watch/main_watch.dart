import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';
import 'package:SportTracker/firebase_options.dart';
import 'package:SportTracker/watch/screens/watch_home_screen.dart';
import 'package:SportTracker/watch/screens/watch_login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await EasyLocalization.ensureInitialized();
  runApp(const SportTrackerWatchApp());
}

class SportTrackerWatchApp extends StatelessWidget {
  const SportTrackerWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      supportedLocales: const [Locale('fr'), Locale('en'), Locale('es')],
      path: 'assets/langs',
      fallbackLocale: const Locale('en'),
      child: Builder(
        builder: (context) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            theme: _watchTheme(Brightness.dark),
            home: const _WatchRoot(),
          );
        },
      ),
    );
  }

  ThemeData _watchTheme(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: brightness,
        surface: brightness == Brightness.dark ? const Color(0xFF1C1C1C) : Colors.grey.shade100,
      ),
      scaffoldBackgroundColor: brightness == Brightness.dark ? const Color(0xFF0D0D0D) : Colors.white,
      cardTheme: CardThemeData(
        color: brightness == Brightness.dark ? const Color(0xFF252525) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(fontSize: 12),
        bodySmall: TextStyle(fontSize: 10),
        labelLarge: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _WatchRoot extends StatelessWidget {
  const _WatchRoot();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const WatchShell(child: WatchHomeScreen());
        }
        return const WatchLoginScreen();
      },
    );
  }
}

/// Coque Wear OS : forme ronde/carrée et mode actif/ambiant.
class WatchShell extends StatelessWidget {
  const WatchShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return WatchShape(
      builder: (BuildContext context, WearShape shape, Widget? child) {
        return AmbientMode(
          builder: (BuildContext context, WearMode mode, Widget? child) {
            if (mode == WearMode.ambient) {
              return const WatchAmbientPlaceholder();
            }
            return child!;
          },
          child: this.child,
        );
      },
    );
  }
}

class WatchAmbientPlaceholder extends StatelessWidget {
  const WatchAmbientPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'SportTracker',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
