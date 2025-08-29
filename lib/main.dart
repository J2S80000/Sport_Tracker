import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:SportTracker/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:SportTracker/views/add_program_page.dart';
import 'package:SportTracker/views/calendar_page.dart';
import 'package:SportTracker/views/complete_profile_page.dart';
import 'package:SportTracker/views/home_page.dart';
import 'package:SportTracker/views/history_page.dart';
import 'package:SportTracker/views/login_page.dart';
import 'package:SportTracker/views/add_something_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('fr'), Locale('en'), Locale('es')],
      path: 'assets/langs', // assure-toi que ce dossier existe et contient tes fichiers JSON
      fallbackLocale: const Locale('en'),
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 1;

  final List<Widget> _pages = [
    const AddSomethingPage(),
    const HomePage(),
    const HistoryPage(),
    const CaalendarPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        cardColor: Colors.white,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primarySwatch: Colors.blue,
        cardColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
        ),
      ),
      routes: {
        '/edit-program': (context) {
          final date = ModalRoute.of(context)!.settings.arguments as DateTime;
          return AddProgramPage(initialDate: date);
        },
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (!snapshot.hasData) {
            return const LoginPage();
          }

          final user = snapshot.data!;
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                return const CompleteProfilePage();
              }

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                child: Scaffold(
                  key: ValueKey<int>(_selectedIndex),
                  body: _pages[_selectedIndex],
                  bottomNavigationBar: BottomNavigationBar(
                    currentIndex: _selectedIndex,
                    onTap: _onItemTapped,
                    items: [
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.add_circle_outline),
                        label: tr('add'),
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.home),
                        label: tr('home'),
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.bar_chart),
                        label: tr('data'),
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.date_range),
                        label: tr('calendar'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
