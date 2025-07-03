import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarViewModel extends ChangeNotifier {
  
  Map<DateTime, Color> dayColors = {};
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  Map<String, dynamic>? selectedProgram;

  DateTime normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);
  Future<void> copyProgramToDate(DateTime targetDate, BuildContext context) async {
  if (selectedProgram == null) return;

  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  String _dateKey(DateTime d) =>
    DateTime(d.year, d.month, d.day).toIso8601String().substring(0, 10);

  final targetKey = _dateKey(targetDate);
  final existingSnap = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('programmes')
      .where('jour', isEqualTo: targetKey)
      .limit(1)
      .get();

  if (existingSnap.docs.isNotEmpty) {
    final replace = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Programme existant"),
        content: const Text("Un programme existe déjà à cette date. Voulez-vous le remplacer ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Remplacer")),
        ],
      ),
    );
    if (replace != true) return;
  }

  // Copier le programme actuel
  final newProgram = Map<String, dynamic>.from(selectedProgram!);
  newProgram['jour'] = targetKey;

  await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('programmes')
      .doc(targetKey)
      .set(newProgram);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("✅ Programme copié au ${targetDate.day}/${targetDate.month}/${targetDate.year}")),
  );

  loadCalendarColors(); // Rechargement des couleurs après ajout
}


  String _formatDateForFirestore(DateTime date) {
    return DateTime(date.year, date.month, date.day).toIso8601String().substring(0, 10);
  }

  Future<void> loadCalendarColors() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('programmes')
        .get();

    Map<DateTime, Color> colors = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['jour'] != null && data['exercices'] is List) {
        try {
          final date = normalizeDate(DateTime.parse(data['jour']));
          final List exercices = data['exercices'];

          int total = exercices.length;
          int done = exercices.where((e) => e['accompli'] == true).length;

          if (total == 0 || done == 0) {
            colors[date] = Colors.red;
          } else if (done == total) {
            colors[date] = Colors.green;
          } else {
            colors[date] = Colors.orange;
          }
        } catch (_) {}
      }
    }

    dayColors = colors;
    notifyListeners();
  }

  Future<void> loadProgramForDateBasic(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
  
    final normalized = normalizeDate(date);
    final dateKey = _formatDateForFirestore(normalized);
  
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('programmes')
        .where('jour', isEqualTo: dateKey)
        .get();
  
    selectedDay = normalized;
    selectedProgram = snapshot.docs.isNotEmpty ? snapshot.docs.first.data() : null;
    notifyListeners();
  }

  void setFocusedDay(DateTime day) {
    focusedDay = day;
    notifyListeners();
  }
  String get currentProgramId => _currentProgramId!;
String? _currentProgramId;

Future<void> loadProgramForDate(DateTime date) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final normalized = normalizeDate(date);
  final dateKey = _formatDateForFirestore(normalized);

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('programmes')
      .where('jour', isEqualTo: dateKey)
      .get();

  selectedDay = normalized;

  if (snapshot.docs.isNotEmpty) {
    selectedProgram = snapshot.docs.first.data();
    _currentProgramId = snapshot.docs.first.id;
  } else {
    selectedProgram = null;
    _currentProgramId = null;
  }

  notifyListeners();
}

Future<void> deleteCurrentProgram(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || _currentProgramId == null) return;

  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('programmes')
      .doc(_currentProgramId)
      .delete();

  selectedProgram = null;
  _currentProgramId = null;
  dayColors.remove(selectedDay);
  notifyListeners();

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("🗑️ Programme supprimé.")),
  );
}

}
