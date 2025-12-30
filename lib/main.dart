import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app/app.dart';
import 'app/env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (optional - app works in local-only mode without it)
  try {
    await Firebase.initializeApp();

    // Configure Firebase emulator if enabled (for local development)
    if (Env.useFirebaseEmulator) {
      FirebaseFirestore.instance.useFirestoreEmulator(
        Env.firestoreEmulatorHost,
        Env.firestoreEmulatorPort,
      );
    }
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('⚠️ Firebase initialization skipped: $e');
    debugPrint('ℹ️ App running in local-only mode');
  }

  runApp(const ProviderScope(child: PropLedgerApp()));
}
