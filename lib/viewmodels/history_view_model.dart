import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

import '../models/aggregated_data_point.dart';
import '../models/exercise_block.dart';
//history_view_model.dart

class HistoryViewModel extends ChangeNotifier {
  final List<String> typeOptions = ExerciseBlock.subTypeOptions.keys.toList()..sort();
  
  String selectedType = 'shadow_boxing';
  int _subTypeIndex = 0;

  List<String> get _currentSubTypes => ExerciseBlock.subTypeOptions[selectedType] ?? const [];
  String get selectedSubType => _currentSubTypes.isNotEmpty ? _currentSubTypes[_subTypeIndex] : '';
  void _logNonMatchingExercises(Map<String, dynamic> e, String frenchType, String frenchSubType, 
                             String englishType, String englishSubType, bool isCompleted) {
  print("DEBUG: Exercice non correspondant:");
  print("  - Type FR: '$frenchType'");
  print("  - Type EN: '$englishType'");
  print("  - Sous-type FR: '$frenchSubType'");
  print("  - Sous-type EN: '$englishSubType'");
  print("  - Accompli: $isCompleted");
  print("  - Données complètes: $e");
}
  // Tables de correspondance français -> anglais
  static final Map<String, String> _typeTranslations = {
    'Street Workout': 'street_workout',
    'Course': 'running',
    'Cardio libre': 'free_cardio',
    'Shadow Boxing': 'shadow_boxing',
    'Repos actif': 'active_rest',
    'Plyometrie': 'plyometrics',
    'Plyométrie': 'plyometrics',
    'Renforcement avec charges': 'weight_training',
  };

  static final Map<String, String> _subTypeTranslations = {
    // Street Workout
    'Pompes': 'pushups',
    'Tractions': 'pullups',
    'Dips': 'dips',
    'Abdos': 'abs',
    'Squats': 'squats',
    'Fentes': 'lunges',
    'Gainage': 'sheating',
    'Burpees': 'burpees',
    'burpees': 'burpees',
    'Mountain Climbers': 'mountain_climbers',
    'Planche': 'plank',
    'Superman': 'superman',
    'Jump Squats': 'jump_squats',
    'Pull-up isométrique': 'isometric_pullup',
    
    // Running
    'Sprint': 'sprint',
    'Endurance': 'endurance',
    'Fractionne': 'interval',
    'Fractionné': 'interval',
    'Montée de côte': 'hill_climb',
    'Descente': 'downhill',
    'Tapis roulant': 'treadmill',
    
    // Free Cardio
    'Jumping Jacks': 'jumping_jacks',
    'Montée de genoux': 'high_knees',
    'Corde à sauter': 'jump_rope',
    'Vélo': 'exercise_bike',
    'Tapis vélo': 'exercise_bike',
    'Stepper': 'stepper',
    'Escaliers': 'stairs',
    
    // Shadow Boxing
    'Classique': 'classic',
    'Avec élastiques': 'with_bands',
    'Avec poids': 'with_weights',
    'Défense / Esquives': 'defense_dodging',
    'Travail vitesse': 'speed_work',
    
    // Active Rest
    'Marche lente': 'slow_walk',
    'Étirements': 'stretching',
    'Respiration': 'breathing',
    'Mobilité': 'mobility',
    'Roulements d\'épaules': 'shoulder_rolls',
    'Rotation de hanches': 'hip_rotation',
    
    // Plyometrics
    'Sauts sur boite': 'box_jumps',
    'Sauts sur boîte': 'box_jumps',
    'Sauts lateraux': 'lateral_jumps',
    'Sauts latéraux': 'lateral_jumps',
    'Sauts groupés': 'tuck_jumps',
    'Skaters': 'skaters',
    'Burpees sautés': 'jumping_burpees',
    
    // Weight Training
    'Développé couché': 'bench_press',
    'Squat barre': 'barbell_squat',
    'Soulevé de terre': 'deadlift',
    'Rowing haltère': 'dumbbell_row',
    'Développé militaire': 'militairy_press',
    'Curl biceps': 'bicep_curl',
    'Extension triceps': 'tricep_extension',
  };

  // Méthode pour convertir les noms français en clés anglaises
String _translateTypeToEnglish(String frenchType) {
  // First check exact matches
  final exactMatch = _typeTranslations[frenchType];
  if (exactMatch != null) return exactMatch;
  
  // Then check case-insensitive matches
  final lowerType = frenchType.toLowerCase();
  for (var key in _typeTranslations.keys) {
    if (key.toLowerCase() == lowerType) {
      return _typeTranslations[key]!;
    }
  }
  
  // Finally fall back to normalization
  return frenchType.toLowerCase().replaceAll(' ', '_');
}

String _translateSubTypeToEnglish(String frenchSubType) {
  // Remove accents and normalize
  String normalized = frenchSubType
    .toLowerCase()
    .replaceAll(RegExp(r'[éèêë]'), 'e')
    .replaceAll(RegExp(r'[àâä]'), 'a')
    .replaceAll(RegExp(r'[îï]'), 'i')
    .replaceAll(RegExp(r'[ôö]'), 'o')
    .replaceAll(RegExp(r'[ûü]'), 'u')
    .replaceAll(RegExp(r'[ç]'), 'c')
    .replaceAll(' ', '_');

  // Try exact match
  final exactMatch = _subTypeTranslations[frenchSubType];
  if (exactMatch != null) return exactMatch.toLowerCase();

  // Try normalized match
  for (var key in _subTypeTranslations.keys) {
    String keyNorm = key
      .toLowerCase()
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[àâä]'), 'a')
      .replaceAll(RegExp(r'[îï]'), 'i')
      .replaceAll(RegExp(r'[ôö]'), 'o')
      .replaceAll(RegExp(r'[ûü]'), 'u')
      .replaceAll(RegExp(r'[ç]'), 'c')
      .replaceAll(' ', '_');
    if (keyNorm == normalized) {
      return _subTypeTranslations[key]!.toLowerCase();
    }
  }

  // Fallback
  return normalized;
}

  void nextSubType() {
    if (_currentSubTypes.isEmpty) return;
    _subTypeIndex = (_subTypeIndex + 1) % _currentSubTypes.length;
    notifyListeners();
    loadData();
  }

  void previousSubType() {
    if (_currentSubTypes.isEmpty) return;
    _subTypeIndex = (_subTypeIndex - 1 + _currentSubTypes.length) % _currentSubTypes.length;
    notifyListeners();
    loadData();
  }

  final List<String> periodOptions = ['Semaine', 'Mois', 'Année', 'Jour'];
  String selectedPeriod = 'Semaine';
  bool onlyCompleted = false;

  void setType(String val) {
    selectedType = val;
    _subTypeIndex = 0;
    notifyListeners();
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
  bool isLoading = false;

Future<void> loadData() async {
  isLoading = true;
  notifyListeners();
  
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("DEBUG: Aucun utilisateur connecté");
      dataPoints = [];
      isLoading = false;
      notifyListeners();
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('programmes')
        .get();

    // Afficher les données brutes pour débogage
    printRawData(snapshot.docs);

    dataPoints = selectedPeriod == 'Jour'
        ? _aggregateByDay(snapshot.docs)
        : _aggregateByGroup(snapshot.docs);
    
  } catch (e) {
    print("DEBUG: Erreur lors du chargement des données: $e");
    dataPoints = [];
  } finally {
    isLoading = false;
    notifyListeners();
  }
}

 List<AggregatedDataPoint> _aggregateByDay(List<QueryDocumentSnapshot> docs) {
  final List<AggregatedDataPoint> list = [];
  int matchingExercises = 0;
  
  int totalExercises = 0;

  print("DEBUG: Début de l'agrégation par jour -----------------");

  for (var doc in docs) {
    final data = doc.data() as Map<String, dynamic>;
    final dateStr = data['jour']?.toString();
    if (dateStr == null) continue;
    
    print("\nDEBUG: Traitement du document du $dateStr");

    DateTime date;
    try {
      if (dateStr.length >= 10) {
        date = DateTime.parse(dateStr.substring(0, 10));
      } else {
        date = DateTime.parse(dateStr);
      }
    } catch (e) {
      print("DEBUG: Erreur de parsing de date pour $dateStr: $e");
      continue;
    }

    final calories = (data['calories'] ?? 0).toDouble();
    print("DEBUG: Calories totales: $calories");
    

    dynamic exercicesData = data['exercices'] ?? data['exercises'] ?? data['workouts'] ?? data['liste_exercices'];
    if (exercicesData == null) {
      print("DEBUG: Aucun exercice trouvé dans ce document");
      continue;
    }

    print("DEBUG: ${(exercicesData is List ? exercicesData.length : 1)} exercice(s) à analyser");

    for (var e in (exercicesData is List ? exercicesData : [])) {
      totalExercises++;
      
      final frenchType = e['type']?.toString() ?? '';
      final frenchSubType = e['subType']?.toString() ?? '';
      final englishType = _translateTypeToEnglish(frenchType);
      final englishSubType = _translateSubTypeToEnglish(frenchSubType);
      print("Comparaison : $englishType == $selectedType && $englishSubType == $selectedSubType");
      
      bool isCompleted = false;
      if (e['accompli'] != null) {
        isCompleted = e['accompli'] == true || e['accompli'] == 'true';
      } else if (e['completed'] != null) {
        isCompleted = e['completed'] == true || e['completed'] == 'true';
      } else if (e['done'] != null) {
        isCompleted = e['done'] == true || e['done'] == 'true';
      }
      
      // Vérification des correspondances
      bool typeMatch = englishType == selectedType;
      bool subTypeMatch = selectedSubType.isEmpty || englishSubType == selectedSubType;
      bool completedMatch = !onlyCompleted || isCompleted;
      
      print("Comparaison : $englishType == $selectedType && $englishSubType == $selectedSubType");
      
      if (typeMatch && subTypeMatch && completedMatch) {
        matchingExercises++;
        print("\nDEBUG: Exercice CORRESPONDANT #$matchingExercises:");
        print("  - Type: $englishType (FR: $frenchType)");
        print("  - Sous-type: $englishSubType (FR: $frenchSubType)");
        print("  - Statut: ${isCompleted ? 'Complété' : 'Non complété'}");
        print("  - Données: $e");

        final intensity = _computeIntensity(e, englishType);
        print("  - Intensité calculée: $intensity");

        list.add(
          AggregatedDataPoint(
            label: DateFormat('dd/MM').format(date),
            avgIntensity: intensity,
            count: 1,
            nom: data['nom']?.toString() ?? '',
            commentaire: data['commentaire']?.toString() ?? '',
            type: selectedType,
            subType: selectedSubType,
            rawDate: date,
            series: int.tryParse(e['series']?.toString() ?? '1'),
            duration: int.tryParse(e['duration']?.toString() ?? '1'),
            totalCalories: calories,
            weight: int.tryParse(e['weight']?.toString() ?? '0'),
            rest: int.tryParse(e['restTime']?.toString() ?? '0'),
          ),
        );
      } else {
        _logNonMatchingExercises(e, frenchType, frenchSubType, englishType, englishSubType, isCompleted);
      }
    }
  }

  print("\nDEBUG: Résumé final -----------------");
  print("DEBUG: Total exercices analysés: $totalExercises");
  print("DEBUG: Exercices correspondants: $matchingExercises");
  print("DEBUG: Points de données générés: ${list.length}");
  print("DEBUG: Exercices correspondants: $matchingExercises/$totalExercises");

  
  list.sort((a, b) => a.rawDate.compareTo(b.rawDate));
  return list;
}
void printRawData(List<QueryDocumentSnapshot> docs) {
  print("\nDEBUG: DONNÉES BRUTES -----------------");
  for (var doc in docs) {
    final data = doc.data() as Map<String, dynamic>;
    print("\nDocument ID: ${doc.id}");
    print("Date: ${data['jour']}");
    print("Nom: ${data['nom']}");
    print("Calories: ${data['calories']}");
    
    dynamic exercices = data['exercices'] ?? data['exercises'] ?? data['workouts'] ?? data['liste_exercices'];
    if (exercices is List) {
      print("Nombre d'exercices: ${exercices.length}");
      for (var e in exercices) {
        final frenchSubType = e['subType']?.toString() ?? '';
        final englishSubType = _translateSubTypeToEnglish(frenchSubType);
        print("  - Sous-type FR: '$frenchSubType' | EN: '$englishSubType' | Sélectionné: '$selectedSubType'");
        print("  - Type: ${e['type']}");
        print("  - Accompli: ${e['accompli'] ?? e['completed'] ?? e['done']}");
        print("  - Données: $e");
      }
    }
  }
}
  List<AggregatedDataPoint> _aggregateByGroup(List<QueryDocumentSnapshot> docs) {
    final grouped = <String, List<double>>{};
    final counts = <String, int>{};
    final noms = <String, String>{};
    final commentaires = <String, String>{};
    final caloriesTotals = <String, double>{};
    int matchingExercises = 0;
    int totalExercises = 0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final dateStr = data['jour']?.toString();
      if (dateStr == null) continue;
      
      DateTime date;
      try {
        if (dateStr.length >= 10) {
          date = DateTime.parse(dateStr.substring(0, 10));
        } else {
          date = DateTime.parse(dateStr);
        }
      } catch (e) {
        continue;
      }
      
      final key = _getPeriodKey(date);
      final calories = (data['calories'] ?? 0).toDouble();
      caloriesTotals.update(key, (v) => v + calories, ifAbsent: () => calories);

      // Obtenir les exercices avec différents noms de champs possibles
      dynamic exercicesData = data['exercices'] ?? data['exercises'] ?? data['workouts'] ?? data['liste_exercices'];
      if (exercicesData == null) continue;

      for (var e in (exercicesData is List ? exercicesData : [])) {
        totalExercises++;
        
        // Obtenir type et sous-type en français puis les convertir
        final frenchType = e['type']?.toString() ?? '';
        final frenchSubType = e['subType']?.toString() ?? '';
        
        // Convertir en anglais pour la comparaison
        final englishType = _translateTypeToEnglish(frenchType);
        final englishSubType = _translateSubTypeToEnglish(frenchSubType);
        
        // Obtenir le statut accompli
        bool isCompleted = false;
        if (e['accompli'] != null) {
          isCompleted = e['accompli'] == true || e['accompli'] == 'true';
        } else if (e['completed'] != null) {
          isCompleted = e['completed'] == true || e['completed'] == 'true';
        } else if (e['done'] != null) {
          isCompleted = e['done'] == true || e['done'] == 'true';
        }
        
        bool typeMatch = englishType == selectedType;
        bool subTypeMatch = selectedSubType.isEmpty || englishSubType == selectedSubType;
        bool completedMatch = !onlyCompleted || isCompleted;
        
        if (typeMatch && subTypeMatch && completedMatch) {
          matchingExercises++;
          final intensity = _computeIntensity(e, englishType);
          grouped.putIfAbsent(key, () => []).add(intensity);
          counts.update(key, (v) => v + 1, ifAbsent: () => 1);
          noms[key] = data['nom']?.toString() ?? '';
          commentaires[key] = data['commentaire']?.toString() ?? '';
        }
      }
    }

    print("DEBUG: Exercices correspondants (groupés): $matchingExercises/$totalExercises");

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
        rawDate: _parseKeyToDate(e.key),
        totalCalories: caloriesTotals[e.key] ?? 0,
      );
    }).toList()
      ..sort((a, b) => a.rawDate.compareTo(b.rawDate));

    return result;
  }

  DateTime _parseKeyToDate(String key) {
    try {
      if (key.contains('-W')) {
        final parts = key.split('-W');
        final year = int.parse(parts[0]);
        final week = int.parse(parts[1]);
        return DateTime(year, 1, 1).add(Duration(days: (week - 1) * 7));
      } else if (key.contains('-')) {
        return DateTime.parse('$key-01');
      } else {
        return DateTime(int.parse(key), 1, 1);
      }
    } catch (e) {
      return DateTime(2000);
    }
  }

  double _computeIntensity(Map<String, dynamic> e, String englishType) {
    final intensityS = e['intensity']?.toString() ?? 'moderate';
    
    final normalizedIntensity = ExerciseBlock.normalizeIntensity(intensityS);
    final intensMul = switch (normalizedIntensity) {
      'low' => 1.0,
      'high' => 2.0,
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

    // Utiliser le type anglais converti
    switch (englishType) {
      case 'street_workout':
      case 'plyometrics':
        base = (series * reps) * (1 + poids / 40);
        base /= (1 + rest / 60);
        break;
      case 'weight_training':
        base = (series * reps) * (1 + poids / 30);
        base /= (1 + rest / 90);
        break;
      case 'running':
        final effort = dist > 0 ? dist * 10 : dur.toDouble();
        base = effort / (1 + rest / 120);
        break;
      case 'free_cardio':
      case 'shadow_boxing':
        base = (dur * series) / (1 + rest / 90);
        break;
      case 'active_rest':
        base = dur.toDouble() / 2;
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
        final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
        final weekNumber = ((dayOfYear - date.weekday + 10) / 7).floor();
        return '${date.year}-W${weekNumber.toString().padLeft(2, '0')}';
      default:
        return '';
    }
  }
}