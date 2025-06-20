import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String today = DateTime.now().toIso8601String().substring(0, 10); // "2025-06-21"
  Map<String, dynamic>? programData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTodayProgram();
  }

  Future<void> fetchTodayProgram() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('programmes')
          .where('jour', isGreaterThanOrEqualTo: today)
          .where('jour', isLessThan: "${today}T23:59:59.999")
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
    return Scaffold(
      appBar: AppBar(title: const Text("Programme du jour")),
      body: isLoading
    ? const Center(child: CircularProgressIndicator())
    : programData == null
        ? const Center(child: Text("Aucun programme pour aujourd'hui."))
        : Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView( // <== pour rendre scrollable
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // alignement à gauche
                children: [
                  Text(
                    programData!['nom'] ?? 'Nom inconnu',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text("Commentaire : ${programData!['commentaire'] ?? '—'}"),
                  const SizedBox(height: 10),
                  Text("Jour : ${programData!['jour']?.substring(0, 10) ?? ''}"),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: fetchTodayProgram,
                    child: const Text("Rafraîchir"),
                  ),
                  const SizedBox(height: 20),
                  if (programData!['exercices'] != null && programData!['exercices'] is List)
                    ...List<Widget>.from(
                      (programData!['exercices'] as List).map((ex) {
                        final Map<String, dynamic> exercice = Map<String, dynamic>.from(ex);
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exercice['type'] ?? 'Type inconnu',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
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
                                const SizedBox(height: 8),
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
                                        // Mise à jour de l'état "accompli" dans Firebase
                                        final user = FirebaseAuth.instance.currentUser;
                                        if (user == null) return;

                                        // Trouve l'ID du programme actuel
                                        final snapshot = await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(user.uid)
                                            .collection('programmes')
                                            .where('jour', isGreaterThanOrEqualTo: today)
                                            .where('jour', isLessThan: "${today}T23:59:59.999")
                                            .get();

                                        if (snapshot.docs.isNotEmpty) {
                                          final docId = snapshot.docs.first.id;
                                          final docRef = snapshot.docs.first.reference;

                                          List exercices = List.from(programData!['exercices']);

                                          // On modifie uniquement l'exercice actuel
                                          final index = exercices.indexOf(ex);
                                          if (index != -1) {
                                            exercices[index]['accompli'] = !(exercice['accompli'] ?? false);

                                            // Mise à jour dans Firestore
                                            await docRef.update({'exercices': exercices});

                                            // Mise à jour locale de l'état pour forcer le refresh
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
                ],
              ),
            ),
          ),
    );
  }
}
