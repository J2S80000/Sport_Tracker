import 'package:flutter/material.dart';
import '../controllers/program_controller.dart';
import '../models/program.dart'; // nécessaire ici
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddProgramPage extends StatefulWidget {
  const AddProgramPage({super.key});

  @override
  State<AddProgramPage> createState() => _AddProgramPageState();
}

class _AddProgramPageState extends State<AddProgramPage> {
  final _formKey = GlobalKey<FormState>();
  final List<ExerciseBlock> _exercises = [];
DateTime _selectedDate = DateTime.now();


  final TextEditingController _programNameController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  
  void _addExercise() {
    setState(() {
      _exercises.add(ExerciseBlock());
    });
  }

void _submitProgram() async {
  final program = Program(
    nom: _programNameController.text,
    date: _selectedDate.toIso8601String(),
    commentaire: _commentController.text,
    exercices: _exercises.map((e) => e.toMap()).toList(),
  );

  final controller = ProgramController();

  try {
    await controller.saveProgram(program);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Programme enregistré !')),
    );

    // Optionnel : revenir à la page d’accueil ou vider le formulaire
    Navigator.pop(context); // ou autre redirection
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Erreur : ${e.toString()}')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter un programme")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            
            children: [
              TextFormField(
                readOnly: true,
                decoration: const InputDecoration(labelText: "Date du programme"),
                controller: TextEditingController(
                  text: "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                ),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
              TextFormField(
                controller: _programNameController,
                decoration: const InputDecoration(labelText: "Nom du programme"),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _commentController,
                decoration:
                    const InputDecoration(labelText: "Commentaire global (optionnel)"),
              ),
              
              const SizedBox(height: 20),
              const Text("Exercices :",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              ..._exercises.map((e) => e.build(context)).toList(),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _addExercise,
                icon: const Icon(Icons.add),
                label: const Text("Ajouter un exercice"),
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _submitProgram,
                  child: const Text("Enregistrer le programme"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// CLASS BLOC D'EXERCICE
// --------------------------------------------------

class ExerciseBlock {
  String type = 'Shadow Boxing';
  String subType = '';
  String duration = '';
  String distance = '';
  String repetitions = '';
  String intensity = 'Modérée';
  String restTime = '';
  String series = '';
  bool accompli = false;
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'subType': subType,
      'duration': duration,
      'distance': distance,
      'repetitions': repetitions,
      'series': series,
      'intensity': intensity,
      'restTime': restTime,
      'accompli': accompli,
    };
  }


  final Map<String, List<String>> subTypeOptions = {
    'Street Workout': ['Pompes', 'Tractions', 'Dips', 'Abdos'],
    'Course': [],
    'Cardio libre': [],
    'Shadow Boxing': [],
    'Repos actif': [],
  };

 
  final List<String> intensityOptions = [
    'Faible',
    'Modérée',
    'Élevée',
  ];

  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              
                // Type d'exercice
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: "Type d'exercice"),
                  items: subTypeOptions.keys
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      type = val!;
                      subType = '';
                      duration = '';
                      distance = '';
                      repetitions = '';
                      restTime = '';
                    });
                  },
                ),

                // Sous-type si applicable
                if (subTypeOptions[type]!.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: subType.isEmpty ? null : subType,
                    decoration: const InputDecoration(labelText: "Sous-type"),
                    items: subTypeOptions[type]!
                        .map<DropdownMenuItem<String>>(
                          (e) => DropdownMenuItem<String>(
                            value: e,
                            child: Text(e),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        subType = val!;
                        repetitions = '';
                      });
                    },
                  ),

                // Répétitions
                if (type == 'Street Workout' && subType.isNotEmpty)
                  TextFormField(
                    decoration: InputDecoration(
                        labelText: "Nombre de répétitions pour $subType"),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => repetitions = val,
                  ),

                // Distance
                if (type == 'Course')
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Distance (en km)"),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => distance = val,
                  ),
                // Affichage du nombre de séries
                if ((type == 'Street Workout' && subType.isNotEmpty) ||
                    type == 'Shadow Boxing' ||
                    type == 'Cardio libre')
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Nombre de séries"),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => series = val,
                  ),
                // Durée
                if (type == 'Course' ||
                    type == 'Shadow Boxing' ||
                    type == 'Cardio libre' ||
                    type == 'Repos actif')
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Durée (en minutes)"),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => duration = val,
                  ),

                // Intensité
                if (type != 'Repos actif')
                  DropdownButtonFormField<String>(
                    value: intensity,
                    decoration: const InputDecoration(labelText: "Intensité"),
                    items: intensityOptions
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        intensity = val!;
                      });
                    },
                  ),

                // Temps de repos
                TextFormField(
                  decoration:
                      const InputDecoration(labelText: "Repos après l'exercice (en sec)"),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => restTime = val,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
