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
    'Street Workout': ['Pompes', 'Tractions', 'Dips', 'Abdos'],
    'Course': [],
    'Cardio libre': [],
    'Shadow Boxing': [],
    'Repos actif': [],
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
    required int? plannedDuration,
    required int? performedSeries,
    required int? performedDuration,
  }) {
    if (plannedSeries == null || plannedDuration == null || plannedSeries == 0 || plannedDuration == 0) {
      return 0;
    }
    final seriesRatio = (performedSeries ?? 0) / plannedSeries;
    final durationRatio = (performedDuration ?? 0) / plannedDuration;
    return ((seriesRatio + durationRatio) / 2 * 100).clamp(0, 100);
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
    final index = exercices.indexWhere((e) => e['type'] == model.type);
    if (index == -1) {
      return 'Aucun exercice correspondant dans le programme du jour.';
    }

    final ex = exercices[index];
    final plannedSeries = int.tryParse(ex['series'] ?? '');
    final plannedDuration = int.tryParse(ex['duration'] ?? '');
    final performedSeries = int.tryParse(model.series);
    final performedDuration = int.tryParse(model.duration);

    final percent = calculateCompletion(
      plannedSeries: plannedSeries,
      plannedDuration: plannedDuration,
      performedSeries: performedSeries,
      performedDuration: performedDuration,
    ).round();

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

    if (confirmed != true) return null;

    exercices[index] = {
      ...ex,
      ...model.toMap(),
    };

    await doc.reference.update({'exercices': exercices});
    return '✅ Performance enregistrée et exercice mis à jour à $percent%.';
  }
}
