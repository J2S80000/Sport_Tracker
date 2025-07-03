import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/program.dart';
// Ensure that the Program class is defined in program.dart and exported properly.


class ProgramController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

Future<void> saveProgram(Program p) async {
  try {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('programmes')
        .doc(p.date.substring(0,10))   // une clé = la date
        .set(p.toMap());
  } catch (e, st) {
    debugPrint('🔥 saveProgram error : $e\n$st');
    rethrow;
  }
}
}
