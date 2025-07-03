import 'package:flutter/material.dart';

class ExerciseBlock {
  Map<String, dynamic> toFirestore() {
    // Supprime les cles ou la valeur est vide
    final m = toMap();
    m.removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));
    return m;
  }

  /* ------------------------------------------------------------------ */
  /* Helpers de conversion                                              */
  /* ------------------------------------------------------------------ */

  static _secToMin(String raw) {
    if (raw.trim().isEmpty) return 0;
    final n = int.tryParse(raw) ?? 0;
    const _SEC_THRESHOLD = 600; // 10 min => on suppose que c'est en s
    return n > _SEC_THRESHOLD ? (n / 60).round() : n;
    // renvoie toujours des min
  }

  String type = 'Shadow Boxing';
  String subType = '';
  String duration = '';
  String distance = '';
  String repetitions = '';
  String intensity = 'Moderee';
  String restTime = '';
  String series = '';
  String weight = '';
  bool accompli = false;

  ExerciseBlock();
  final List<String> exerciseOptions = ExerciseBlock.subTypeOptions.entries
    .expand((e) => e.value)
    .toList()
  ..sort();

  // Helper method to normalize intensity values
  static String _normalizeIntensity(String intensity) {
    switch (intensity.toLowerCase().trim()) {
      case 'faible':
      case 'basse':
        return 'Faible';
      case 'moderee':
      case 'modere':
      case 'moyenne':
        return 'Moderee';
      case 'elevee':
      case 'haute':
      case 'forte':
        return 'Elevee';
      default:
        print('Unknown intensity: $intensity, defaulting to Moderee');
        return 'Moderee';
    }
  }

  factory ExerciseBlock.fromMap(Map<String, dynamic> map) {
    final block = ExerciseBlock();
    block.type = map['type'] ?? block.type;
    block.subType = map['subType'] ?? '';
    block.duration = _secToMin(map['duration']?.toString() ?? '').toString();
    block.distance = map['distance'] ?? '';
    block.repetitions = map['repetitions'] ?? '';
    block.intensity = _normalizeIntensity(map['intensity'] ?? 'Moderee');
    block.restTime = map['restTime'] ?? '';
    block.series = map['series'] ?? '';
    block.weight = map['weight'] ?? '';
    block.accompli = map['accompli'] ?? false;
    return block;
  }

  Map<String, dynamic> toMap() => {
        'type': type,
        'subType': subType,
        'duration': duration,
        'distance': distance,
        'repetitions': repetitions,
        'series': series,
        'intensity': intensity,
        'restTime': restTime,
        'accompli': false,
      };

  static Map<String, List<String>> subTypeOptions = {
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

  static List<String> intensityOptions = [
    'Faible',
    'Moderee',
    'Elevee',
  ];
}