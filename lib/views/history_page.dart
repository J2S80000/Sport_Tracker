import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/aggregated_data_point.dart';
import '../viewmodels/history_view_model.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HistoryViewModel()..loadData(),
      child: Consumer<HistoryViewModel>(
        builder: (context, vm, _) => Scaffold(
          appBar: AppBar(title: Text(tr('history'))),
          body: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
               Wrap(
  spacing: 10,
  children: [
    /* ───────────── Menu par TYPE ───────────── */
    DropdownButton<String>(
      value: vm.selectedType,
      onChanged: (val) => vm.setType(val!),
      items: vm.typeOptions
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
    ),

    /* ─────────── Flèches sous-type ─────────── */
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: vm.previousSubType,
        ),
        Text(vm.selectedSubType,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: vm.nextSubType,
        ),
      ],
    ),

    /* ─────────── Période + switch ─────────── */
    DropdownButton<String>(
      value: vm.selectedPeriod,
      onChanged: (val) => vm.setPeriod(val!),
      items: vm.periodOptions
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
    ),
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(tr('only_completed')),
        Switch(value: vm.onlyCompleted, onChanged: vm.toggleCompleted),
      ],
    ),
  ],
),
                const SizedBox(height: 10),
                Expanded(
                  child: vm.dataPoints.isEmpty
                      ? Center(child: Text(tr('no_data_found')))
                      : Column(
                          children: [
                            SizedBox(
                              height: 300,
                              child: LineChart(
                                LineChartData(
                                  lineBarsData: [
                                    LineChartBarData(
                                      isCurved: true,
                                      spots: vm.dataPoints
                                          .asMap()
                                          .entries
                                          .map((e) => FlSpot(e.key.toDouble(), e.value.avgIntensity))
                                          .toList(),
                                      barWidth: 3,
                                      color: Colors.blue,
                                      dotData: FlDotData(show: true),
                                    )
                                  ],
                                  lineTouchData: LineTouchData(
                                    touchTooltipData: LineTouchTooltipData(
                                      getTooltipItems: (spots) => spots.map((s) {
                                        final i = s.x.toInt();
                                        final p = vm.dataPoints[i];
                                        return LineTooltipItem('${p.nom}\n${p.commentaire}', const TextStyle(color: Colors.white));
                                      }).toList(),
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, _) {
                                          final i = value.toInt();
                                          if (i >= vm.dataPoints.length) return const SizedBox.shrink();
                                          final label = vm.dataPoints[i].label;
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 6.0),
                                            child: Transform.rotate(
                                              angle: -0.5,
                                              child: Text(label, style: const TextStyle(fontSize: 10)),
                                            ),
                                          );
                                        },
                                        interval: 1,
                                        reservedSize: 36,
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
                                itemCount: vm.dataPoints.length,
                                itemBuilder: (_, index) {
  final p = vm.dataPoints[index];

                  if (vm.selectedPeriod == 'Jour') {
                    return ListTile(
                      title: Text("${p.label} - ${tr('intensity', args: [p.avgIntensity.toStringAsFixed(2)])}"),
subtitle: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(tr('exercise', args: [p.type, p.subType])),

    if ([
      'Street Workout',
      'Plyometrie',
      'Renfo avec charges',
      'Shadow Boxing',
      'Cardio libre'
    ].contains(p.type) && p.series != null)
      Text(tr('series', args: [p.series.toString()])),

    if ([
      'Course',
      'Shadow Boxing',
      'Cardio libre',
      'Repos actif'
    ].contains(p.type) && p.duration != null)
      Text(tr('duration', args: [p.duration.toString()])),

    if (p.type == 'Renfo avec charges' && p.weight != null)
      Text(tr('weight', args: [p.weight.toString()])),

    if (p.rest != null)
      Text(tr('rest', args: [p.rest.toString()])),

    if (p.nom.isNotEmpty || p.commentaire.isNotEmpty)
      Text(tr('program', args: [p.nom, p.commentaire])),

    if (p.totalCalories != null)
      Text(tr('calories_burned_value', args: [p.totalCalories!.round().toString()]))
  ],
),
                    );
                  } else {
                    return ListTile(
                      title: Text("${p.label} - ${tr('avg_intensity', args: [p.avgIntensity.toStringAsFixed(2)])}"),
                      subtitle: Text(tr('programs_done', args: [p.count.toString()])),
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
        ),
      ),
    );
  }
}
