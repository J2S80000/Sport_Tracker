// AddProgramPage.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/add_program_view_model.dart';
import '../models/exercise_block.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../models/exercise_card.dart';
import 'package:http/http.dart' as http;

class AddProgramPage extends StatelessWidget {
  final DateTime? initialDate;
  final TextEditingController _promptController = TextEditingController();

  AddProgramPage({super.key, this.initialDate});

  Future<double> _calculateTotalCalories(List<ExerciseBlock> exercises, double poids) async {
    double total = 0;
    for (final ex in exercises) {
      total += ex.estimateCalories(poids: poids);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = AddProgramViewModel();
        if (initialDate != null) {
          vm.updateSelectedDate(initialDate!);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          vm.checkExistingProgram(context);
        });
        return vm;
      },
      child: Consumer<AddProgramViewModel>(
        builder: (context, vm, _) => Scaffold(
          appBar: AppBar(title: const Text("Ajouter un programme")),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                TextFormField(
                  readOnly: true,
                  decoration: const InputDecoration(labelText: "Date du programme"),
                  controller: TextEditingController(
                    text: "${vm.selectedDate.day}/${vm.selectedDate.month}/${vm.selectedDate.year}",
                  )..selection = TextSelection.fromPosition(
                    TextPosition(offset: "${vm.selectedDate.day}/${vm.selectedDate.month}/${vm.selectedDate.year}".length),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: vm.selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      vm.updateSelectedDate(picked);
                      await vm.checkExistingProgram(context);
                    }
                  },
                ),
                TextFormField(
                  controller: vm.programNameController,
                  decoration: const InputDecoration(labelText: "Nom du programme"),
                ),
                TextFormField(
                  controller: vm.commentController,
                  decoration: const InputDecoration(labelText: "Commentaire global (optionnel)"),
                ),
                TextFormField(
                  controller: _promptController,
                  decoration: const InputDecoration(
                    labelText: "Demande personnalisée à l'IA",
                    hintText: "Ex : crée un programme de remise en forme pour débutant",
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                const Text("Exercices :", style: TextStyle(fontWeight: FontWeight.bold)),
                ...vm.exercises.asMap().entries.map((entry) {
                  final index = entry.key;
                  final exercise = entry.value;
                  return ExerciseCard(
                    block: exercise,
                    index: index,
                    onDelete: () => vm.removeExercise(index),
                  );
                }).toList(),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: vm.isGenerating 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.flash_on),
                        label: Text(vm.isGenerating ? "Génération en cours..." : "Générer avec l'IA"),
                        onPressed: vm.isGenerating ? null : () async {
                          final objectif = _promptController.text.trim();
                          if (objectif.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Veuillez saisir un objectif.')),
                            );
                            return;
                          }
                          vm.setGenerating = true;
                          try {
                            final uri = Uri.parse('https://generate-program.sporttracker.workers.dev/generate-program');
                            final resp = await http.post(
                              uri,
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode({
                                'uid': FirebaseAuth.instance.currentUser?.uid ?? 'ANON',
                                'objectif': objectif,
                                'date': vm.selectedDate.toIso8601String().substring(0, 10),
                              }),
                            );
                            if (resp.statusCode != 200) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur réseau : ${resp.statusCode}')),
                              );
                              return;
                            }
                            final data = jsonDecode(resp.body);
                            vm.programNameController.text = data['nom']?.toString() ?? '';
                            vm.commentController.text = data['commentaire']?.toString() ?? '';
                            if (data['exercices'] != null && data['exercices'] is List) {
                              final exercicesList = data['exercices'] as List;
                              vm.exercises.clear();
                              for (var exerciceData in exercicesList) {
                                if (exerciceData is Map<String, dynamic>) {
                                  final exercice = ExerciseBlock.fromMap(exerciceData);
                                  vm.exercises.add(exercice);
                                }
                              }
                              vm.notifyListeners();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ Programme généré avec ${vm.exercises.length} exercices !'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('⚠️ Aucun exercice généré par l\'IA'),
                                  backgroundColor: Colors.orange,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Erreur lors de la génération : $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } finally {
                            vm.setGenerating = false;
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text("Ajouter un exercice"),
                        onPressed: vm.addExercise,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // Récupération du poids
  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();
  final poids = (userDoc.data()?['poids'] ?? 70).toDouble();

  // Calcul des calories
  final totalCalories = await _calculateTotalCalories(vm.exercises, poids);

  // Format de la date : "2025-07-21"
  final jourFormatted = "${vm.selectedDate.year.toString().padLeft(4, '0')}-"
                        "${vm.selectedDate.month.toString().padLeft(2, '0')}-"
                        "${vm.selectedDate.day.toString().padLeft(2, '0')}";

  // Enregistrement dans Firestore
await FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid)
    .collection('programmes')
    .doc(jourFormatted) // ← ID personnalisé : "2025-07-26"
    .set({
      'uid': user.uid,
      'nom': vm.programNameController.text,
      'commentaire': vm.commentController.text,
      'date': vm.selectedDate,
      'jour': jourFormatted,
      'calories': totalCalories.round(),
      'exercices': vm.exercises.map((e) => e.toFirestore()).toList(),
    });

  Navigator.pop(context);
},

                  child: const Text("✅ Enregistrer le programme"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
