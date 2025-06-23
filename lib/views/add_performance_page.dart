import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddPerformancePage extends StatefulWidget {
  const AddPerformancePage({super.key});

  @override
  State<AddPerformancePage> createState() => _AddPerformancePageState();
}

class _AddPerformancePageState extends State<AddPerformancePage> {
  final _formKey = GlobalKey<FormState>();

  String _type = 'Shadow Boxing';
  String _duree = '';
  String _series = '';
  String _frequence = '';
  String _commentaire = '';

  double calculateCompletion({
    required int? plannedSeries,
    required int? plannedDuration,
    required int? performedSeries,
    required int? performedDuration,
  }) {
    if (plannedSeries == null || plannedDuration == null || plannedSeries == 0 || plannedDuration == 0) {
      return 0;
    }
    final seriesRatio = (performedSeries ?? 0) / plannedSeries;
    final durationRatio = (performedDuration ?? 0) / plannedDuration;
    return ((seriesRatio + durationRatio) / 2 * 100).clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter une performance")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Type d'exercice"),
              DropdownButton<String>(
                value: _type,
                onChanged: (String? newValue) {
                  setState(() {
                    _type = newValue!;
                  });
                },
                items: <String>['Shadow Boxing', 'Pompes', 'Tractions', 'Course', 'Cardio libre']
                    .map((String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Durée (minutes)'),
                validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
                keyboardType: TextInputType.number,
                onChanged: (value) => _duree = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Séries (si applicable)'),
                keyboardType: TextInputType.number,
                onChanged: (value) => _series = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Fréquence cardiaque (optionnel)'),
                keyboardType: TextInputType.number,
                onChanged: (value) => _frequence = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Commentaire'),
                onChanged: (value) => _commentaire = value,
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;

                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;

                    final now = DateTime.now();
                    final dateKey = DateTime(now.year, now.month, now.day).toIso8601String().substring(0, 10);

                    final programmeSnap = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('programmes')
                        .where('jour', isGreaterThanOrEqualTo: dateKey)
                        .where('jour', isLessThan: dateKey + 'T23:59:59')
                        .limit(1)
                        .get();

                    if (programmeSnap.docs.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Aucun programme aujourd\'hui pour valider cette performance.')),
                      );
                      return;
                    }

                    final doc = programmeSnap.docs.first;
                    final data = doc.data();
                    final exercices = List<Map<String, dynamic>>.from(data['exercices'] ?? []);

                    final matchingIndex = exercices.indexWhere((e) => e['type'] == _type);
                    if (matchingIndex == -1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Aucun exercice correspondant dans le programme du jour.')),
                      );
                      return;
                    }

                    final ex = exercices[matchingIndex];
                    final plannedSeries = int.tryParse(ex['series'] ?? '');
                    final plannedDuration = int.tryParse(ex['duration'] ?? '');
                    final performedSeries = int.tryParse(_series);
                    final performedDuration = int.tryParse(_duree);

                    final percent = calculateCompletion(
                      plannedSeries: plannedSeries,
                      plannedDuration: plannedDuration,
                      performedSeries: performedSeries,
                      performedDuration: performedDuration,
                    ).round();

                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Valider la performance ?"),
                        content: Text("Cette performance correspond à $percent% de l'objectif.\nRemplacer et marquer comme accompli ?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Valider")),
                        ],
                      ),
                    );

                    if (confirmed != true) return;

                    exercices[matchingIndex] = {
                      ...ex,
                      'duration': _duree,
                      'series': _series,
                      'accompli': true,
                      'commentaire': _commentaire,
                    };

                    await doc.reference.update({'exercices': exercices});

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('✅ Performance enregistrée et exercice mis à jour à $percent%.')),
                    );

                    Navigator.pop(context);
                  },
                  child: const Text("Enregistrer"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
