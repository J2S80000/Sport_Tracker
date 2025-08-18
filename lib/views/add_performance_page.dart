import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:SportTracker/models/performanceview.dart';

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
            appBar: AppBar(title: Text(tr('add_performance'))),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: vm.formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: type,
                        decoration: InputDecoration(labelText: tr('exercise_type')),
                        items: vm.subTypeOptions.keys
                            .map((e) => DropdownMenuItem(value: e, child: Text(tr(e))))
                            .toList(),
                        onChanged: (val) => vm.updateField(type: val),
                      ),

                      if (vm.subTypeOptions[type]!.isNotEmpty)
                        DropdownButtonFormField<String>(
                          value: subType.isEmpty ? null : subType,
                          decoration: InputDecoration(labelText: tr('sub_type')),
                          items: vm.subTypeOptions[type]!
                              .map((e) => DropdownMenuItem(value: e, child: Text(tr(e))))
                              .toList(),
                          onChanged: (val) => vm.updateField(subType: val),
                        ),

                      // Répétitions : Street Workout, Plyométrie, Renfo avec charges
                      if ((type == 'Street Workout' || type == 'Plyometrie' || type == 'Renfo avec charges') && subType.isNotEmpty)
                        TextFormField(
                          decoration: InputDecoration(labelText: tr('repetitions_for', args: [subType])),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => vm.updateField(repetitions: val),
                        ),

                      // Distance : Course
                      if (type == 'Course')
                        TextFormField(
                          decoration: InputDecoration(labelText: tr('distance_km')),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => vm.updateField(distance: val),
                        ),

                      // Séries : Street Workout, Plyométrie, Renfo avec charges, Shadow Boxing, Cardio libre
                      if ((type == 'Street Workout' && subType.isNotEmpty) ||
                          (type == 'Plyometrie' && subType.isNotEmpty) ||
                          (type == 'Renfo avec charges' && subType.isNotEmpty) ||
                          type == 'Shadow Boxing' ||
                          type == 'Cardio libre')
                        TextFormField(
                          decoration: InputDecoration(labelText: tr('series_count')),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => vm.updateField(series: val),
                        ),

                      // Durée : Course, Shadow Boxing, Cardio libre, Repos actif
                      if (type == 'Course' ||
                          type == 'Shadow Boxing' ||
                          type == 'Cardio libre' ||
                          type == 'Repos actif')
                        TextFormField(
                          decoration: InputDecoration(labelText: tr('duration_min')),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => vm.updateField(duration: val),
                        ),

                      // Poids : Renfo avec charges
                      if (type == 'Renfo avec charges' && subType.isNotEmpty)
                        TextFormField(
                          decoration: InputDecoration(labelText: tr('weight_kg')),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => vm.updateField(weight: val),
                        ),

                      // Intensité : tous sauf Repos actif
                      if (type != 'Repos actif')
                        DropdownButtonFormField<String>(
                          value: vm.model.intensity.isEmpty ? null : vm.model.intensity,
                          decoration: InputDecoration(labelText: tr('intensity')),
                          items: vm.intensityOptions
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) => vm.updateField(intensity: val),
                        ),

                      // Repos : tous
                      TextFormField(
                        decoration: InputDecoration(labelText: tr('rest_after_exercise')),
                        keyboardType: TextInputType.number,
                        onChanged: (val) => vm.updateField(restTime: val),
                      ),

                      // Commentaire
                      TextFormField(
                        decoration: InputDecoration(labelText: tr('comment')),
                        onChanged: (val) => vm.updateField(commentaire: val),
                      ),

                      const SizedBox(height: 20),

                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            final result = await vm.submitPerformance(context);
                            if (result != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('performance_saved'))));
                              if (result.startsWith('✅')) Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('performance_error'))));
                            }
                          },
                          child: Text(tr('save_performance')),
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
