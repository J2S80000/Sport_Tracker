import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/aggregated_data_point.dart';
import '../models/exercise_block.dart';

class HistoryViewModel extends ChangeNotifier {
  final List<String> typeOptions = ExerciseBlock.subTypeOptions.keys.toList()..sort();

  String selectedType = 'Shadow Boxing';
  int _subTypeIndex = 0;

  List<String> get _currentSubTypes => ExerciseBlock.subTypeOptions[selectedType] ?? const [];
  String get selectedSubType => _currentSubTypes.isNotEmpty ? _currentSubTypes[_subTypeIndex] : '';

  void nextSubType() {
    if (_currentSubTypes.isEmpty) return;
    _subTypeIndex = (_subTypeIndex + 1) % _currentSubTypes.length;
    loadData();
  }

  void previousSubType() {
    if (_currentSubTypes.isEmpty) return;
    _subTypeIndex = (_subTypeIndex - 1 + _currentSubTypes.length) % _currentSubTypes.length;
    loadData();
  }

  final List<String> periodOptions = ['Semaine', 'Mois', 'Année', 'Jour'];
  String selectedPeriod = 'Semaine';
  bool onlyCompleted = false;

  void setType(String val) {
    selectedType = val;
    _subTypeIndex = 0;
    loadData();
  }

  void setPeriod(String val) {
    selectedPeriod = val;
    loadData();
  }

  void toggleCompleted(bool val) {
    onlyCompleted = val;
    loadData();
  }

  List<AggregatedDataPoint> dataPoints = [];

  Future<void> loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('programmes')
        .get();

    dataPoints = selectedPeriod == 'Jour'
        ? _aggregateByDay(snapshot.docs)
        : _aggregateByGroup(snapshot.docs);

    notifyListeners();
  }

  List<AggregatedDataPoint> _aggregateByDay(List<QueryDocumentSnapshot> docs) {
    final List<AggregatedDataPoint> list = [];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final dateStr = data['jour']?.substring(0, 10);
      final calories = (data['calories'] ?? 0).toDouble();
      if (dateStr == null) continue;
      final date = DateTime.parse(dateStr);

      for (var e in (data['exercices'] ?? [])) {
        if (e['type'] == selectedType &&
            e['subType'] == selectedSubType &&
            (!onlyCompleted || e['accompli'] == true)) {
          final intensity = _computeIntensity(e);

          list.add(
            AggregatedDataPoint(
              label: DateFormat('dd/MM').format(date),
              avgIntensity: intensity,
              count: 1,
              nom: data['nom'] ?? '',
              commentaire: data['commentaire'] ?? '',
              type: selectedType,
              subType: selectedSubType,
              rawDate: date,
              series: int.tryParse(e['series'] ?? '1'),
              duration: int.tryParse(e['duration'] ?? '1'),
              totalCalories: calories,
              weight: int.tryParse(e['weight'] ?? '0'),
              rest: int.tryParse(e['restTime'] ?? '0'),
            ),
          );
        }
      }
    }

    list.sort((a, b) => a.rawDate.compareTo(b.rawDate));
    return list;
  }

  List<AggregatedDataPoint> _aggregateByGroup(List<QueryDocumentSnapshot> docs) {
    final grouped = <String, List<double>>{};
    final counts = <String, int>{};
    final noms = <String, String>{};
    final commentaires = <String, String>{};
    final caloriesTotals = <String, double>{};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final dateStr = data['jour']?.substring(0, 10);
      if (dateStr == null) continue;
      final date = DateTime.parse(dateStr);
      final key = _getPeriodKey(date);
      final calories = (data['calories'] ?? 0).toDouble();
      caloriesTotals.update(key, (v) => v + calories, ifAbsent: () => calories);

      for (var e in (data['exercices'] ?? [])) {
        if (e['type'] == selectedType &&
            e['subType'] == selectedSubType &&
            (!onlyCompleted || e['accompli'] == true)) {
          final intensity = _computeIntensity(e);
          grouped.putIfAbsent(key, () => []).add(intensity);
          counts.update(key, (v) => v + 1, ifAbsent: () => 1);
          noms[key] = data['nom'] ?? '';
          commentaires[key] = data['commentaire'] ?? '';
        }
      }
    }

    final result = grouped.entries.map((e) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return AggregatedDataPoint(
        label: e.key,
        avgIntensity: avg,
        count: counts[e.key] ?? 1,
        nom: noms[e.key] ?? '',
        commentaire: commentaires[e.key] ?? '',
        type: selectedType,
        subType: selectedSubType,
        rawDate: DateTime.tryParse(e.key.split('-').first) ?? DateTime(2000),
        totalCalories: caloriesTotals[e.key] ?? 0,
      );
    }).toList()
      ..sort((a, b) => a.rawDate.compareTo(b.rawDate));

    return result;
  }

  double _computeIntensity(Map<String, dynamic> e) {
    final type = e['type'] as String? ?? '';
    final intensityS = (e['intensity'] ?? 'Moderee').toString();
    final intensMul = switch (intensityS) {
      'Faible' => 1.0,
      'Elevee' => 2.0,
      _ => 1.5,
    };

    int _i(String k, [int d = 0]) => int.tryParse(e[k]?.toString() ?? '') ?? d;
    double _d(String k, [double d = 0]) => double.tryParse(e[k]?.toString() ?? '') ?? d;

    final series = _i('series', 1);
    final reps = _i('repetitions', 1);
    final dur = _i('duration', 1);
    final rest = _i('restTime', 0);
    final dist = _d('distance', 0);
    final poids = _d('weight', 0);

    double base;

    switch (type) {
      case 'Street Workout':
      case 'Plyometrie':
        base = (series * reps) * (1 + poids / 40);
        base /= (1 + rest / 60);
        break;
      case 'Renfo avec charges':
        base = (series * reps) * (1 + poids / 30);
        base /= (1 + rest / 90);
        break;
      case 'Course':
        final effort = dist > 0 ? dist * 10 : dur.toDouble();
        base = effort / (1 + rest / 120);
        break;
      case 'Cardio libre':
      case 'Shadow Boxing':
        base = (dur * series) / (1 + rest / 90);
        break;
      default:
        base = 0;
    }

    return base * intensMul;
  }

  String _getPeriodKey(DateTime date) {
    switch (selectedPeriod) {
      case 'Année':
        return date.year.toString();
      case 'Mois':
        return DateFormat('yyyy-MM').format(date);
      case 'Semaine':
        final week = (date.day - date.weekday + 10) ~/ 7;
        return '${date.year}-W${week.toString().padLeft(2, '0')}';
      default:
        return '';
    }
  }
}
