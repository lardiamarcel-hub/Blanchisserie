import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/firestore_service.dart';

/// Gère les notifications FCM reçues alors que l'app est en arrière-plan
/// ou totalement fermée. Doit rester une fonction top-level.
@pragma('vm:entry-point')
Future<void> gererMessageArrierePlan(RemoteMessage message) async {
  // Rien à faire ici : le système affiche déjà la notification à partir
  // de sa charge utile "notification". On garde ce handler pour permettre
  // un traitement de données personnalisé plus tard si besoin.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(gererMessageArrierePlan);

  // Active la persistance offline Firestore : les commandes créées ou les
  // statuts changés sans réseau sont mis en file d'attente localement et
  // synchronisés automatiquement dès que la connexion revient.
  FirestoreService.activerPersistanceHorsLigne();

  await initializeDateFormatting('fr_FR', null);

  runApp(const ProviderScope(child: BlanchisserieApp()));
}
