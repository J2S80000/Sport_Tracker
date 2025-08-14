import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ExerciseBlock {
  
  String type = 'shadow_boxing'; // Utilisez maintenant les clés de traduction
  String subType = '';
  String duration = '';
  String distance = '';
  String repetitions = '';
  String intensity = 'moderate';
  String restTime = '';
  String series = '';
  String weight = '';
  bool accompli = false;

  ExerciseBlock();

  // Méthodes de traduction
  static List<String> getTranslatedTypeOptions(BuildContext context) {
    return [
      'street_workout',
      'running',
      'free_cardio',
      'shadow_boxing',
      'active_rest',
      'plyometrics',
      'weight_training',
    ].map((key) => tr(key)).toList();
  }

  static List<String> getTranslatedSubTypeOptions(String type, BuildContext context) {
    final subtypes = subTypeOptions[type] ?? [];
    return subtypes.map((key) => tr(key)).toList(); // Pas de normalisation
  }

  // Getters pour les labels traduits
  String get typeLabel => tr(type); // Utilisez directement la clé
  String get subTypeLabel => subType.isNotEmpty ? tr(subType) : '';
  String get intensityLabel => tr(intensity);
  // Options des types et sous-types (utilisez des clés au lieu de texte)
  static final Map<String, List<String>> subTypeOptions = {
    'street_workout': [
      'pushups',
      'pullups',
      'dips',
      'abs',
      'squats',
      'lunges',
      'sheating',
      'plank',
      'burpees',
      'mountain_climbers',
      'superman',
      'jump_squats',
      'isometric_pullup',
    ],
    'running': [
      'sprint',
      'endurance',
      'interval',
      'hill_climb',
      'downhill',
      'treadmill',
    ],
    'free_cardio': [
      'jumping_jacks',
      'burpees',
      'high_knees',
      'jump_rope',
      'exercise_bike',
      'stepper',
      'stairs',
    ],
    'shadow_boxing': [
      'classic',
      'with_bands',
      'with_weights',
      'defense_dodging',
      'speed_work',
    ],
    'active_rest': [
      'slow_walk',
      'stretching',
      'breathing',
      'mobility',
      'shoulder_rolls',
      'hip_rotation',
    ],
    'plyometrics': [
      'box_jumps',
      'lateral_jumps',
      'tuck_jumps',
      'skaters',
      'jumping_burpees',
    ],
    'weight_training': [
      'bench_press',
      'barbell_squat',
      'deadlift',
      'dumbbell_row',
      'military_press',
      'bicep_curl',
      'tricep_extension',
    ],
  };

  static final List<String> intensityOptions = [
    'low',
    'moderate',
    'high',
  ];

  // Helper method to normalize intensity values
  static String _normalizeIntensity(String intensity) {
    switch (intensity.toLowerCase().trim()) {
      case 'low':
      case 'faible':
      case 'basse':
        return 'low';
      case 'moderate':
      case 'moderee':
      case 'modere':
      case 'moyenne':
        return 'moderate';
      case 'high':
      case 'elevee':
      case 'haute':
      case 'forte':
        return 'high';
      default:
        return 'moderate';
    }
  }

  // Reste du code inchangé...
  Map<String, dynamic> toFirestore() {
    final m = toMap();
    m.removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));
    return m;
  }

  static String _normalize(String s) {
    const Map<String, String> rep = {
      'à':'a','á':'a','â':'a','ä':'a','ã':'a','å':'a','ā':'a',
      'ç':'c',
      'è':'e','é':'e','ê':'e','ë':'e','ē':'e',
      'ì':'i','í':'i','î':'i','ï':'i','ī':'i',
      'ñ':'n',
      'ò':'o','ó':'o','ô':'o','ö':'o','õ':'o','ō':'o',
      'ù':'u','ú':'u','û':'u','ü':'u','ū':'u',
      'ÿ':'y',
      'À':'a','Á':'a','Â':'a','Ä':'a','Ã':'a','Å':'a','Ā':'a',
      'Ç':'c',
      'È':'e','É':'e','Ê':'e','Ë':'e','Ē':'e',
      'Ì':'i','Í':'i','Î':'i','Ï':'i','Ī':'i',
      'Ñ':'n',
      'Ò':'o','Ó':'o','Ô':'o','Ö':'o','Õ':'o','Ō':'o',
      'Ù':'u','Ú':'u','Û':'u','Ü':'u','Ū':'u',
      'Ÿ':'y'
    };
    final sb = StringBuffer();
    for (final ch in s.trim().runes) {
      final c = String.fromCharCode(ch);
      sb.write(rep[c] ?? c.toLowerCase());
    }
    return sb.toString();
  }

  int _estimateMinutesFromDistance(String type, String intensity, String distance) {
    final t = _normalize(type);
    final i = _normalize(intensity);

    final meters = _parseDistanceMeters(distance);
    if (meters <= 0) return 0;

    double paceMinPerKm;
    if (t == 'running' || t == 'free_cardio') {
      switch (i) {
        case 'low':   paceMinPerKm = 7.0;  break;
        case 'high':  paceMinPerKm = 4.5;  break;
        default:      paceMinPerKm = 5.5;  break;
      }
    } else {
      paceMinPerKm = 6.0;
    }

    final km = meters / 1000.0;
    return (km * paceMinPerKm).ceil();
  }

  int _parseDistanceMeters(String distance) {
    final s = distance.toLowerCase().replaceAll(' ', '');
    final kmMatch = RegExp(r'([\d\.]+)km').firstMatch(s);
    if (kmMatch != null) {
      return (double.parse(kmMatch.group(1)!) * 1000).round();
    }
    final mMatch = RegExp(r'(\d+)m').firstMatch(s);
    if (mMatch != null) return int.parse(mMatch.group(1)!);
    final plain = RegExp(r'^\d+$').firstMatch(s);
    if (plain != null) return int.parse(plain.group(0)!);
    return 0;
  }

  static int _secToMin(String raw, {String? type}) {
    if (raw.trim().isEmpty) return 0;
    final n = int.tryParse(raw) ?? 0;
    const _SEC_THRESHOLD = 600;

    if (type != null && type.toLowerCase().contains('shadow_boxing')) {
      return n;
    }

    if (n <= 20) return (n / 60).round();
    if (n > _SEC_THRESHOLD) return (n / 60).round();
    return n;
  }

  static double _getMET(String type, String subType, String intensity) {
    final t = _normalize(type);
    final i = _normalize(intensity);
    double baseMET;

    switch (t) {
      case 'running':        baseMET = 8.5; break;
      case 'free_cardio':    baseMET = 6.0; break;
      case 'shadow_boxing':  baseMET = 7.0; break;
      case 'weight_training': baseMET = 5.0; break;
      case 'street_workout': baseMET = 5.5; break;
      case 'plyometrics':    baseMET = 8.0; break;
      case 'active_rest':    baseMET = 2.0; break;
      default:               baseMET = 4.0;
    }

    switch (i) {
      case 'low':    return baseMET * 0.85;
      case 'high':   return baseMET * 1.25;
      default:       return baseMET;
    }
  }

  int _getDurationEstimate() {
    final regExp = RegExp(r'(\d+)');
    final match = regExp.firstMatch(duration);
    if (match != null) {
      final int? parsed = int.tryParse(match.group(0)!);
      if (parsed != null && parsed > 0) return parsed;
    }

    final int? reps = int.tryParse(repetitions);
    if (reps != null && reps > 0) return (reps / 10).ceil();

    if (distance.trim().isNotEmpty) {
      final mins = _estimateMinutesFromDistance(type, intensity, distance);
      if (mins > 0) return mins;
    }

    return 1;
  }

  double estimateCalories({required double poids}) {
    final met = _getMET(type, subType, intensity);
    final durationMin = _getDurationEstimate();
    int seriesCount = 1;
    if (series.trim().isNotEmpty) {
      seriesCount = int.tryParse(series) ?? 1;
      if (seriesCount < 1) seriesCount = 1;
    }
    final totalMinutes = durationMin * seriesCount;

    return met * poids * (totalMinutes / 60);
  }

  factory ExerciseBlock.fromMap(Map<String, dynamic> map) {
    final block = ExerciseBlock();
    block.type = _convertToKey(map['type'] ?? block.type);
    block.subType = _convertToKey(map['subType'] ?? '');
    block.duration = map['duration']?.toString() ?? '';
    block.distance = map['distance'] ?? '';
    block.repetitions = map['repetitions'] ?? '';
    block.intensity = _convertIntensityToKey(map['intensity'] ?? 'moderate');
    block.restTime = map['restTime'] ?? '';
    block.series = map['series'] ?? '';
    block.weight = map['weight'] ?? '';
    block.accompli = map['accompli'] ?? false;
    return block;
  }
  static String _convertToKey(String text) {
  // Table de correspondance ancien texte -> nouvelle clé
  const conversionTable = {
    'Street Workout': 'street_workout',
    'Course': 'running',
    'Cardio libre': 'free_cardio',
    'Shadow Boxing': 'shadow_boxing',
    'Repos actif': 'active_rest',
    'Plyométrie': 'plyometrics',
    'Renfo avec charges': 'weight_training',
    // Ajoutez toutes les conversions nécessaires
  };
  
  return conversionTable[text] ?? text.toLowerCase();
}

static String _convertIntensityToKey(String intensity) {
  switch (intensity.toLowerCase()) {
    case 'faible': return 'low';
    case 'modérée':
    case 'moderee': return 'moderate';
    case 'élevée':
    case 'elevee': return 'high';
    default: return intensity;
  }
}

  Map<String, dynamic> toMap() => {
    'type': type,
    'subType': subType,
    'duration': duration,
    'distance': distance,
    'repetitions': repetitions,
    'series': series,
    'intensity': intensity,
    'weight': weight,
    'restTime': restTime,
    'accompli': accompli,
  };
}

class ExerciseBlockWidget extends StatelessWidget {
  final ExerciseBlock block;

  ExerciseBlockWidget({required this.block});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(block.typeLabel),        // Will show the translated type
        Text(block.subTypeLabel),     // Will show the translated subtype
        Text(block.intensityLabel),   // Will show the translated intensity
        // Ajoutez d'autres widgets pour afficher les autres propriétés si nécessaire
      ],
    );
  }
}

class ExerciseTypeSelector extends StatefulWidget {
  @override
  _ExerciseTypeSelectorState createState() => _ExerciseTypeSelectorState();
}

class _ExerciseTypeSelectorState extends State<ExerciseTypeSelector> {
  String selectedType = 'shadow_boxing'; // Valeur par défaut

  // Liste des options de type d'exercice (clés uniquement)
  static final List<String> typeOptions = [
    'street_workout',
    'running',
    'free_cardio',
    'shadow_boxing',
    'active_rest',
    'plyometrics',
    'weight_training',
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selectedType, // ex: "developpe_couche"
      onChanged: (val) => setState(() => selectedType = val!),
      items: typeOptions.map((key) => DropdownMenuItem(
        value: key, // toujours la clé !
        child: Text(tr(ExerciseBlock._normalize(key))), // affichage traduit
      )).toList(),
    );
  }
}