import 'package:flutter/material.dart';
import 'add_performance_page.dart';
import 'add_program_page.dart';

class AddSomethingPage extends StatelessWidget {
  const AddSomethingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.directions_run),
              label: const Text("Ajouter une performance"),
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
              label: const Text("Ajouter un programme d'entraînement"),
              onPressed: () {Navigator.push(
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
