import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:easy_localization/easy_localization.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'package:fleet/services/firebase_service.dart';
import 'package:fleet/services/membership_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize easy_localization
  await EasyLocalization.ensureInitialized();
  
  // Initialize dotenv before Firebase  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize our Firebase service
  final firebaseService = FirebaseService();
  await firebaseService.initialize();
  await firebaseService.configurePersistence();
  
  // Initialize MembershipSyncService
  MembershipSyncService().initialize();
  
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('tr')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}