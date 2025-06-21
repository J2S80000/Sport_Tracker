import 'package:flutter/material.dart';
import '../controllers/program_controller.dart';
import '../models/program.dart';
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

  @override
  void initState() {
    super.initState();
    _checkExistingProgram();
  }

  Future<void> _checkExistingProgram() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('programmes')
        .where('jour', isEqualTo: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day).toIso8601String())
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final existing = snapshot.docs.first.data();
      final nom = existing['nom'] ?? '(sans nom)';
      final commentaire = existing['commentaire'] ?? '';
      final exercices = List<Map<String, dynamic>>.from(existing['exercices'] ?? []);

      _programNameController.text = nom;
      _commentController.text = commentaire;
      _exercises.clear();
      _exercises.addAll(exercices.map((e) => ExerciseBlock.fromMap(e)));

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Programme existant'),
          content: const Text('Un programme existe déjà pour ce jour. Voulez-vous le remplacer ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remplacer'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
    DateTime newDate = _selectedDate;
    QuerySnapshot testSnapshot;
    // Trouver la prochaine date libre

    do {
      newDate = newDate.add(const Duration(days: 1));
      testSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('programmes')
          .where('jour', isEqualTo: DateTime(newDate.year, newDate.month, newDate.day).toIso8601String())
          .get();
    } while (testSnapshot.docs.isNotEmpty);

    setState(() {
      _selectedDate = newDate;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Date automatiquement mise à jour au ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}"),
      ),
    );
    return; // Ne pas enregistrer, attendre nouvelle validation utilisateur
      }
    }
  }

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
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur : \${e.toString()}')),
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
                    _checkExistingProgram();
                  }
                },
              ),
              TextFormField(
                controller: _programNameController,
                decoration: const InputDecoration(labelText: "Nom du programme"),
                validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(labelText: "Commentaire global (optionnel)"),
              ),
              const SizedBox(height: 20),
              const Text("Exercices :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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

  ExerciseBlock();

  factory ExerciseBlock.fromMap(Map<String, dynamic> map) {
    final block = ExerciseBlock();
    block.type = map['type'] ?? block.type;
    block.subType = map['subType'] ?? '';
    block.duration = map['duration'] ?? '';
    block.distance = map['distance'] ?? '';
    block.repetitions = map['repetitions'] ?? '';
    block.intensity = map['intensity'] ?? 'Modérée';
    block.restTime = map['restTime'] ?? '';
    block.series = map['series'] ?? '';
    block.accompli = map['accompli'] ?? false;
    return block;
  }

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
                if (subTypeOptions[type]!.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: subType.isEmpty ? null : subType,
                    decoration: const InputDecoration(labelText: "Sous-type"),
                    items: subTypeOptions[type]!
                        .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      setState(() => subType = val!);
                    },
                  ),
                if (type == 'Street Workout' && subType.isNotEmpty)
                  TextFormField(
                    decoration: InputDecoration(labelText: "Nombre de répétitions pour \$subType"),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => repetitions = val,
                  ),
                if (type == 'Course')
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Distance (en km)"),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => distance = val,
                  ),
                if ((type == 'Street Workout' && subType.isNotEmpty) || type == 'Shadow Boxing' || type == 'Cardio libre')
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Nombre de séries"),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => series = val,
                  ),
                if (type == 'Course' || type == 'Shadow Boxing' || type == 'Cardio libre' || type == 'Repos actif')
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Durée (en minutes)"),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => duration = val,
                  ),
                if (type != 'Repos actif')
                  DropdownButtonFormField<String>(
                    value: intensity,
                    decoration: const InputDecoration(labelText: "Intensité"),
                    items: intensityOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setState(() => intensity = val!),
                  ),
                TextFormField(
                  decoration: const InputDecoration(labelText: "Repos après l'exercice (en sec)"),
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
