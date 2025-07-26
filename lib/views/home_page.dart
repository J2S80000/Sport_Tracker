import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sport_tracker/views/layout_page.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';


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

class _HomePageState extends State<HomePage> {
  String todaybd = DateTime.now().toIso8601String().substring(0, 10); // "2025-06-21"
  Map<String, dynamic>? programData;
  bool isLoading = true;

@override
void initState() {
  super.initState();

  final now = DateTime.now();
  todaybd = now.toIso8601String().substring(0, 10);
  currentDayDate = DateTime(now.year, now.month, now.day);

  fetchTodayProgram();
  initStepCounter();
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
  setState(() {}); // Mettre à jour l’UI
  await updateStepsAndCalories(); // ✅ Calculer immédiatement si on a des pas
}

  _stepCountStream = Pedometer.stepCountStream;
  _stepCountStream!.listen(onStepCount).onError(onStepCountError);
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

  // ⚠️ Ne calcule pas tout de suite à la première réception
  if (!hasFirstEventProcessed) {
    hasFirstEventProcessed = true;
    return;
  }

  setState(() {
    totalStepsToday = event.steps - (stepsAtStartOfDay ?? event.steps);

    
  });
await prefs.setInt('lastKnownSteps', event.steps);

  print('Pas aujourd\'hui : $totalStepsToday');

  await updateStepsAndCalories();

}

Future<void> updateStepsAndCalories() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || totalStepsToday == null || programData == null) return;

  // Charger poids et taille
  final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  final poids = userDoc.data()?['poids'] ?? 60;
  final taille = userDoc.data()?['taille'] ?? 170;

  final caloriesPas = calculateCalories(totalStepsToday!, poids, taille);

  // Charger le programme du jour
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('programmes')
      .where('jour', isGreaterThanOrEqualTo: todaybd)
      .where('jour', isLessThan: "${todaybd}T23:59:59.999")
      .get();

  if (snapshot.docs.isNotEmpty) {
    final docRef = snapshot.docs.first.reference;
    final data = snapshot.docs.first.data();

    final previousSteps = data['pas'] ?? 0;

    final prevCaloriesPas = data['calories_pas'] ?? 0;
    final caloriesExos = data['calories_exercices'] ?? 0;

    final newCaloriesPas = caloriesPas;
    final totalCalories = newCaloriesPas + caloriesExos;

    await docRef.update({
      'pas': totalStepsToday!,
      'calories_pas': newCaloriesPas,
      'calories_exercices': caloriesExos,
      'calories': totalCalories, // Total toujours dispo
    });
    await fetchTodayProgram();

    print('🔥 Mise à jour : $totalStepsToday pas, $newCaloriesPas kcal (exos: $caloriesExos) => total: $totalCalories');
  }
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
        setState(() {
          programData = snapshot.docs.first.data();
          isLoading = false;
        });
      } else {
        setState(() {
          programData = null;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur de chargement : $e');
      setState(() => isLoading = false);
    }
  }

@override
Widget build(BuildContext context) {
  return LayoutPage(
    title: "Programme du jour",
    child: isLoading
        ? const Center(child: CircularProgressIndicator())
        : programData == null
            ? const Center(child: Text("Aucun programme pour aujourd'hui."))
            : Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Zone podomètre
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text("Pas enregistrés aujourd'hui", style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text('${totalStepsToday ?? 0}', style: const TextStyle(fontSize: 20)),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text("Calories brûlées", style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text('${(programData!['calories_pas'] ?? 0) + (programData!['calories_exercices'] ?? 0)} kcal', style: const TextStyle(fontSize: 20)),
                                  Text("Pas : ${programData!['calories_pas'] ?? 0} kcal"),
Text("Exos : ${programData!['calories_exercices'] ?? 0} kcal"),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Zone infos programme
                      Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 500),
    child: Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              programData!['nom'] ?? 'Nom inconnu',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("📝 Commentaire : ${programData!['commentaire'] ?? '—'}"),
            const SizedBox(height: 4),
            Text("📅 Jour : ${programData!['jour']?.substring(0, 10) ?? ''}"),
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
                          label: const Text("Rafraîchir le programme"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ),Center(
  child: ElevatedButton.icon(
    icon: const Icon(Icons.local_fire_department),
    label: const Text("Recalculer calories (pas + exos)"),
    onPressed: () async {
      await updateStepsAndCalories();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Calories mises à jour")),
      );
    },
  ),
),


                      const SizedBox(height: 30),

                      // Exercices
                      if (programData!['exercices'] != null && programData!['exercices'] is List) ...[
                        const Text("📋 Liste des exercices", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ...List<Widget>.from(
                          (programData!['exercices'] as List).map((ex) {
                            final Map<String, dynamic> exercice = Map<String, dynamic>.from(ex);
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exercice['type'] ?? 'Type inconnu',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    if ((exercice['subType'] ?? '').isNotEmpty)
                                      Text("Sous-type : ${exercice['subType']}"),
                                    if ((exercice['series'] ?? '').isNotEmpty)
                                      Text("Séries : ${exercice['series']}"),
                                    if ((exercice['repetitions'] ?? '').isNotEmpty)
                                      Text("Répétitions : ${exercice['repetitions']}"),
                                    if ((exercice['duration'] ?? '').isNotEmpty)
                                      Text("Durée : ${exercice['duration']} min"),
                                    if ((exercice['distance'] ?? '').isNotEmpty)
                                      Text("Distance : ${exercice['distance']} km"),
                                    if ((exercice['intensity'] ?? '').isNotEmpty)
                                      Text("Intensité : ${exercice['intensity']}"),
                                    if ((exercice['restTime'] ?? '').isNotEmpty)
                                      Text("Repos : ${exercice['restTime']} sec"),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text("Statut :"),
                                        IconButton(
                                          icon: Icon(
                                            exercice['accompli'] == true
                                                ? Icons.check_circle
                                                : Icons.radio_button_unchecked,
                                            color: exercice['accompli'] == true ? Colors.green : Colors.grey,
                                          ),
                                          onPressed: () async {
                                            final user = FirebaseAuth.instance.currentUser;
                                            if (user == null) return;

                                            final snapshot = await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(user.uid)
                                                .collection('programmes')
                                                .where('jour', isGreaterThanOrEqualTo: todaybd)
                                                .where('jour', isLessThan: "${todaybd}T23:59:59.999")
                                                .get();

                                            if (snapshot.docs.isNotEmpty) {
                                              final docRef = snapshot.docs.first.reference;
                                              List exercices = List.from(programData!['exercices']);
                                              final index = exercices.indexOf(ex);
                                              if (index != -1) {
                                                exercices[index]['accompli'] =
                                                    !(exercice['accompli'] ?? false);
                                                await docRef.update({'exercices': exercices});
                                                setState(() {
                                                  programData!['exercices'] = exercices;
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
}
