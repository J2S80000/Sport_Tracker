import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:SportTracker/views/layout_page.dart';
import 'package:SportTracker/views/run_route_viewer_page.dart';
import 'package:SportTracker/services/run_save_service.dart';

/// Page listant les courses enregistrées (recordedRun) avec accès au tracé.
class MyRunsPage extends StatefulWidget {
  const MyRunsPage({super.key});

  @override
  State<MyRunsPage> createState() => _MyRunsPageState();
}

class _MyRunsPageState extends State<MyRunsPage> {
  List<_RunItem> _runs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRuns();
  }

  Future<void> _loadRuns() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _runs = [];
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('programmes')
          .limit(200)
          .get();

      final items = <_RunItem>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final jour = data['jour']?.toString() ?? doc.id;
        final exercices = data['exercices'] as List<dynamic>? ?? [];
        for (var i = 0; i < exercices.length; i++) {
          final ex = exercices[i];
          if (ex is! Map) continue;
          final map = Map<String, dynamic>.from(ex);
          if (map['recordedRun'] == true && map['route'] is List) {
            items.add(_RunItem(
              date: jour,
              exercise: map,
              programmeDocId: doc.id,
              exerciseIndex: i,
            ));
          }
        }
      }
      items.sort((a, b) => b.date.compareTo(a.date));
      setState(() {
        _runs = items;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _confirmDeleteRun(BuildContext context, _RunItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('delete_run')),
        content: Text(tr('delete_run_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(tr('delete')),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      await RunSaveService.deleteRecordedRun(
        programmeDocId: item.programmeDocId,
        exerciseIndex: item.exerciseIndex,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('run_deleted'))),
        );
        _loadRuns();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('my_runs_error'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutPage(
      title: tr('my_runs'),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                        const SizedBox(height: 16),
                        Text(tr('my_runs_error'), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _loadRuns,
                          icon: const Icon(Icons.refresh),
                          label: Text(tr('refresh_program')),
                        ),
                      ],
                    ),
                  ),
                )
              : _runs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_run,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            tr('my_runs_empty'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadRuns,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _runs.length,
                        itemBuilder: (context, index) {
                          final item = _runs[index];
                          return _RunCard(
                            item: item,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RunRouteViewerPage(
                                    exercise: item.exercise,
                                  ),
                                ),
                              );
                            },
                            onDelete: () => _confirmDeleteRun(context, item),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _RunItem {
  final String date;
  final Map<String, dynamic> exercise;
  final String programmeDocId;
  final int exerciseIndex;

  _RunItem({
    required this.date,
    required this.exercise,
    required this.programmeDocId,
    required this.exerciseIndex,
  });
}

class _RunCard extends StatelessWidget {
  final _RunItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RunCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ex = item.exercise;
    final runTitle = ex['runTitle']?.toString();
    final distance = ex['distance']?.toString() ?? '—';
    final duration = ex['duration']?.toString() ?? '—';
    final durationSec = (ex['durationSeconds'] as num?)?.toInt();
    final distanceKm = (ex['distanceKm'] as num?)?.toDouble();
    final dateStr = item.date.length >= 10 ? item.date.substring(0, 10) : item.date;

    String subtitle = '$distance · ${duration} min';
    if (durationSec != null && distanceKm != null) {
      final m = durationSec ~/ 60;
      final s = durationSec % 60;
      subtitle = '${distanceKm.toStringAsFixed(2)} km · $m:${s.toString().padLeft(2, '0')}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.directions_run,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      runTitle?.isNotEmpty == true ? runTitle! : dateStr,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (runTitle?.isNotEmpty == true)
                      Text(
                        dateStr,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                onPressed: onDelete,
                tooltip: tr('delete_run'),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
