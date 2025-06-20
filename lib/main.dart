import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sport_tracker/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sport_tracker/views/calendar_page.dart';

import 'views/add_something_page.dart';
import 'views/home_page.dart';
import 'views/history_page.dart';
import 'views/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 1;

  final List<Widget> _pages =  [
    AddSomethingPage(),
    HomePage(),
    HistoryPage(),
    CaalendarPage(),
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
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
            
          } else if (!snapshot.hasData) {
            return const LoginPage(); // utilisateur non connecté
          } else {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: Scaffold(
                key: ValueKey<int>(_selectedIndex),
                body: _pages[_selectedIndex],
                bottomNavigationBar: BottomNavigationBar(
                  backgroundColor: Colors.white, // ✅ Couleur du fond
                  selectedItemColor: Colors.blue, // Couleur de l’item actif
                  unselectedItemColor: Colors.grey, // Optionnel : pour les autres
                  

                  items: const [
                    
                    BottomNavigationBarItem(
                      icon: Icon(Icons.add_circle_outline),
                      label: 'Ajouter',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Accueil',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.bar_chart),
                      label: 'Données',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.date_range),
                      label: 'Calendrier',
                    ),
                  ],
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                ),
              ),
            );
          }
        },
      ),
    );
  }
  
}
