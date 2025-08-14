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
            // ✅ Header avec numéro et bouton supprimer
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
            
            DropdownButtonFormField<String>(
              value: b.type, // Doit être une clé, ex: "squat_barre"
              decoration: const InputDecoration(labelText: "Type d'exercice"),
              items: ExerciseBlock.subTypeOptions.keys
                  .map((t) => DropdownMenuItem(
                    value: t, // La clé !
                    child: Text(tr(t)), // Affichage traduit
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
            
            // Sous-type pour Street Workout, Plyométrie et Renfo avec charges
            if (ExerciseBlock.subTypeOptions[b.type]!.isNotEmpty)
              DropdownButtonFormField<String>(
                value: b.subType.isEmpty ? null : b.subType,
                decoration: const InputDecoration(labelText: "Sous-type"),
                items: ExerciseBlock.subTypeOptions[b.type]!
                    .map((s) => DropdownMenuItem(
                      value: s, // La clé !
                      child: Text(tr(s)), // Affichage traduit
                    ))
                    .toList(),
                onChanged: (val) => setState(() => b.subType = val!),
              ),
            
            // Répétitions pour Street Workout, Plyométrie et Renfo avec charges
            if ((b.type == 'Street Workout' || b.type == 'Plyometrie' || b.type == 'Renfo avec charges') && b.subType.isNotEmpty)
              TextFormField(
                initialValue: b.repetitions,
                decoration: InputDecoration(labelText: "Nombre de répétitions pour ${b.subType}"),
                keyboardType: TextInputType.number,
                onChanged: (val) => b.repetitions = val,
              ),
            
            // Distance pour Course uniquement
            if (b.type == 'Course')
              TextFormField(
                initialValue: b.distance,
                decoration: const InputDecoration(labelText: "Distance (km)"),
                keyboardType: TextInputType.number,
                onChanged: (val) => b.distance = val,
              ),
            
            // Séries pour Street Workout, Plyométrie, Renfo avec charges, Shadow Boxing et Cardio libre
            if ((b.type == 'Street Workout' && b.subType.isNotEmpty) ||
                (b.type == 'Plyometrie' && b.subType.isNotEmpty) ||
                (b.type == 'Renfo avec charges' && b.subType.isNotEmpty) ||
                b.type == 'Shadow Boxing' ||
                b.type == 'Cardio libre')
              TextFormField(
                initialValue: b.series,
                decoration: const InputDecoration(labelText: "Nombre de séries"),
                keyboardType: TextInputType.number,
                onChanged: (val) => b.series = val,
              ),
            
            // Durée pour Course, Shadow Boxing, Cardio libre et Repos actif
            if (b.type == 'Course' ||
                b.type == 'Shadow Boxing' ||
                b.type == 'Cardio libre' ||
                b.type == 'Repos actif' ||
    (b.type == 'Street Workout' && b.subType == 'Gainage'))
              TextFormField(
                initialValue: b.duration,
                decoration: const InputDecoration(labelText: "Durée (minutes)"),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  // ➜ si l'user tape « 900 » on l'interprète comme 15 min
                  final n = int.tryParse(val) ?? 0;
                  const _SEC_THRESHOLD = 600;
                  final minutes = n > _SEC_THRESHOLD ? (n / 60).round() : n;
                  setState(() => b.duration = minutes.toString());
                },
              ),
            
            // Poids/Charge pour Renfo avec charges uniquement
            if (b.type == 'Renfo avec charges' && b.subType.isNotEmpty)
              TextFormField(
                initialValue: b.weight ?? '',
                decoration: const InputDecoration(labelText: "Poids/Charge (kg)"),
                keyboardType: TextInputType.number,
                onChanged: (val) => b.weight = val,
              ),
            
            // Intensité pour tous sauf Repos actif
            if (b.type != 'Repos actif')
              DropdownButtonFormField<String>(
                value: b.intensity,
                decoration: const InputDecoration(labelText: "Intensité"),
                items: ExerciseBlock.intensityOptions
                    .map((i) => DropdownMenuItem(
                      value: i, // La clé !
                      child: Text(tr(i)), // Affichage traduit
                    ))
                    .toList(),
                onChanged: (val) => setState(() => b.intensity = val!),
              ),
            
            // Temps de repos pour tous les exercices
            TextFormField(
              initialValue: b.restTime,
              decoration: const InputDecoration(labelText: "Repos après (en sec)"),
              keyboardType: TextInputType.number,
              onChanged: (val) => b.restTime = val,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Dialog de confirmation pour la suppression
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer l\'exercice'),
        content: Text('Voulez-vous vraiment supprimer l\'exercice ${widget.index + 1} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              widget.onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}