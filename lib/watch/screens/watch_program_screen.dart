import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WatchProgramScreen extends StatefulWidget {
  const WatchProgramScreen({super.key, this.program});

  final Map<String, dynamic>? program;

  @override
  State<WatchProgramScreen> createState() => _WatchProgramScreenState();
}

class _WatchProgramScreenState extends State<WatchProgramScreen> {
  Map<String, dynamic>? get _program => widget.program;
  List<Map<String, dynamic>>? _exercices;

  @override
  void initState() {
    super.initState();
    _exercices = _program != null
        ? List<Map<String, dynamic>>.from(
            (_program!['exercices'] as List? ?? []).map((e) => Map<String, dynamic>.from(e is Map ? e : {})))
        : null;
  }

  @override
  void didUpdateWidget(WatchProgramScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.program != oldWidget.program) {
      _exercices = widget.program != null
          ? List<Map<String, dynamic>>.from(
              (widget.program!['exercices'] as List? ?? []).map((e) => Map<String, dynamic>.from(e is Map ? e : {})))
          : null;
    }
  }

  Future<void> _toggleAccompli(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _program == null || _exercices == null || index >= _exercices!.length) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('programmes')
        .where('jour', isGreaterThanOrEqualTo: today)
        .where('jour', isLessThan: '${today}T23:59:59.999')
        .get();
    if (snapshot.docs.isEmpty) return;
    final docRef = snapshot.docs.first.reference;
    _exercices![index]['accompli'] = !(_exercices![index]['accompli'] == true);
    await docRef.update({'exercices': _exercices});
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final exercices = _exercices ?? _program?['exercices'] as List? ?? [];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('exercises_list')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: exercices.isEmpty
          ? Center(
              child: Text(
                tr('no_program_today'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: exercices.length,
              itemBuilder: (context, index) {
                final ex = Map<String, dynamic>.from(
                  exercices[index] is Map ? exercices[index] as Map : {},
                );
                final accompli = ex['accompli'] == true;
                final type = ex['type'] ?? 'unknown_type';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      accompli ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: accompli ? Colors.green : theme.colorScheme.outline,
                      size: 22,
                    ),
                    title: Text(
                      tr(type),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        decoration: accompli ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _toggleAccompli(index),
                  ),
                );
              },
            ),
    );
  }
}
