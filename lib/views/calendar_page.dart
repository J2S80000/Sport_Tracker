import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CaalendarPage extends StatefulWidget {
  const CaalendarPage({super.key});

  @override
  State<CaalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CaalendarPage> {
  Map<DateTime, Color> dayColors = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, dynamic>? selectedProgram;

  @override
  void initState() {
    super.initState();
    loadProgramCompletionStatus();
  }

  /// 🔄 Normalise une date en supprimant l'heure
  DateTime normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);

  /// 📥 Charge les couleurs du calendrier selon l'avancement
  Future<void> loadProgramCompletionStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('programmes')
        .get();

    Map<DateTime, Color> colors = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['jour'] != null && data['exercices'] is List) {
        final dateParsed = DateTime.parse(data['jour']).toLocal();
        final date = normalizeDate(dateParsed);
        final List exercices = data['exercices'];

        int total = exercices.length;
        int done = exercices.where((e) => e['accompli'] == true).length;

        if (total == 0 || done == 0) {
          colors[date] = Colors.red;
        } else if (done == total) {
          colors[date] = Colors.green;
        } else {
          colors[date] = Colors.orange;
        }
      }
    }

    setState(() {
      dayColors = colors;
    });
  }

  /// 📤 Quand un jour est sélectionné → charger son programme
  Future<void> loadProgramForDate(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final normalized = normalizeDate(date);

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('programmes')
        .where('jour', isGreaterThanOrEqualTo: normalized.toIso8601String())
        .where('jour', isLessThan: normalized.add(const Duration(days: 1)).toIso8601String())
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        selectedProgram = snapshot.docs.first.data();
        _selectedDay = normalized;
      });
    } else {
      setState(() {
        selectedProgram = null;
        _selectedDay = normalized;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Suivi calendrier")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2025, 1, 1),
              lastDay: DateTime.utc(2026, 1, 1),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                loadProgramForDate(selectedDay);
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, _) {
                  final normalized = normalizeDate(day);
                  final color = dayColors[normalized];
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
            // 🟢 Légende
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _LegendItem(color: Colors.green, label: "Accompli"),
                _LegendItem(color: Colors.orange, label: "Partiel"),
                _LegendItem(color: Colors.red, label: "Non fait"),
              ],
            ),
            const Divider(height: 30),
            // 📋 Affichage du programme sélectionné
            if (_selectedDay != null)
              Text(
                "Programme du ${_selectedDay!.toLocal().toString().split(" ")[0]}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 8),
            if (selectedProgram == null)
              const Text("Aucun programme ce jour-là."),
            if (selectedProgram != null)
              Column(
                children: [
                  Text("Nom : ${selectedProgram!['nom']}"),
                  Text("Commentaire : ${selectedProgram!['commentaire'] ?? '—'}"),
                  const SizedBox(height: 10),
                  ...(selectedProgram!['exercices'] as List).map((e) {
                    final exercice = Map<String, dynamic>.from(e);

                    List<String> specs = [];
                    if ((exercice['subType'] ?? '').isNotEmpty) specs.add("Sous-type: ${exercice['subType']}");
                    if ((exercice['series'] ?? '').isNotEmpty) specs.add("Séries: ${exercice['series']}");
                    if ((exercice['repetitions'] ?? '').isNotEmpty) specs.add("Répétitions: ${exercice['repetitions']}");
                    if ((exercice['duration'] ?? '').isNotEmpty) specs.add("Durée: ${exercice['duration']} min");
                    if ((exercice['distance'] ?? '').isNotEmpty) specs.add("Distance: ${exercice['distance']} km");
                    if ((exercice['intensity'] ?? '').isNotEmpty) specs.add("Intensité: ${exercice['intensity']}");
                    if ((exercice['restTime'] ?? '').isNotEmpty) specs.add("Repos: ${exercice['restTime']} sec");

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      leading: Icon(
                        exercice['accompli'] == true
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: exercice['accompli'] == true ? Colors.green : Colors.grey,
                      ),
                      title: Text(exercice['type'] ?? 'Inconnu',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        specs.join(' • '),
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// 🎨 Légende visuelle
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
