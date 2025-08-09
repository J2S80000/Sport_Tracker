import 'package:flutter/material.dart';
// exercise_block.dart

class ExerciseBlock {
  Map<String, dynamic> toFirestore() {
  final m = toMap();
  m.removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));
  return m;
}
  
 static String _normalize(String s) {
  // enlève les accents et met en minuscule (sans dépendance externe)
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
  /* ------------------------------------------------------------------ */
  /* Helpers de conversion                                              */
  /* ------------------------------------------------------------------ */
  int _estimateMinutesFromDistance(String type, String intensity, String distance) {
  final t = _normalize(type);
  final i = _normalize(intensity);

  final meters = _parseDistanceMeters(distance);
  if (meters <= 0) return 0;

  double paceMinPerKm;
  if (t == 'course' || t == 'cardio libre') {
    switch (i) {
      case 'faible':   paceMinPerKm = 7.0;  break;
      case 'elevee':   paceMinPerKm = 4.5;  break;
      default:         paceMinPerKm = 5.5;  break;
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
  const _SEC_THRESHOLD = 600; // 10 min => on suppose que c'est en secondes

  // Si type = Shadow Boxing, toujours prendre comme minutes (même pour n <= 20)
  if (type != null && type.toLowerCase().contains('shadow boxing')) {
    return n;
  }

  // Pour les autres, <= 20 => secondes, à convertir
  if (n <= 20) return (n / 60).round();
  if (n > _SEC_THRESHOLD) return (n / 60).round();
  return n; // Sinon minutes
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

  static double _getMET(String type, String subType, String intensity) {
  final t = _normalize(type);
  final i = _normalize(intensity);
  double baseMET;

  switch (t) {
    case 'course':              baseMET = 8.5; break;
    case 'cardio libre':        baseMET = 6.0; break;
    case 'shadow boxing':       baseMET = 7.0; break;
    case 'renfo avec charges':  baseMET = 5.0; break;
    case 'street workout':      baseMET = 5.5; break;
    case 'plyometrie':          baseMET = 8.0; break;
    case 'repos actif':         baseMET = 2.0; break;
    default:                    baseMET = 4.0;
  }

  switch (i) {
    case 'faible':  return baseMET * 0.85;
    case 'elevee':  return baseMET * 1.25;
    default:        return baseMET;
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

  print('DEBUG [$type - $subType] - MET: $met, Durée: $durationMin, Séries: $seriesCount, TotalMinutes: $totalMinutes, Poids: $poids');

  return met * poids * (totalMinutes / 60);
}
factory ExerciseBlock.fromMap(Map<String, dynamic> map) {
  final block = ExerciseBlock();
  block.type = map['type'] ?? block.type;
  block.subType = map['subType'] ?? '';
  block.duration = map['duration']?.toString() ?? '';
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
        'weight': weight,
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