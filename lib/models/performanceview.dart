import 'package:SportTracker/models/exercise_block.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PerformanceModel {
  String type;
  String subType;
  String duration;
  String distance;
  String repetitions;
  String series;
  String restTime;
  String intensity;
  String commentaire;

  PerformanceModel({
    this.type = 'Street Workout',
    this.subType = '',
    this.duration = '',
    this.distance = '',
    this.repetitions = '',
    this.series = '',
    this.restTime = '',
    this.intensity = '',
    this.commentaire = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'subType': subType,
      'duration': duration,
      'distance': distance,
      'repetitions': repetitions,
      'series': series,
      'restTime': restTime,
      'intensité': intensity,
      'commentaire': commentaire,
      'accompli': true,
    };
  }
}

class AddPerformanceViewModel extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();
  final model = PerformanceModel();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

 final Map<String, List<String>> subTypeOptions = {
  'Street Workout': [
    'Pompes',
    'Tractions',
    'Dips',
    'Abdos',
    'Squats',
    'Fentes',
    'Gainage',
    'Burpees',
    'Mountain Climbers',
    'Planche',
    'Superman',
    'Jump Squats',
    'Pull-up isometrique',
  ],
  'Course': [
    'Sprint',
    'Endurance',
    'Fractionne',
    'Montee de cote',
    'Descente',
    'Tapis roulant',
  ],
  'Cardio libre': [
    'Jumping Jacks',
    'Burpees',
    'High Knees',
    'Montee de genoux',
    'Corde a sauter',
    'Tapis velo',
    'Stepper',
    'Escaliers',
  ],
  'Shadow Boxing': [
    'Classique',
    'Avec elastiques',
    'Avec poids',
    'Defense / Esquives',
    'Travail vitesse',
  ],
  'Repos actif': [
    'Marche lente',
    'Etirements',
    'Respiration',
    'Mobilite',
    'Roulements d\'epaules',
    'Rotation de hanches',
  ],
  'Plyometrie': [
    'Sauts sur boite',
    'Sauts lateraux',
    'Sauts groupes',
    'Skaters',
    'Burpees sautes',
  ],
  'Renfo avec charges': [
    'Developpe couche',
    'Squat barre',
    'Souleve de terre',
    'Rowing haltere',
    'Developpe militaire',
    'Curl biceps',
    'Extension triceps',
  ],
};

  final List<String> intensityOptions = ['Faible', 'Modérée', 'Élevée'];

  void updateField({
    String? type,
    String? subType,
    String? duration,
    String? distance,
    String? repetitions,
    String? series,
    String? restTime,
    String? intensity,
    String? weight,
    String? commentaire,
  }) {
    if (type != null) {
      model.type = type;
      model.subType = '';
      model.duration = '';
      model.distance = '';
      model.repetitions = '';
      model.series = '';
      model.restTime = '';
    }
    if (subType != null) model.subType = subType;
    if (duration != null) model.duration = duration;
    if (distance != null) model.distance = distance;
    if (repetitions != null) model.repetitions = repetitions;
    if (series != null) model.series = series;
    if (restTime != null) model.restTime = restTime;
    if (intensity != null) model.intensity = intensity;
    if (commentaire != null) model.commentaire = commentaire;

    notifyListeners();
  }

double calculateCompletion({
  required int? plannedSeries,
  required int? plannedReps,
  required int? plannedDuration,
  required int? performedSeries,
  required int? performedReps,
  required int? performedDuration,
}) {
  final ratios = <double>[];

  if (plannedSeries != null && plannedSeries > 0) {
    ratios.add((performedSeries ?? 0) / plannedSeries);
  }

  if (plannedReps != null && plannedReps > 0) {
    ratios.add((performedReps ?? 0) / plannedReps);
  }

  if (plannedDuration != null && plannedDuration > 0) {
    ratios.add((performedDuration ?? 0) / plannedDuration);
  }

  if (ratios.isEmpty) return 0;

  final avg = ratios.reduce((a, b) => a + b) / ratios.length;
  return (avg * 100).clamp(0, 100);
}



  Future<String?> submitPerformance(BuildContext context) async {
  if (!formKey.currentState!.validate()) return 'Formulaire invalide.';

  final user = _auth.currentUser;
  if (user == null) return 'Utilisateur non connecté.';

  final now = DateTime.now();
  final dateKey = DateTime(now.year, now.month, now.day).toIso8601String().substring(0, 10);

  final programmeSnap = await _firestore
      .collection('users')
      .doc(user.uid)
      .collection('programmes')
      .where('jour', isGreaterThanOrEqualTo: dateKey)
      .where('jour', isLessThan: dateKey + 'T23:59:59')
      .limit(1)
      .get();

  if (programmeSnap.docs.isEmpty) {
    return 'Aucun programme aujourd\'hui pour valider cette performance.';
  }

  final doc = programmeSnap.docs.first;
  final data = doc.data();
  final exercices = List<Map<String, dynamic>>.from(data['exercices'] ?? []);

  final index = exercices.indexWhere((e) =>
    ExerciseBlock.normalize(e['type'] ?? '') == ExerciseBlock.normalize(model.type) &&
    ExerciseBlock.normalize(e['subType'] ?? '') == ExerciseBlock.normalize(model.subType)
  );

  // 🔹 Récupère les valeurs prévues AVANT modification
  final plannedSeries   = index != -1 ? int.tryParse(exercices[index]['series']?.toString() ?? '') : null;
  final plannedReps     = index != -1 ? int.tryParse(exercices[index]['repetitions']?.toString() ?? '') : null;
  final plannedDuration = index != -1 ? int.tryParse(exercices[index]['duration']?.toString() ?? '') : null;

  // 🔹 Valeurs réalisées (issues du formulaire)
  final performedSeries   = int.tryParse(model.series);
  final performedReps     = int.tryParse(model.repetitions);
  final performedDuration = int.tryParse(model.duration);

  // 🔹 Calcul du % d'accomplissement
  final percent = calculateCompletion(
    plannedSeries: plannedSeries,
    plannedReps: plannedReps,
    plannedDuration: plannedDuration,
    performedSeries: performedSeries,
    performedReps: performedReps,
    performedDuration: performedDuration,
  ).round();

  print("DEBUG -> Planned series: $plannedSeries, reps: $plannedReps, duration: $plannedDuration");
  print("DEBUG -> Performed series: $performedSeries, reps: $performedReps, duration: $performedDuration");
  print("DEBUG -> Percent: $percent%");

  // 🔹 Confirmation utilisateur AVANT sauvegarde
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Valider la performance ?"),
      content: Text("Cette performance correspond à $percent% de l'objectif.\nRemplacer et marquer comme accompli ?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Valider")),
      ],
    ),
  );

  if (confirmed != true) return null; // ❌ rien n'est sauvegardé si annulé

  // 🔹 Mise à jour Firestore seulement si confirmé
  if (index == -1) {
    exercices.add(model.toMap());
  } else {
    exercices[index] = {
      ...exercices[index],
      ...model.toMap(),
    };
  }

  await doc.reference.update({'exercices': exercices});

  return '✅ Performance enregistrée et exercice mis à jour à $percent%.';
}


}
