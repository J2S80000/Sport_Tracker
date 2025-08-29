import 'package:SportTracker/models/exercise_block.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/aggregated_data_point.dart';
import '../viewmodels/history_view_model.dart';
// history_page.dart
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
                // Debug info (à supprimer en production)
                
                
                Wrap(
                  spacing: 10,
                  children: [
                    DropdownButton<String>(
      value: vm.selectedType,
      onChanged: (val) => vm.setType(val!),
      items: vm.typeOptions
          .map((e) => DropdownMenuItem(
            value: e, 
            child: Text(tr(e))
          ))
          .toList(),
    ),
                    /* ───────────── Menu par MÉTRIQUE ───────────── */
                    DropdownButton<String>(
                      value: vm.selectedMetric,
                      onChanged: (val) => vm.setMetric(val!),
                      items: vm.metricOptions
                          .map((e) => DropdownMenuItem(
                            value: e, 
                            child: Text(e)
                          ))
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
                        Container(
                          constraints: BoxConstraints(minWidth: 100),
                          child: Text(
                            vm.selectedSubType.isNotEmpty ? tr(vm.selectedSubType) : tr('all_subtypes'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
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
                
                // Bouton de rechargement manuel pour le debug
                ElevatedButton(
                  onPressed: vm.loadData,
                  child: Text('Recharger les données'),
                ),
                
                const SizedBox(height: 10),
                
                Expanded(
                  child: vm.isLoading
                      ? Center(child: CircularProgressIndicator())
                      : vm.dataPoints.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                                  const SizedBox(height: 16),
                                  Text(
                                    tr('no_data_found'),
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Vérifiez les critères de filtrage ci-dessus',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
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
                                              .map((e) {
                                                final value = vm.selectedMetric == 'Intensité' 
                                                  ? e.value.avgIntensity
                                                  : vm.selectedMetric == 'Calories'
                                                    ? (e.value.totalCalories ?? 0)
                                                    : (e.value.count?.toDouble() ?? 0); // Pour 'Séances'
                                                return FlSpot(e.key.toDouble(), value);
                                              })
                                              .toList(),
                                          barWidth: 3,
                                          color: vm.selectedMetric == 'Intensité' 
                                            ? Colors.blue 
                                            : vm.selectedMetric == 'Calories'
                                              ? Colors.red
                                              : Colors.green,
                                          dotData: FlDotData(show: true),
                                        )
                                      ],
                                      lineTouchData: LineTouchData(
                                        touchTooltipData: LineTouchTooltipData(
                                          getTooltipItems: (spots) => spots.map((s) {
                                            final i = s.x.toInt();
                                            if (i >= vm.dataPoints.length) return null;
                                            final p = vm.dataPoints[i];
                                            
                                            String tooltipText;
                                            if (vm.selectedMetric == 'Intensité') {
                                              tooltipText = '${p.nom}\n${p.commentaire}\nIntensité: ${p.avgIntensity.toStringAsFixed(2)}';
                                            } else if (vm.selectedMetric == 'Calories') {
                                              tooltipText = '${p.nom}\nCalories: ${p.totalCalories?.round() ?? 0} kcal\nDate: ${p.label}';
                                            } else {
                                              tooltipText = '${p.nom}\nSéances: ${p.count}\nDate: ${p.label}';
                                            }
                                            
                                            return LineTooltipItem(
                                              tooltipText, 
                                              const TextStyle(color: Colors.white)
                                            );
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
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, _) {
                                              String unit = '';
                                              if (vm.selectedMetric == 'Intensité') unit = '';
                                              else if (vm.selectedMetric == 'Calories') unit = ' kcal';
                                              else if (vm.selectedMetric == 'Séances') unit = '';
                                              
                                              return Text('${value.round()}$unit', style: const TextStyle(fontSize: 10));
                                            },
                                            reservedSize: 40,
                                          ),
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
  return Expanded(
  child: ListView.builder(
    itemCount: vm.dataPoints.length,
    itemBuilder: (_, index) {
      final p = vm.dataPoints[index];

      if (vm.selectedPeriod == 'Jour') {
        return Card(
          child: ListTile(
            title: Text("${p.label} - ${tr(vm.selectedMetric.toLowerCase())}: ${
              vm.selectedMetric == 'Intensité' ? p.avgIntensity.toStringAsFixed(2) :
              vm.selectedMetric == 'Calories' ? '${p.totalCalories?.round() ?? 0} kcal' :
              '${p.count}'
            }"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${tr('exercise')}: ${tr(p.type ?? 'unknown_type')}${p.subType.isNotEmpty ? ' > ${tr(p.subType)}' : ''}"),

                if (vm.selectedMetric == 'Intensité') ...[
                  if ({
                    'street_workout',
                    'plyometrics',
                    'weight_training',
                    'shadow_boxing',
                    'free_cardio'
                  }.contains(p.type) && p.series != null)
                    Text("${tr('series')}: ${p.series}"),

                  if ({
                    'running',
                    'shadow_boxing',
                    'free_cardio',
                    'active_rest'
                  }.contains(p.type) && p.duration != null)
                    Text("${tr('duration')}: ${p.duration} min"),

                  if (p.type == 'weight_training' && p.weight != null)
                    Text("${tr('weight')}: ${p.weight} kg"),

                  if (p.rest != null && p.rest! > 0)
                    Text("${tr('rest_time')}: ${p.rest} s"),
                ],

                if (p.nom.isNotEmpty || p.commentaire.isNotEmpty)
                  Text("${tr('program')}: ${p.nom} - ${p.commentaire}"),
              ],
            ),
          ),
        );
      } else {
        return Card(
          child: ListTile(
            title: Text("${p.label} - ${tr(vm.selectedMetric.toLowerCase())}: ${
              vm.selectedMetric == 'Intensité' ? p.avgIntensity.toStringAsFixed(2) :
              vm.selectedMetric == 'Calories' ? '${p.totalCalories?.round() ?? 0} kcal' :
              '${p.count}'
            }"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (vm.selectedMetric == 'Intensité' || vm.selectedMetric == 'Séances')
                  Text("${tr('programs_completed')}: ${p.count}"),
                
                if (vm.selectedMetric == 'Calories')
                  Text("${tr('total_calories')}: ${p.totalCalories?.round() ?? 0} kcal"),
              ],
            ),
          ),
        );
      }
    },
  ),
  );
} else {
                                        return Card(
                                          child: ListTile(
                                            title: Text("${p.label} - ${tr('avg_intensity')}: ${p.avgIntensity.toStringAsFixed(2)}"),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text("${tr('programs_completed')}: ${p.count}"),
                                                if (p.totalCalories != null && p.totalCalories! > 0)
                                                  Text("${tr('calories_burned')}: ${p.totalCalories!.round()} kcal"),
                                              ],
                                            ),
                                          ),
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
