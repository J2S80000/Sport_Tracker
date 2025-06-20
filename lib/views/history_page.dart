// Copie ce code dans history_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final List<String> exerciseOptions = [
    'Shadow Boxing', 'Pompes', 'Tractions', 'Dips', 'Abdos', 'Course', 'Cardio libre',
  ];

  final List<String> periodOptions = ['Semaine', 'Mois', 'Année', 'Jour'];
  String selectedExercise = 'Shadow Boxing';
  String selectedPeriod = 'Semaine';
  bool onlyCompleted = false;

  List<AggregatedDataPoint> dataPoints = [];

  @override
  void initState() {
    super.initState();
    loadExerciseData();
  }

  Future<void> loadExerciseData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('programmes')
        .get();

    if (selectedPeriod == 'Jour') {
      List<AggregatedDataPoint> singlePoints = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final dateStr = data['jour']?.substring(0, 10);
        if (dateStr == null) continue;
        final date = DateTime.parse(dateStr);

        final List exercices = data['exercices'] ?? [];
        for (var e in exercices) {
          if (e['type'] == selectedExercise && (!onlyCompleted || e['accompli'] == true)) {
            final intensity = computeIntensity(
              int.tryParse(e['series'] ?? '1') ?? 1,
              int.tryParse(e['duration'] ?? '1') ?? 1,
              int.tryParse(e['restTime'] ?? '0') ?? 0,
            );
            singlePoints.add(AggregatedDataPoint(
              label: DateFormat('dd/MM').format(date),
              avgIntensity: intensity,
              count: 1,
              nom: data['nom'] ?? '',
              commentaire: data['commentaire'] ?? '',
              rawDate: date, // 👈 Ajout ici
              series: int.tryParse(e['series'] ?? '1'),
              duration: int.tryParse(e['duration'] ?? '1'),
              rest: int.tryParse(e['restTime'] ?? '0'),
            ));
          }
        }
      }
      singlePoints.sort((a, b) => a.rawDate.compareTo(b.rawDate));
      setState(() => dataPoints = singlePoints);
      return;
    }

    Map<String, List<double>> grouped = {};
    Map<String, int> counts = {};
    Map<String, String> noms = {};
    Map<String, String> commentaires = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final dateStr = data['jour']?.substring(0, 10);
      if (dateStr == null) continue;
      final date = DateTime.parse(dateStr);
      final key = getPeriodKey(date);

      for (var e in data['exercices'] ?? []) {
        if (e['type'] == selectedExercise && (!onlyCompleted || e['accompli'] == true)) {
          final intensity = computeIntensity(
            int.tryParse(e['series'] ?? '1') ?? 1,
            int.tryParse(e['duration'] ?? '1') ?? 1,
            int.tryParse(e['restTime'] ?? '0') ?? 0,
          );
          grouped.putIfAbsent(key, () => []).add(intensity);
          counts.update(key, (v) => v + 1, ifAbsent: () => 1);
          noms[key] = data['nom'] ?? '';
          commentaires[key] = data['commentaire'] ?? '';
        }
      }
    }

    final points = grouped.entries.map((e) {
      final average = e.value.reduce((a, b) => a + b) / e.value.length;
      return AggregatedDataPoint(
        label: e.key,
        avgIntensity: average,
        count: counts[e.key] ?? 1,
        nom: noms[e.key] ?? '',
        commentaire: commentaires[e.key] ?? '',
        rawDate: DateTime.tryParse(e.key.split('-').first) ?? DateTime(2000), // approximation


      );
    }).toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    setState(() => dataPoints = points);
  }

  double computeIntensity(int series, int duration, int rest) {
    return (series * duration) / (1 + rest / 60);
  }

  String getPeriodKey(DateTime date) {
    switch (selectedPeriod) {
      case 'Année':
        return date.year.toString();
      case 'Mois':
        return DateFormat('yyyy-MM').format(date);
      case 'Semaine':
        final week = (date.day - date.weekday + 10) ~/ 7;
        return '${date.year}-W$week';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Historique des performances")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                DropdownButton<String>(
                  value: selectedExercise,
                  onChanged: (val) {
                    setState(() => selectedExercise = val!);
                    loadExerciseData();
                  },
                  items: exerciseOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                ),
                DropdownButton<String>(
                  value: selectedPeriod,
                  onChanged: (val) {
                    setState(() => selectedPeriod = val!);
                    loadExerciseData();
                  },
                  items: periodOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Uniquement accomplis"),
                    Switch(
                      value: onlyCompleted,
                      onChanged: (val) {
                        setState(() => onlyCompleted = val);
                        loadExerciseData();
                      },
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: dataPoints.isEmpty
                  ? const Center(child: Text("Aucune donnée trouvée"))
                  : Column(
                      children: [
                        SizedBox(
                          height: 300,
                          child: LineChart(
                            LineChartData(
                              lineTouchData: LineTouchData(
                                touchTooltipData: LineTouchTooltipData(
                                  tooltipBgColor: Colors.black87,
                                  getTooltipItems: (spots) => spots.map((spot) {
                                    final index = spot.x.toInt();
                                    final p = dataPoints[index];
                                    return LineTooltipItem('${p.nom}\n${p.commentaire}', const TextStyle(color: Colors.white));
                                  }).toList(),
                                ),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  isCurved: true,
                                  spots: dataPoints.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.avgIntensity)).toList(),
                                  barWidth: 3,
                                  color: Colors.blue,
                                  dotData: FlDotData(show: true),
                                ),
                              ],
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index >= dataPoints.length) return const SizedBox.shrink();
                                      if (dataPoints.length > 6 && index % 2 != 0) return const SizedBox.shrink();

                                      final key = dataPoints[index].label;

                                      String label;
                                      if (selectedPeriod == 'Semaine' && key.contains('-W')) {
                                        final parts = key.split('-W');
                                        label = 'S${parts[1]} ${parts[0]}';
                                      } else if (selectedPeriod == 'Mois' && key.contains('-')) {
                                        try {
                                          final date = DateTime.parse('$key-01');
                                          label = DateFormat('MMM yy').format(date);
                                        } catch (_) {
                                          label = key;
                                        }
                                      }
                                      else {
                                        label = key;
                                      }

                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6.0),
                                        child: Transform.rotate(
                                          angle: -0.5,
                                          child: Text(label, style: const TextStyle(fontSize: 10)),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: true, reservedSize: 36),
                                ),
                              ),
                              gridData: FlGridData(show: true),
                              borderData: FlBorderData(show: true),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            itemCount: dataPoints.length,
                            itemBuilder: (context, index) {
                              final p = dataPoints[index];

                              if (selectedPeriod == 'Jour') {
                                return ListTile(
                                  title: Text("${p.label} - Intensité : ${p.avgIntensity.toStringAsFixed(2)}"),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (p.series != null) Text("Séries : ${p.series}"),
                                      if (p.duration != null) Text("Durée : ${p.duration} min"),
                                      if (p.rest != null) Text("Repos : ${p.rest} sec"),
                                      if (p.nom.isNotEmpty || p.commentaire.isNotEmpty)
                                        Text("Programme : ${p.nom} • ${p.commentaire}"),
                                    ],
                                  ),
                                );
                              } else {
                                return ListTile(
                                  title: Text("${p.label} - Moy. intensité : ${p.avgIntensity.toStringAsFixed(2)}"),
                                  subtitle: Text("${p.count} programme(s) effectué(s)"),
                                );
                              }
                            },
                          ),
                        )
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class AggregatedDataPoint {
  final String label;
  final double avgIntensity;
  final int count;
  final String nom;
  final String commentaire;
  final DateTime rawDate; // 👈 Ajout ici
  final int? series;
  final int? duration;
  final int? rest;

  

  AggregatedDataPoint({
    required this.label,
    required this.avgIntensity,
    required this.count,
    required this.nom,
    required this.commentaire,
    required this.rawDate,
    this.series,
    this.duration,
    this.rest,
  });
}
