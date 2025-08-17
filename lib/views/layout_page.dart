import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

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

  Locale? _selectedLocale;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedLocale ??= context.locale;
  }

  // ... reste du code inchangé ...

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
        SnackBar(content: Text(tr("invalid_values"))),
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

  void _changeLanguage(Locale locale) {
    setState(() {
      _selectedLocale = locale;
    });
    context.setLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr("settings")),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _poidsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: tr("weight_kg")),
            ),
            TextField(
              controller: _tailleController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: tr("height_cm")),
            ),
            const SizedBox(height: 20),
            DropdownButton<Locale>(
              value: _selectedLocale,
              onChanged: (Locale? locale) {
                if (locale != null) {
                  _changeLanguage(locale);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: Locale('fr'),
                  child: Text('Français'),
                ),
                DropdownMenuItem(
                  value: Locale('en'),
                  child: Text('English'),
                ),
                DropdownMenuItem(
                  value: Locale('es'),
                  child: Text('Español'),
                ),
                
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: Text(tr("cancel")),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _save,
          child: isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(tr("save")),
        ),
      ],
    );
  }
}
