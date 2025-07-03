import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../viewmodels/calendar_view_model.dart';

class CaalendarPage extends StatelessWidget {
  const CaalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CalendarViewModel()..loadCalendarColors(),
      child: Consumer<CalendarViewModel>(
        builder: (context, vm, _) => Scaffold(
          appBar: AppBar(title: const Text("Suivi calendrier")),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2025, 1, 1),
                  lastDay: DateTime.utc(2026, 1, 1),
                  focusedDay: vm.focusedDay,
                  selectedDayPredicate: (day) => isSameDay(vm.selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    vm.loadProgramForDate(selectedDay);
                    vm.setFocusedDay(focusedDay);
                  },
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, _) {
                      final color = vm.dayColors[vm.normalizeDate(day)];
                      return Container(
                        decoration: BoxDecoration(
                          color: color ?? Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: color != null ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    _LegendItem(color: Colors.green, label: "Accompli"),
                    _LegendItem(color: Colors.orange, label: "Partiel"),
                    _LegendItem(color: Colors.red, label: "Non fait"),
                  ],
                ),
                const Divider(height: 30),
                if (vm.selectedDay != null)
                  Text(
                    "Programme du ${vm.selectedDay!.day.toString().padLeft(2, '0')}/${vm.selectedDay!.month.toString().padLeft(2, '0')}/${vm.selectedDay!.year}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                const SizedBox(height: 8),
                ElevatedButton.icon(
  icon: const Icon(Icons.copy),
  label: const Text("Copier"),
  onPressed: () async {
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.selectedDay ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2026),
    );

    if (picked != null) {
      await vm.copyProgramToDate(picked, context);
    }
  },
),
                if (vm.selectedDay != null && vm.selectedProgram == null)
                  const Text("Aucun programme ce jour-là."),
                if (vm.selectedProgram != null)
                  Column(
                    children: [
                      Text("Nom : ${vm.selectedProgram!['nom']}"),
                      Text("Commentaire : ${vm.selectedProgram!['commentaire'] ?? '—'}"),
                      const SizedBox(height: 10),
                      ...(vm.selectedProgram!['exercices'] as List).map((e) {
                        final ex = Map<String, dynamic>.from(e);
                        List<String> specs = [];

                        if ((ex['subType'] ?? '').isNotEmpty) specs.add("Sous-type: ${ex['subType']}");
                        if ((ex['series'] ?? '').isNotEmpty) specs.add("Séries: ${ex['series']}");
                        if ((ex['repetitions'] ?? '').isNotEmpty) specs.add("Répétitions: ${ex['repetitions']}");
                        if ((ex['duration'] ?? '').isNotEmpty) specs.add("Durée: ${ex['duration']} min");
                        if ((ex['distance'] ?? '').isNotEmpty) specs.add("Distance: ${ex['distance']} km");
                        if ((ex['intensity'] ?? '').isNotEmpty) specs.add("Intensité: ${ex['intensity']}");
                        if ((ex['restTime'] ?? '').isNotEmpty) specs.add("Repos: ${ex['restTime']} sec");

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          leading: Icon(
                            ex['accompli'] == true ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: ex['accompli'] == true ? Colors.green : Colors.grey,
                          ),
                          title: Text(ex['type'] ?? 'Inconnu', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(specs.join(' • '), style: const TextStyle(fontSize: 12)),
                        );
                      }),
                      Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    ElevatedButton.icon(
      icon: const Icon(Icons.edit),
      label: const Text("Modifier"),
      onPressed: () {
        // Navigue vers AddProgramPage avec la date
        Navigator.pushNamed(
          context,
          '/edit-program',
          arguments: vm.selectedDay, // ou directement le programme si tu préfères
        );
      },
    ),
    ElevatedButton.icon(
      icon: const Icon(Icons.delete),
      label: const Text("Supprimer"),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Confirmer la suppression"),
            content: const Text("Souhaites-tu vraiment supprimer ce programme ?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer")),
            ],
          ),
        );

        if (confirm == true) {
          await vm.deleteCurrentProgram(context);
        }
      },
    ),
  ],
),

                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 12),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
