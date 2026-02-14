// calendar_view_model.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class CalendarViewModel extends ChangeNotifier {
  /* ──────────── ÉTAT ──────────── */

  final Map<DateTime, Color> dayColors = {};
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  Map<String, dynamic>? selectedProgram;

  // IA ­— objectif saisi par l’utilisateur (modifiable via TextField côté UI)
  final TextEditingController objectifCtrl =
      TextEditingController(text: 'Amélioration générale');

  bool isGenerating = false;

  /* ──────────── UTILITAIRES ──────────── */

  DateTime normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

  String _dateKey(DateTime d) =>
      normalizeDate(d).toIso8601String().substring(0, 10);

  String _programCollectionPath(String uid) =>
      'users/$uid/programmes'; // raccourci
  Future<void> selectDay(DateTime selected, DateTime focused) async {
    // 1. On met à jour l'UI instantanément UNE SEULE FOIS
    selectedDay = normalizeDate(selected);
    focusedDay = focused;
    selectedProgram = null; // On vide le programme précédent pour éviter un affichage fantôme
    notifyListeners(); 

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // 2. On charge les données Firebase
    final key = _dateKey(selected);
    final snap = await FirebaseFirestore.instance
        .collection(_programCollectionPath(uid))
        .where('jour', isEqualTo: key)
        .limit(1)
        .get();

    // 3. On met à jour l'état avec le résultat UNE SEULE FOIS
    if (snap.docs.isNotEmpty) {
      selectedProgram = snap.docs.first.data();
      _currentProgramId = snap.docs.first.id;
    } else {
      selectedProgram = null;
      _currentProgramId = null;
    }
    notifyListeners(); 
  }

  /* ──────────── IA : Génération batch ──────────── */

  Future<void> generateBatch(BuildContext ctx, {required String range}) async {
    if (selectedDay == null || isGenerating) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    isGenerating = true;
    notifyListeners();

    try {
      final uri = Uri.parse(
          'https://generate-program.quizexec.workers.dev');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'range': range, // 'week' ou 'month'
          'startDate': _dateKey(selectedDay!),
          'objectif': objectifCtrl.text.trim(),
        }),
      );

      if (resp.statusCode != 200) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Erreur réseau ${resp.statusCode}')),
        );
        return;
      }

      final data = jsonDecode(resp.body);
      final List<dynamic> list = data['programs'] ?? [];

      for (final p in list) {
        await _saveProgram(uid, Map<String, dynamic>.from(p));
        final d = normalizeDate(DateTime.parse(p['date']));
        dayColors[d] = Colors.orange; // “à faire”
      }

      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text('✅ ${list.length} programmes générés !'),
        backgroundColor: Colors.green,
      ));

      notifyListeners();
    } catch (e) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text('Erreur : $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> _saveProgram(String uid, Map<String, dynamic> program) async {
    final jour = program['date'] ?? program['jour'] ?? _dateKey(DateTime.now());
    await FirebaseFirestore.instance
        .collection(_programCollectionPath(uid)) 
        .doc(jour)
        .set({...program, 'jour': jour});
  }

  /* ──────────── Couleurs calendrier ──────────── */

  Future<void> loadCalendarColors() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snap = await FirebaseFirestore.instance
        .collection(_programCollectionPath(uid))
        .get();

    dayColors.clear();

    for (var doc in snap.docs) {
      final data = doc.data();
      if (data['jour'] != null && data['exercices'] is List) {
        try {
          final date = normalizeDate(DateTime.parse(data['jour']));
          final ex = List.from(data['exercices']);
          final total = ex.length;
          final done = ex.where((e) => e['accompli'] == true).length;

          dayColors[date] = done == 0
              ? Colors.red
              : done == total
                  ? Colors.green
                  : Colors.orange;
        } catch (_) {}
      }
    }
    notifyListeners();
  }

  /* ──────────── Opérations programme (lecture / suppression / copie) ──────────── */

  String? _currentProgramId;

  // Si on a déjà un programme chargé, on le garde
  String? get currentProgramId => _currentProgramId;
  

  Future<void> loadProgramForDate(DateTime date) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // ✅ Assigner IMMÉDIATEMENT pour que la sélection soit visible
    selectedDay = normalizeDate(date);
    notifyListeners();

    final key = _dateKey(date);
    final snap = await FirebaseFirestore.instance
        .collection(_programCollectionPath(uid))
        .where('jour', isEqualTo: key)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      selectedProgram = snap.docs.first.data();
      _currentProgramId = snap.docs.first.id;
    } else {
      selectedProgram = null;
      _currentProgramId = null;
    }
    notifyListeners();
  }

  Future<void> deleteCurrentProgram(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Utilisateur non connecté.")),
  );
  return;
}

if (_currentProgramId == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Aucun programme sélectionné.")),
  );
  return;
}

    await FirebaseFirestore.instance
        .collection(_programCollectionPath(uid))
        .doc(_currentProgramId)
        .delete();

    selectedProgram = null;
    dayColors.remove(selectedDay);
    _currentProgramId = null;
    notifyListeners();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🗑️ Programme supprimé.")),
    );
  }

  Future<void> copyProgramToDate(DateTime targetDate, BuildContext context) async {
    if (selectedProgram == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final targetKey = _dateKey(targetDate);
    final existing = await FirebaseFirestore.instance
        .collection(_programCollectionPath(uid))
        .where('jour', isEqualTo: targetKey)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Programme existant"),
          content: const Text("Un programme existe déjà à cette date. Remplacer ?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Remplacer")),
          ],
        ),
      );
      if (replace != true) return;
    }

    final newProg = Map<String, dynamic>.from(selectedProgram!)..['jour'] = targetKey;
    await FirebaseFirestore.instance
        .collection(_programCollectionPath(uid))
        .doc(targetKey)
        .set(newProg);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Programme copié au ${targetDate.day}/${targetDate.month}/${targetDate.year}")),
    );

    loadCalendarColors();
  }

  /* ──────────── Divers ──────────── */

  void setFocusedDay(DateTime d) {
    focusedDay = d;
    notifyListeners();
  }
}
