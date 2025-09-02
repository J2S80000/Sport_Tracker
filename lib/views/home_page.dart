import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:SportTracker/views/layout_page.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:SportTracker/models/exercise_block.dart';
import 'package:easy_localization/easy_localization.dart';

// home_page.dart


int? stepCount;
Stream<StepCount>? _stepCountStream;
int? totalStepsToday;
bool hasFirstEventProcessed = false;
int? stepsAtStartOfDay;

late String todaybd;
DateTime? currentDayDate;


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}
int calculateBMR(int poidsKg) {
  // Approximation simple : 1 kcal par kg par heure
  return (poidsKg * 24).round();
}

class _HomePageState extends State<HomePage> {
    Stream<StepCount>? _stepCountStream;
  int? totalStepsToday;
  int? stepsAtStartOfDay;
  late TextEditingController _caloriesController;
  String todaybd = DateTime.now().toIso8601String().substring(0, 10); // "2025-06-21"
  Map<String, dynamic>? programData;
  bool isLoading = true;
double calculateCalorieDeficit() {
  if (programData == null) return 0;
  
  final caloriesDepensees = (programData?['calories'] ?? 0).toDouble();
  final caloriesIngerees = (programData?['calories_ingerees'] ?? 0).toDouble();
  
  return caloriesDepensees - caloriesIngerees; // Positif = déficit, négatif = surplus
}

@override
void initState() {
  super.initState();

  _caloriesController = TextEditingController();
  final now = DateTime.now();
  todaybd = now.toIso8601String().substring(0, 10);
  currentDayDate = DateTime(now.year, now.month, now.day);

  fetchTodayProgram();
  initStepCounter();
}

void dispose() {
  _caloriesController.dispose();
  super.dispose();
}


void onStepCount(StepCount event) async {
  final now = DateTime.now();
  final currentDay = DateTime(now.year, now.month, now.day);
  final prefs = await SharedPreferences.getInstance();
  final storedDate = prefs.getString('stepDate');
  final storedStart = prefs.getInt('stepStart');

  if (storedDate == todaybd && storedStart != null && stepsAtStartOfDay == null) {
    stepsAtStartOfDay = storedStart;
    print('Valeur restaurée depuis cache : $stepsAtStartOfDay');
  }

  if (storedDate != todaybd) {
    currentDayDate = currentDay;
    todaybd = now.toIso8601String().substring(0, 10);
    stepsAtStartOfDay = event.steps;

    await prefs.setString('stepDate', todaybd);
    await prefs.setInt('stepStart', stepsAtStartOfDay!);

    print('Réinitialisation à $stepsAtStartOfDay pour $todaybd');
  }

  // ✅ Toujours calculer les pas dès le premier événement
  totalStepsToday = event.steps - (stepsAtStartOfDay ?? event.steps);
  await prefs.setInt('lastKnownSteps', event.steps);

Text(tr('steps_today', args: [totalStepsToday.toString()]));
  setState(() {});

  await updateStepsAndCalories();
}

void initStepCounter() async {
  final status = await Permission.activityRecognition.request();
  if (!status.isGranted) {
    print('Permission non accordée : $status');
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  final storedDate = prefs.getString('stepDate');
  final storedStart = prefs.getInt('stepStart');

  if (storedDate == todaybd && storedStart != null) {
    stepsAtStartOfDay = storedStart;
    final lastKnownSteps = prefs.getInt('lastKnownSteps') ?? storedStart;
    totalStepsToday = lastKnownSteps - storedStart;
    print('Restauration immédiate des pas: $totalStepsToday');

    setState(() {}); 
    // ✅ Mettre Firestore à jour directement même sans nouvel événement
    await updateStepsAndCalories();
  }

  _stepCountStream = Pedometer.stepCountStream;
  _stepCountStream!.listen(onStepCount).onError(onStepCountError);
}




int calculateCalories(int steps, int poidsKg, int tailleCm) {
  // Estimation distance en km
  double stepLengthMeters = tailleCm * 0.414 / 100; // longueur de foulée estimée
  double distanceKm = (steps * stepLengthMeters) / 1000;

  double speedKmH = 4; // vitesse moyenne marche modérée
  double durationHours = distanceKm / speedKmH;

  double met = 3.5; // MET pour marche modérée
  double calories = met * poidsKg * durationHours;

  return calories.round();
}

void onStepCountError(error) {
  print('Erreur de podomètre : $error');
}

  Future<void> fetchTodayProgram() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('programmes')
        .where('jour', isGreaterThanOrEqualTo: todaybd)
        .where('jour', isLessThan: "${todaybd}T23:59:59.999")
        .get();

    if (snapshot.docs.isNotEmpty) {
      // ✅ CORRECTION : Chercher d'abord un programme manuel
      QueryDocumentSnapshot<Map<String, dynamic>>? manualProgram;
      
      try {
        manualProgram = snapshot.docs.firstWhere(
          (doc) {
            final data = doc.data();
            return data['autoGenerated'] != true;
          },
        );
      } catch (e) {
        // Aucun programme manuel trouvé, prendre le premier disponible
        manualProgram = snapshot.docs.first;
      }

      final data = manualProgram.data();
      setState(() {
  programData = data;
  _caloriesController.text = (data['calories_ingerees'] ?? 0).toString();
  isLoading = false;
});
    } else {
      // ✅ Pas de programme => afficher quand même les pas et calories
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final poids = userDoc.data()?['poids'] ?? 60;
        final taille = userDoc.data()?['taille'] ?? 170;
        final caloriesPas = calculateCalories(totalStepsToday ?? 0, poids, taille);
        
        setState(() {
          programData = {
            'nom': 'Aucun programme',
            'commentaire': '',
            'jour': todaybd,
            'pas': totalStepsToday ?? 0,
            'calories_pas': caloriesPas,
            'calories_exercices': 0,
            'calories': caloriesPas,
            'exercices': [],
            "calories_ingerees": 0,
            'autoGenerated': true,
          };
          isLoading = false;
        });
      }
    }
  } catch (e) {
    print('Erreur de chargement : $e');
    setState(() => isLoading = false);
  }
}
// Méthode pour mettre à jour les calories ingérées
Future<void> updateCaloriesIngerees(int calories) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('programmes')
        .where('jour', isGreaterThanOrEqualTo: todaybd)
        .where('jour', isLessThan: "${todaybd}T23:59:59.999")
        .get();

    if (snapshot.docs.isNotEmpty) {
      final docRef = snapshot.docs.first.reference;
      await docRef.update({'calories_ingerees': calories});
      
      setState(() {
        programData!['calories_ingerees'] = calories;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('calories_updated'))),
      );
    }
  } catch (e) {
    print('Erreur mise à jour calories ingérées : $e');
  }
}
Future<void> updateStepsAndCalories() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  totalStepsToday ??= 0;

  final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  final poids = (userDoc.data()?['poids'] ?? 60);
  final bmrCalories = calculateBMR(
    poids is int ? poids : int.tryParse(poids.toString()) ?? 60,
  );
  final taille = userDoc.data()?['taille'] ?? 170;

  final caloriesPas = calculateCalories(
    (totalStepsToday ?? 0).toInt(),
    poids is int ? poids : int.tryParse(poids.toString()) ?? 60,
    taille is int ? taille : int.tryParse(taille.toString()) ?? 170,
  );

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('programmes')
      .where('jour', isEqualTo: todaybd)
      .get();

  if (snapshot.docs.isNotEmpty) {
    final program = snapshot.docs.first;
    final docRef = program.reference;
    final data = program.data();

    final List exercices = data['exercices'] ?? [];
    final caloriesExos = calculerCaloriesExercices(
      exercices,
      poids: (poids is int ? poids.toDouble() : double.tryParse(poids.toString()) ?? 60.0),
    );
    final totalCalories = caloriesPas + caloriesExos;

    // Conserver les calories ingérées existantes ou mettre 0 par défaut
    final caloriesIngerees = data['calories_ingerees'] ?? 0;

    await docRef.update({
      'pas': (totalStepsToday ?? 0).toInt(),
      'calories_pas': caloriesPas,
      'calories_exercices': caloriesExos,
      'calories_repos': bmrCalories,
      'calories': caloriesPas + caloriesExos + bmrCalories,
      'calories_ingerees': caloriesIngerees, // 🆕 Ajout du champ calories ingérées
    });

    print("Programme mis à jour avec $totalStepsToday pas, $caloriesExos kcal exos !");
  } else {
    // Création d'un nouveau programme auto-généré
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('programmes')
        .doc(todaybd)
        .set({
      'nom': 'Programme auto-généré',
      'commentaire': '',
      'jour': todaybd,
      'date': DateTime.now(),
      'pas': (totalStepsToday ?? 0).toInt(),
      'calories_pas': caloriesPas,
      'calories_exercices': 0,
      'calories_repos': bmrCalories,
      'calories': caloriesPas + bmrCalories,
      'calories_ingerees': 0, // 🆕 Ajout du champ calories ingérées par défaut
      'exercices': [],
      'autoGenerated': true,
    });

    print("Programme auto-généré créé avec $totalStepsToday pas !");
  }

  await fetchTodayProgram();
}
@override
Widget build(BuildContext context) {
  return LayoutPage(
    title: tr('program_of_the_day'),
    child: isLoading
        ? const Center(child: CircularProgressIndicator())
        : programData == null
            ? Center(
                child: Text(tr('no_program_today')),
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Zone podomètre
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    tr('steps_today'),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text('${totalStepsToday ?? 0}', style: const TextStyle(fontSize: 20)),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    tr('calories_burned'),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${(programData?['calories_pas'] ?? 0) + (programData?['calories_exercices'] ?? 0)} kcal',
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  Text("👟 : ${programData?['calories_pas'] ?? 0} kcal"),
                                  Text("Exos : ${programData?['calories_exercices'] ?? 0} kcal"),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Widget pour saisir les calories ingérées
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('calories_consumed'),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
  Expanded(
    child: TextField(
      controller: _caloriesController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: tr('calories_consumed'),
        suffixText: 'kcal',
        border: const OutlineInputBorder(),

      ),
      onSubmitted: (value) async {
        final calories = int.tryParse(value) ?? 0;
        await updateCaloriesIngerees(calories);
           setState(() {
        _caloriesController.clear();
      });
      },
    ),
  ),
  const SizedBox(width: 12),
  ElevatedButton(
    onPressed: () async {
      final calories = int.tryParse(_caloriesController.text) ?? 0;
      await updateCaloriesIngerees(calories);
    },
    child: Text(tr('save')),
  ),
],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Graphique de déficit calorique
                      if (programData != null) ...[
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('calorie_balance'),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                
                                // Graphique en barres simple
                                SizedBox(
                                  width: double.infinity,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // Barre calories brûlées
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${(programData?['calories'] ?? 0)} kcal',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            width: 60,
                                            height: ((programData?['calories'] ?? 0) / 10).clamp(10.0, 150.0),
                                            decoration: BoxDecoration(
                                              color: Colors.red[400],
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            tr('burned'),
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      // Barre calories consommées
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${(programData?['calories_ingerees'] ?? 0)} kcal',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            width: 60,
                                            height: ((programData?['calories_ingerees'] ?? 0) / 10).clamp(10.0, 150.0),
                                            decoration: BoxDecoration(
                                              color: Colors.green[400],
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            tr('consumed'),
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Résumé du déficit/surplus
                                Builder(
                                  builder: (context) {
                                    final caloriesDepensees = (programData?['calories'] ?? 0).toDouble();
                                    final caloriesIngerees = (programData?['calories_ingerees'] ?? 0).toDouble();
                                    final deficit = caloriesDepensees - caloriesIngerees;
                                    
                                    return Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: deficit > 0 ? Colors.green[50] : Colors.orange[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: deficit > 0 ? Colors.green[300]! : Colors.orange[300]!,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                deficit > 0 ? tr('calorie_deficit') : tr('calorie_surplus'),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: deficit > 0 ? const Color.fromARGB(255, 31, 142, 36) : Colors.orange[700],
                                                ),
                                              ),
                                              Text(
                                                '${deficit.abs().toInt()} kcal',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: deficit > 0 ? Colors.green[700] : Colors.orange[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            deficit > 0 
                                              ? 'Vous êtes en déficit de ${deficit.toInt()} kcal, favorable à la perte de poids'
                                              : 'Vous avez un surplus de ${deficit.abs().toInt()} kcal, attention à la prise de poids',
                                            style: const TextStyle(fontSize: 12,color: Colors.black54),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Zone infos programme
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    programData?['nom'] ?? 'Nom inconnu',
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(tr('comments', args: [programData?['commentaire'] ?? '—'])),
                                  const SizedBox(height: 4),
                                  Text(tr('day', args: [programData?['jour']?.substring(0, 10) ?? ''])),
                                  if (programData?['autoGenerated'] == true)
                                    Text(
                                      tr('auto_generated'),
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Center(
                        child: ElevatedButton.icon(
                          onPressed: fetchTodayProgram,
                          icon: const Icon(Icons.refresh),
                          label: Text(tr('refresh_program')),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                        ),
                      ),
                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.local_fire_department),
                          label: Text(tr('recalculate_calories')),
                          onPressed: () async {
                            await updateStepsAndCalories();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(tr('calories_updated'))),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Liste des exercices
                      if (programData?['exercices'] != null &&
                          programData?['exercices'] is List) ...[
                        Text(tr('exercises_list'),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ...List<Widget>.from(
                          (programData!['exercices'] as List).map((ex) {
                            final Map<String, dynamic> exercice =
                                Map<String, dynamic>.from(ex);
                            return Card(
                              margin:
                                  const EdgeInsets.symmetric(vertical: 8),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exercice['type'] ?? 'Type inconnu',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    if ((exercice['subType'] ?? '')
                                        .isNotEmpty)
                                      Text("Sous-type : ${exercice['subType']}"),
                                    if ((exercice['series'] ?? '')
                                        .isNotEmpty)
                                      Text("Séries : ${exercice['series']}"),
                                    if ((exercice['repetitions'] ?? '')
                                        .isNotEmpty)
                                      Text(
                                          "Répétitions : ${exercice['repetitions']}"),
                                    if ((exercice['duration'] ?? '')
                                        .isNotEmpty)
                                      Text("Durée : ${exercice['duration']}"),
                                    if ((exercice['distance'] ?? '')
                                        .isNotEmpty)
                                      Text("Distance : ${exercice['distance']}"),
                                    if ((exercice['intensity'] ?? '')
                                        .isNotEmpty)
                                      Text("Intensité : ${exercice['intensity']}"),
                                    if ((exercice['restTime'] ?? '')
                                        .isNotEmpty)
                                      Text("Repos : ${exercice['restTime']}"),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(tr('status')),
                                        IconButton(
                                          icon: Icon(
                                            exercice['accompli'] == true
                                                ? Icons.check_circle
                                                : Icons.radio_button_unchecked,
                                            color: exercice['accompli'] == true
                                                ? Colors.green
                                                : Colors.grey,
                                          ),
                                          onPressed: () async {
                                            final user = FirebaseAuth
                                                .instance.currentUser;
                                            if (user == null) return;

                                            final snapshot =
                                                await FirebaseFirestore
                                                    .instance
                                                    .collection('users')
                                                    .doc(user.uid)
                                                    .collection('programmes')
                                                    .where('jour',
                                                        isGreaterThanOrEqualTo:
                                                            todaybd)
                                                    .where('jour',
                                                        isLessThan:
                                                            "${todaybd}T23:59:59.999")
                                                    .get();

                                            if (snapshot.docs.isNotEmpty) {
                                              final docRef =
                                                  snapshot.docs.first.reference;
                                              List exercices = List.from(
                                                  programData!['exercices']);
                                              final index =
                                                  exercices.indexOf(ex);
                                              if (index != -1) {
                                                exercices[index]['accompli'] =
                                                    !(exercice['accompli'] ??
                                                        false);
                                                await docRef.update(
                                                    {'exercices': exercices});
                                                setState(() {
                                                  programData!['exercices'] =
                                                      exercices;
                                                });
                                              }
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        )
                      ]
                    ],
                  ),
                ),
              ),
  );
}
int calculerCaloriesExercices(List exercices, {required double poids}) {
  double totalExos = 0;
  for (final ex in exercices) {
  if (ex is Map && (ex['accompli'] == true || ex['accompli'] == 1)) {
    final exercise = ExerciseBlock.fromMap(Map<String, dynamic>.from(ex));
    totalExos += exercise.estimateCalories(poids: poids);
  }
}

  return totalExos.round();
}


}
