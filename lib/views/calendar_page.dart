import 'package:easy_localization/easy_localization.dart';
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
          appBar: AppBar(title: Text(tr('calendar_tracking'))),
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
  calendarStyle: CalendarStyle(
    // ✅ Par défaut, texte adaptatif
    defaultTextStyle: TextStyle(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black,
    ),
    weekendTextStyle: TextStyle(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[300]
          : Colors.redAccent,
    ),
    outsideTextStyle: TextStyle(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[700]
          : Colors.grey,
    ),
    todayDecoration: BoxDecoration(
      color: Colors.blue.withOpacity(0.5),
      shape: BoxShape.circle,
    ),
    selectedDecoration: BoxDecoration(
      color: Colors.blue,
      shape: BoxShape.circle,
    ),
  ),
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
            color: color != null
                ? Colors.white
                : Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
          ),
        ),
      );
    },
  ),
),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _LegendItem(color: Colors.green, label: tr('legend_done')),
                    _LegendItem(color: Colors.orange, label: tr('legend_partial')),
                    _LegendItem(color: Colors.red, label: tr('legend_not_done')),
                  ],
                ),
                const Divider(height: 30),
                if (vm.selectedDay != null)
                 if (vm.isGenerating) const LinearProgressIndicator(),
const SizedBox(height: 12),

Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    Expanded(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.view_week),
        label: Text(tr('generate_week')),
        onPressed: vm.isGenerating
            ? null
            : () => _showPromptDialog(context, vm, 'week'),
      ),
    ),
    const SizedBox(width: 8),
    Expanded(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.calendar_month),
        label: Text(tr('generate_2weeks')),
        onPressed: vm.isGenerating
            ? null
            : () => _showPromptDialog(context, vm, 'month'),
      ),
    ),
  ],
),
const SizedBox(height: 12),

if (vm.selectedDay != null)
  Text(
    tr('program_for_date', args: [
      "${vm.selectedDay!.day.toString().padLeft(2, '0')}/"
      "${vm.selectedDay!.month.toString().padLeft(2, '0')}/${vm.selectedDay!.year}"
    ]),
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  )
else
  Text(tr('no_date_selected')),

                const SizedBox(height: 8),
                ElevatedButton.icon(
  icon: const Icon(Icons.copy),
  label: Text(tr('copy')),
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
                  Text(tr('no_program_that_day')),
                if (vm.selectedProgram != null)
                  Column(
                    children: [
                      Text("${tr('name')}: ${vm.selectedProgram!['nom']}"),
                      Text("${tr('commentary')}: ${vm.selectedProgram!['commentaire'] ?? '—'}"),
                      const SizedBox(height: 10),
                      ...(vm.selectedProgram!['exercices'] as List).map((e) {
                        final ex = Map<String, dynamic>.from(e);
                        List<String> specs = [];

                        if ((ex['subType'] ?? '').isNotEmpty) specs.add("${tr('subtype')}: ${ex['subType']}");
                        if ((ex['series'] ?? '').isNotEmpty) specs.add("${tr('series')}: ${ex['series']}");
                        if ((ex['repetitions'] ?? '').isNotEmpty) specs.add("${tr('repetitions')}: ${ex['repetitions']}");
                        if ((ex['duration'] ?? '').isNotEmpty) specs.add("${tr('duration')}: ${ex['duration']}");
                        if ((ex['distance'] ?? '').isNotEmpty) specs.add("${tr('distance')}: ${ex['distance']}");
                        if ((ex['intensity'] ?? '').isNotEmpty) specs.add("${tr('intensity')}: ${ex['intensity']}");
                        if ((ex['restTime'] ?? '').isNotEmpty) specs.add("${tr('rest')}: ${ex['restTime']}");

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
      label: Text(tr('edit')),
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
      label: Text(tr('delete')),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(tr('confirm_delete_title')),
            content: Text(tr('confirm_delete_content')),
            actions: [
              TextButton(child: Text(tr('cancel')), onPressed: () => Navigator.pop(context, false)),
              TextButton(child: Text(tr('delete')), onPressed: () => Navigator.pop(context, true)),
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
void _showPromptDialog(BuildContext context, CalendarViewModel vm, String range) {
  final controller = TextEditingController(text: vm.objectifCtrl.text);

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(tr('objective_for', args: [range == 'week' ? tr('generate_week') : tr('generate_2weeks')])),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: tr('describe_objective')),
        autofocus: true,
      ),
      actions: [
        TextButton(
          child: Text(tr('cancel')),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
        TextButton(
          child: Text(tr('validate')),
          onPressed: () {
            Navigator.of(ctx).pop();
            vm.objectifCtrl.text = controller.text;
            vm.generateBatch(context, range: range);
          },
        ),
      ],
    ),
  );
}

