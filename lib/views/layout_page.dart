import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LayoutPage extends StatelessWidget {
  final String title;
  final Widget child;

  const LayoutPage({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          // Bouton paramètres
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const _SettingsDialog(),
              );
            },
          ),

          // Bouton logout
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: child,
    );
  }
}

class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog();

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  final _poidsController = TextEditingController();
  final _tailleController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    _poidsController.text = data['poids']?.toString() ?? '';
    _tailleController.text = data['taille']?.toString() ?? '';
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final poids = double.tryParse(_poidsController.text)?.round();
final taille = double.tryParse(_tailleController.text)?.round();
    if (poids == null || taille == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Valeurs invalides")),
      );
      return;
    }

    setState(() => isLoading = true);

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'poids': poids,
      'taille': taille,
    });

    setState(() => isLoading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Paramètres"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _poidsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Poids (kg)"),
          ),
          TextField(
            controller: _tailleController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Taille (cm)"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text("Annuler"),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _save,
          child: isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Enregistrer"),
        ),
      ],
    );
  }
}
