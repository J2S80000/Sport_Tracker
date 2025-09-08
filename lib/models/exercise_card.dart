// File: lib/widgets/exercise_card.dart
import 'package:flutter/material.dart';
import '../models/exercise_block.dart';
import 'package:easy_localization/easy_localization.dart';


class ExerciseCard extends StatefulWidget {
  final ExerciseBlock block;
  final int index;
  final VoidCallback? onDelete;
  
  const ExerciseCard({
    super.key, 
    required this.block,
    required this.index,
    this.onDelete,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  
  ExerciseBlock get b => widget.block;
  

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Header avec numéro et bouton supprimer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Exercice ${widget.index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteDialog(context),
                    tooltip: 'Supprimer cet exercice',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Type d'exercice (clé, affichage traduit)
            DropdownButtonFormField<String>(
              value: ExerciseBlock.subTypeOptions.keys.contains(b.type) ? b.type : null,
              decoration: InputDecoration(labelText: tr('exercise_type')),
              items: ExerciseBlock.subTypeOptions.keys
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(tr(t)),
                      ))
                  .toList(),
              onChanged: (val) => setState(() {
                b.type = val!;
                b
                  ..subType = ''
                  ..duration = ''
                  ..distance = ''
                  ..repetitions = ''
                  ..restTime = '';
              }),
            ),
            
            // Sous-type (clé, affichage traduit)
            if (ExerciseBlock.subTypeOptions[b.type]!.isNotEmpty)
              DropdownButtonFormField<String>(
                value: (ExerciseBlock.subTypeOptions[b.type] ?? []).contains(b.subType) ? b.subType : null,

                decoration: InputDecoration(labelText: tr('sub_type')),
                items: ExerciseBlock.subTypeOptions[b.type]!
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(tr(s)),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => b.subType = val!),
              ),
            
            // Répétitions pour certains types
            if ((b.type == 'street_workout' || b.type == 'plyometrics' || b.type == 'weight_training') && b.subType.isNotEmpty)
              TextFormField(
                initialValue: b.repetitions,
                decoration: InputDecoration(labelText: tr('repetitions_for', args: [tr(b.subType)])),
                keyboardType: TextInputType.number,
                onChanged: (val) => b.repetitions = val,
              ),
            
            // Distance pour running uniquement
            if (b.type == 'running')
              TextFormField(
                initialValue: b.distance,
                decoration: InputDecoration(labelText: tr('distance_km')),
                keyboardType: TextInputType.number,
                onChanged: (val) => b.distance = val,
              ),
            
            // Séries pour certains types
            if ((b.type == 'street_workout' && b.subType.isNotEmpty) ||
                (b.type == 'plyometrics' && b.subType.isNotEmpty) ||
                (b.type == 'weight_training' && b.subType.isNotEmpty) ||
                b.type == 'shadow_boxing' ||
                b.type == 'free_cardio')
              TextFormField(
                initialValue: b.series,
                decoration: InputDecoration(labelText: tr('series_count')),
                keyboardType: TextInputType.number,
                onChanged: (val) => b.series = val,
              ),
            
            // Durée pour certains types
            if (b.type == 'running' ||
                b.type == 'shadow_boxing' ||
                b.type == 'free_cardio' ||
                b.type == 'active_rest' ||
                (b.type == 'street_workout' && b.subType == 'plank'))
              TextFormField(
                initialValue: b.duration,
                decoration: InputDecoration(labelText: tr('duration_min')),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  final n = int.tryParse(val) ?? 0;
                  const _SEC_THRESHOLD = 600;
                  final minutes = n > _SEC_THRESHOLD ? (n / 60).round() : n;
                  setState(() => b.duration = minutes.toString());
                },
              ),
            
            // Poids/Charge pour weight_training uniquement
            if (b.type == 'weight_training' && b.subType.isNotEmpty)
              TextFormField(
                initialValue: b.weight ?? '',
                decoration: InputDecoration(labelText: tr('weight_kg')),
                keyboardType: TextInputType.number,
                onChanged: (val) => b.weight = val,
              ),
            
            // Intensité pour tous sauf active_rest
            if (b.type != 'active_rest')
              DropdownButtonFormField<String>(
                value: b.intensity,
                decoration: InputDecoration(labelText: tr('intensity')),
                items: ExerciseBlock.intensityOptions
                    .map((i) => DropdownMenuItem(
                          value: i,
                          child: Text(tr(i)),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => b.intensity = val!),
              ),
            
            // Temps de repos pour tous les exercices
            TextFormField(
              initialValue: b.restTime,
              decoration: InputDecoration(labelText: tr('rest_after_exercise')),
              keyboardType: TextInputType.number,
              onChanged: (val) => b.restTime = val,
            ),
          ],
        ),
      ),
    );
  }

  // Dialog de confirmation pour la suppression
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('delete_exercise')),
        content: Text(tr('confirm_delete_exercise', args: [(widget.index + 1).toString()])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              widget.onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(tr('delete')),
          ),
        ],
      ),
    );
  }
}