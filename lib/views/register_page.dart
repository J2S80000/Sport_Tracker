import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController poidsController = TextEditingController();
  final TextEditingController tailleController = TextEditingController();
  String errorMessage = '';
Future<void> register() async {
  try {
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    // Ajouter les données personnalisées dans Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(credential.user!.uid)
        .set({
      'email': emailController.text.trim(),
      'poids': double.tryParse(poidsController.text.trim()) ?? 0,
      'taille': double.tryParse(tailleController.text.trim()) ?? 0,
    });

    Navigator.pop(context); // Retour à la page précédente après succès
  } catch (e) {
    setState(() {
      errorMessage = 'Erreur : ${e.toString()}';
    });
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Créer un compte")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Mot de passe"),
              obscureText: true,
            ),TextField(
  controller: poidsController,
  decoration: const InputDecoration(labelText: "Poids (kg)"),
  keyboardType: TextInputType.number,
),
TextField(
  controller: tailleController,
  decoration: const InputDecoration(labelText: "Taille (cm)"),
  keyboardType: TextInputType.number,
),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: register,
              child: const Text("S'inscrire"),
            ),
            if (errorMessage.isNotEmpty)
              Text(errorMessage, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
