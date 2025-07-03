// AddProgramPage.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/add_program_view_model.dart';
import '../models/exercise_block.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../models/exercise_card.dart';          // ← nouveau

import 'package:http/http.dart' as http;

class AddProgramPage extends StatelessWidget {
  final DateTime? initialDate;
  final TextEditingController _promptController = TextEditingController();

  AddProgramPage({super.key, this.initialDate});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = AddProgramViewModel();
        // Si une date initiale est fournie, l'utiliser
        if (initialDate != null) {
          vm.updateSelectedDate(initialDate!);
        }
        // Vérifier les programmes existants après la création
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
                
                // ✅ Modification : passage de l'index et du callback de suppression
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

                          // Démarrer le chargement
                          vm.setGenerating=true;

                          try {
                            // 1) Requête vers ton Worker
                            final uri = Uri.parse(
                              'https://generate-program.sporttracker.workers.dev/generate-program',
                            );
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

                            // 2) Parsing de la réponse
                            final data = jsonDecode(resp.body);
                            
                            // Debug : afficher la réponse complète
                            print('Réponse complète du Worker: $data');
                            
                            // 3) Injection des champs retournés
                            vm.programNameController.text = data['nom']?.toString() ?? '';
                            vm.commentController.text = data['commentaire']?.toString() ?? '';
                            
                            // 4) Traitement des exercices avec vérification
                            if (data['exercices'] != null && data['exercices'] is List) {
                              final exercicesList = data['exercices'] as List;
                              print('Nombre d\'exercices reçus: ${exercicesList.length}');
                              
                              vm.exercises.clear();
                              
                              for (var exerciceData in exercicesList) {
                                try {
                                  // Vérification que exerciceData est bien un Map
                                  if (exerciceData is Map<String, dynamic>) {
                                    print('Traitement exercice: $exerciceData');
                                    
                                    // Ajout dynamique type/sous-type inconnus
                                    final type = exerciceData['type']?.toString() ?? '';
                                    final subType = exerciceData['subType']?.toString() ?? '';
                                    
                                    if (type.isNotEmpty) {
                                      // Supprime les espaces en double, mais conserve l'intitulé exact (ex: "Renfo avec charges")
                                      final cleanType = type.trim();
                                      final cleanSubType = subType.trim();

                                      // Initialise si nécessaire
                                      if (!ExerciseBlock.subTypeOptions.containsKey(cleanType)) {
                                        ExerciseBlock.subTypeOptions[cleanType] = [];
                                      }

                                      // Ajoute le sous-type s'il est défini et pas déjà présent
                                      if (cleanSubType.isNotEmpty &&
                                          !ExerciseBlock.subTypeOptions[cleanType]!.contains(cleanSubType)) {
                                        ExerciseBlock.subTypeOptions[cleanType]!.add(cleanSubType);
                                      }
                                    }
                                    
                                    // Création de l'exercice
                                    final exercice = ExerciseBlock.fromMap(exerciceData);
                                    vm.exercises.add(exercice);
                                    print('Exercice ajouté: ${exercice.type} - ${exercice.subType}');
                                  } else {
                                    print('Exercice invalide (pas un Map): $exerciceData');
                                  }
                                } catch (e) {
                                  print('Erreur lors du traitement d\'un exercice: $e');
                                  print('Données de l\'exercice: $exerciceData');
                                }
                              }
                              
                              print('Nombre total d\'exercices ajoutés: ${vm.exercises.length}');
                              vm.notifyListeners();
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ Programme généré avec ${vm.exercises.length} exercices !'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else {
                              print('Aucun exercice trouvé dans la réponse ou format invalide');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('⚠️ Aucun exercice généré par l\'IA'),
                                  backgroundColor: Colors.orange,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            
                          } catch (e) {
                            print('Erreur générale: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Erreur lors de la génération : $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } finally {
                            // Arrêter le chargement dans tous les cas
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
                  onPressed: () => vm.submit(context),
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