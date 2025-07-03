import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sport_tracker/models/performanceview.dart';

class AddPerformancePage extends StatelessWidget {
  const AddPerformancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddPerformanceViewModel(),
      child: Builder(
        builder: (context) {
          final vm = context.watch<AddPerformanceViewModel>();
          final type = vm.model.type;
          final subType = vm.model.subType;

          return Scaffold(
            appBar: AppBar(title: const Text("Ajouter une performance")),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: vm.formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: type,
                        decoration: const InputDecoration(labelText: "Type d'exercice"),
                        items: vm.subTypeOptions.keys
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) => vm.updateField(type: val),
                      ),
                      if (vm.subTypeOptions[type]!.isNotEmpty)
                        DropdownButtonFormField<String>(
                          value: subType.isEmpty ? null : subType,
                          decoration: const InputDecoration(labelText: "Sous-type"),
                          items: vm.subTypeOptions[type]!
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) => vm.updateField(subType: val),
                        ),
                      if (type == 'Street Workout' && subType.isNotEmpty)
                        TextFormField(
                          decoration: InputDecoration(labelText: "Nombre de répétitions pour $subType"),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => vm.updateField(repetitions: val),
                        ),
                      if (type == 'Course')
                        TextFormField(
                          decoration: const InputDecoration(labelText: "Distance (en km)"),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => vm.updateField(distance: val),
                        ),
                      if ((type == 'Street Workout' && subType.isNotEmpty) || type == 'Shadow Boxing' || type == 'Cardio libre')
                        TextFormField(
                          decoration: const InputDecoration(labelText: "Nombre de séries"),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => vm.updateField(series: val),
                        ),
                      if (type == 'Course' || type == 'Shadow Boxing' || type == 'Cardio libre' || type == 'Repos actif')
                        TextFormField(
                          decoration: const InputDecoration(labelText: "Durée (en minutes)"),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => vm.updateField(duration: val),
                        ),
                      if (type != 'Repos actif')
                        DropdownButtonFormField<String>(
                          value: vm.model.intensity.isEmpty ? null : vm.model.intensity,
                          decoration: const InputDecoration(labelText: "Intensité"),
                          items: vm.intensityOptions
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) => vm.updateField(intensity: val),
                        ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: "Repos après l'exercice (en sec)"),
                        keyboardType: TextInputType.number,
                        onChanged: (val) => vm.updateField(restTime: val),
                      ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: "Commentaire"),
                        onChanged: (val) => vm.updateField(commentaire: val),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            final result = await vm.submitPerformance(context);
                            if (result != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
                              if (result.startsWith('✅')) Navigator.pop(context);
                            }
                          },
                          child: const Text("Enregistrer"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
