import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/aggregated_data_point.dart';
import '../models/exercise_block.dart';

class HistoryViewModel extends ChangeNotifier {
  /* ───────────────────────────────────────────────────────────── */
  /* Options de type  (menu déroulant)                            */
  /* ───────────────────────────────────────────────────────────── */
  final List<String> typeOptions =
      ExerciseBlock.subTypeOptions.keys.toList()..sort();

  String selectedType = 'Shadow Boxing';

  /* ───────────────────────────────────────────────────────────── */
  /* Gestion du sous-type (flèches)                               */
  /* ───────────────────────────────────────────────────────────── */
  int _subTypeIndex = 0;

  /// Liste courante des sous-types pour le type sélectionné
  List<String> get _currentSubTypes =>
      ExerciseBlock.subTypeOptions[selectedType] ?? const [];

  /// Sous-type actuellement choisi
  String get selectedSubType =>
      _currentSubTypes.isNotEmpty ? _currentSubTypes[_subTypeIndex] : '';

  void nextSubType() {
    if (_currentSubTypes.isEmpty) return;
    _subTypeIndex = (_subTypeIndex + 1) % _currentSubTypes.length;
    loadData();
  }

  void previousSubType() {
    if (_currentSubTypes.isEmpty) return;
    _subTypeIndex =
        (_subTypeIndex - 1 + _currentSubTypes.length) % _currentSubTypes.length;
    loadData();
  }

  /* ───────────────────────────────────────────────────────────── */
  /* Autres paramètres (période, accompli)                        */
  /* ───────────────────────────────────────────────────────────── */
  final List<String> periodOptions = ['Semaine', 'Mois', 'Année', 'Jour'];
  String selectedPeriod = 'Semaine';
  bool onlyCompleted = false;

  void setType(String val) {
    selectedType = val;
    _subTypeIndex = 0; // on repart au 1ᵉʳ sous-type
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

  /* ───────────────────────────────────────────────────────────── */
  /* Chargement & agrégation                                      */
  /* ───────────────────────────────────────────────────────────── */
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

  List<AggregatedDataPoint> _aggregateByDay(
      List<QueryDocumentSnapshot> docs) {
    final List<AggregatedDataPoint> list = [];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final dateStr = data['jour']?.substring(0, 10);
      if (dateStr == null) continue;
      final date = DateTime.parse(dateStr);

      for (var e in (data['exercices'] ?? [])) {
        if (e['type'] == selectedType &&
            e['subType'] == selectedSubType &&
            (!onlyCompleted || e['accompli'] == true)) {
          final intensity = _computeIntensity(
            int.tryParse(e['series'] ?? '1') ?? 1,
            int.tryParse(e['duration'] ?? '1') ?? 1,
            int.tryParse(e['restTime'] ?? '0') ?? 0,
          );

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
              rest: int.tryParse(e['restTime'] ?? '0'),
            ),
          );
        }
      }
    }

    list.sort((a, b) => a.rawDate.compareTo(b.rawDate));
    return list;
  }

  List<AggregatedDataPoint> _aggregateByGroup(
      List<QueryDocumentSnapshot> docs) {
    final grouped = <String, List<double>>{};
    final counts = <String, int>{};
    final noms = <String, String>{};
    final commentaires = <String, String>{};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final dateStr = data['jour']?.substring(0, 10);
      if (dateStr == null) continue;
      final date = DateTime.parse(dateStr);
      final key = _getPeriodKey(date);

      for (var e in (data['exercices'] ?? [])) {
        if (e['type'] == selectedType &&
            e['subType'] == selectedSubType &&
            (!onlyCompleted || e['accompli'] == true)) {
          final intensity = _computeIntensity(
            int.tryParse(e['series'] ?? '1') ?? 1,
            int.tryParse(e['duration'] ?? '1') ?? 1,
            int.tryParse(e['restTime'] ?? '0') ?? 0,
          );
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
        rawDate:
            DateTime.tryParse(e.key.split('-').first) ?? DateTime(2000),
      );
    }).toList()
      ..sort((a, b) => a.rawDate.compareTo(b.rawDate));

    return result;
  }

  /* Utilitaires */
  double _computeIntensity(int series, int duration, int rest) =>
      (series * duration) / (1 + rest / 60);

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
