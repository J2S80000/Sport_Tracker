import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/program.dart';


class ProgramController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveProgram(Program program) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');
  print("Tentative de sauvegarde pour l'utilisateur ${user.uid}");


    await _db
        .collection('users')
        .doc(user.uid)
        .collection('programmes')
        .add(program.toMap());
  }
}
