import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../main.dart'; // 🔁 pour relancer MainApp après enregistrement

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final TextEditingController poidsController = TextEditingController();
  final TextEditingController tailleController = TextEditingController();
  String error = '';

  Future<void> saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'poids': double.tryParse(poidsController.text),
        'taille': double.tryParse(tailleController.text),
        'createdAt': DateTime.now(),
      });

      if (mounted) {
        // 🔁 relancer l'app pour recalculer les pages avec le doc maintenant présent
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainApp()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = '${tr("error")}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("Affichage de CompleteProfilePage");

    return Scaffold(
      appBar: AppBar(title: Text(tr('complete_profile'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: poidsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: tr("weight")),
            ),
            TextField(
              controller: tailleController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: tr("height")),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveProfile,
              child: Text(tr("save")),
            ),
            if (error.isNotEmpty)
              Text(error, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
