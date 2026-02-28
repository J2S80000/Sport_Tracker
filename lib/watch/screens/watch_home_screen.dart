import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:SportTracker/watch/widgets/watch_stat_chip.dart';
import 'package:SportTracker/watch/screens/watch_program_screen.dart';

class WatchHomeScreen extends StatefulWidget {
  const WatchHomeScreen({super.key});

  @override
  State<WatchHomeScreen> createState() => _WatchHomeScreenState();
}

class _WatchHomeScreenState extends State<WatchHomeScreen> {
  Map<String, dynamic>? _program;
  bool _loading = true;
  String _today = DateTime.now().toIso8601String().substring(0, 10);

  @override
  void initState() {
    super.initState();
    _loadTodayProgram();
  }

  Future<void> _loadTodayProgram() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('programmes')
          .where('jour', isGreaterThanOrEqualTo: _today)
          .where('jour', isLessThan: '${_today}T23:59:59.999')
          .get();

      if (mounted) {
        setState(() {
          _loading = false;
          if (snapshot.docs.isNotEmpty) {
            _program = snapshot.docs.first.data();
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final steps = (_program?['pas'] ?? 0) as int;
    final caloriesPas = (_program?['calories_pas'] ?? 0) as int;
    final caloriesExos = (_program?['calories_exercices'] ?? 0) as int;
    final totalCal = caloriesPas + caloriesExos;
    final exercices = _program?['exercices'] as List? ?? [];
    final done = exercices.where((e) => e['accompli'] == true).length;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr('program_of_the_day'),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: WatchStatChip(
                      icon: Icons.directions_walk,
                      value: '$steps',
                      label: tr('steps_today'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: WatchStatChip(
                      icon: Icons.local_fire_department,
                      value: '$totalCal',
                      label: tr('calories_burned'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: WatchStatChip(
                      icon: Icons.fitness_center,
                      value: '$done/${exercices.length}',
                      label: tr('exercises_list'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => WatchProgramScreen(program: _program),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list_alt, size: 18),
                  label: Text(tr('exercises_list')),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                icon: const Icon(Icons.logout, size: 16),
                label: Text(tr('logout')),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
