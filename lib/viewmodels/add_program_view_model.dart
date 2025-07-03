// add_program_view_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/program.dart';
import '../models/exercise_block.dart';
import '../controllers/program_controller.dart';

class AddProgramViewModel extends ChangeNotifier {
  // ───────────────────────────────────────────── UI state
  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  set setGenerating(bool value) {
    _isGenerating = value;
    notifyListeners();
  }

  final programNameController = TextEditingController();
  final commentController     = TextEditingController();
  final List<ExerciseBlock> exercises = [];
  DateTime selectedDate = DateTime.now();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ NOUVELLE FONCTION : Réinitialiser le formulaire
  void resetForm() {
    programNameController.clear();
    commentController.clear();
    exercises.clear();
    selectedDate = DateTime.now();
    _isGenerating = false;
    notifyListeners();
  }

  // ✅ Constructeur avec réinitialisation automatique
  AddProgramViewModel() {
    resetForm();
  }

  // ───────────────────────────────────────────── PUBLIC helpers
  Future<void> checkExistingProgram(BuildContext ctx) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final key = _dateKey(selectedDate);
    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('programmes')
        .where('jour', isEqualTo: key)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return;

    final data = snap.docs.first.data();

    final confirm = await showDialog<bool>(
  context: ctx,
  builder: (dialogCtx) => AlertDialog(
    title: const Text('Programme existant'),
    content: const Text('Un programme existe déjà pour ce jour. Voulez-vous le remplacer ?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(dialogCtx, false),
        child: const Text('Annuler'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(dialogCtx, true),
        child: const Text('Remplacer'),
      ),
    ],
  ),
);
  if(confirm==true) {
      programNameController.text = data['nom'] ?? '';
    commentController.text     = data['commentaire'] ?? '';
    exercises
      ..clear()
      ..addAll(List<Map<String, dynamic>>.from(data['exercices'] ?? [])
          .map(ExerciseBlock.fromMap));
    notifyListeners();
  } else {
    await _autopickNextDate(ctx);         // ← choisit automatiquement le prochain jour libre
    resetForm();                          // ← vide les champs
  }
  

    if (confirm != true) await _autopickNextDate(ctx);
    notifyListeners();
  }

  Future<void> ensureExerciseExists(
      {required String type, required String subType}) async {
    // Collection « catalogue_exercices »
    final typeId = type.trim();
    final subId = subType.trim();

    final typeRef = _firestore.collection('catalogue_exercices').doc(typeId);
    final subRef = typeRef.collection('sous_types').doc(subId);

    // 1️⃣ Type
    if (!(await typeRef.get()).exists) await typeRef.set({'label': type});

    // 2️⃣ Sous-type (facultatif)
    if (subType.isNotEmpty) {
      final subRef = typeRef.collection('sous_types').doc(subType);
      if (!(await subRef.get()).exists) {
        await subRef.set({'label': subType});
      }
    }
  }

  void addExercise() {
    exercises.add(ExerciseBlock());
    notifyListeners();
  }

  // ✅ NOUVELLE FONCTION : Supprimer un exercice
  void removeExercise(int index) {
    if (index >= 0 && index < exercises.length) {
      exercises.removeAt(index);
      notifyListeners();
    }
  }

  // ✅ NOUVELLE FONCTION : Mettre à jour la date sélectionnée
  void updateSelectedDate(DateTime newDate) {
    selectedDate = newDate;
    notifyListeners();
  }

  Future<void> submit(BuildContext context) async {
    // ▶ ajoute tout ce qui n'existe pas encore dans le catalogue
    await Future.wait(exercises.map((e) =>
        ensureExerciseExists(type: e.type, subType: e.subType)));

    final p = Program(
      nom        : programNameController.text,
      date       : _dateKey(selectedDate),
      commentaire: commentController.text,
      exercices: exercises
        .where((e) => e.type.isNotEmpty)        // évite les blocs vierges
        .map((e) => e.toFirestore())            // nettoie
        .toList(),
    );

    try {
      await ProgramController().saveProgram(p);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Programme enregistré !')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur : $e')),
      );
    }
  }

  // ───────────────────────────────────────────── private
  Future<void> _autopickNextDate(BuildContext ctx) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    DateTime d = selectedDate;

    while (true) {
      d = d.add(const Duration(days: 1));
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('programmes')
          .where('jour', isEqualTo: _dateKey(d))
          .limit(1)
          .get();
      if (snap.docs.isEmpty) break;
    }

    selectedDate = d;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content:
            Text("📅 Nouvelle date : ${d.day}/${d.month}/${d.year}")));
  }

  @override
  void dispose() {
    programNameController.dispose();
    commentController.dispose();
    super.dispose();
  }

  String _dateKey(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().substring(0, 10);
}