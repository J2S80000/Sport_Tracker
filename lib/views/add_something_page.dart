import 'package:flutter/material.dart';
import 'add_performance_page.dart';
import 'add_program_page.dart';
import 'package:easy_localization/easy_localization.dart';

class AddSomethingPage extends StatelessWidget {
  const AddSomethingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('add_something'))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.directions_run),
              label: Text(tr('add_performance')),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddPerformancePage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.fitness_center),
              label: Text(tr('add_training_program')),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddProgramPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
