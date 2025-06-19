import 'package:flutter/material.dart';

class AddPerformancePage extends StatefulWidget {
  const AddPerformancePage({super.key});

  @override
  State<AddPerformancePage> createState() => _AddPerformancePageState();
}

class _AddPerformancePageState extends State<AddPerformancePage> {
  final _formKey = GlobalKey<FormState>();

  String _type = 'Course';
  String _duree = '';
  String _frequence = '';
  String _commentaire = '';

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
                items: <String>['Course', 'Musculation', 'Yoga', 'Natation']
                    .map((String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Durée / répétitions'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Champ requis' : null,
                onChanged: (value) => _duree = value,
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
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Performance enregistrée !')),
                      );
                    }
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
