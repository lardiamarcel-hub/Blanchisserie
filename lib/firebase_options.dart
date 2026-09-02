// ignore_for_file: type=lint
// GÉNÉRÉ AUTOMATIQUEMENT PAR FLUTTERFIRE — CE FICHIER EST UN GABARIT.
//
// Ce fichier doit être régénéré avec les vraies clés de votre projet
// Firebase avant tout build :
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// La commande écrasera ce fichier avec les valeurs correctes pour Android
// (et iOS le cas échéant). Voir le README pour le détail de la procédure.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions n\'a pas été configuré pour le web. '
        'Exécutez `flutterfire configure`.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions n\'est pas configuré pour cette plateforme. '
          'Exécutez `flutterfire configure`.',
        );
    }
  }

  // Valeurs à remplacer par `flutterfire configure` — voir le README.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REMPLACER_APRES_FLUTTERFIRE_CONFIGURE',
    appId: 'REMPLACER_APRES_FLUTTERFIRE_CONFIGURE',
    messagingSenderId: 'REMPLACER_APRES_FLUTTERFIRE_CONFIGURE',
    projectId: 'REMPLACER_APRES_FLUTTERFIRE_CONFIGURE',
    storageBucket: 'REMPLACER_APRES_FLUTTERFIRE_CONFIGURE',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REMPLACER_APRES_FLUTTERFIRE_CONFIGURE',
    appId: 'REMPLACER_APRES_FLUTTERFIRE_CONFIGURE',
    messagingSenderId: 'REMPLACER_APRES_FLUTTERFIRE_CONFIGURE',
    projectId: 'REMPLACER_APRES_FLUTTERFIRE_CONFIGURE',
    storageBucket: 'REMPLACER_APRES_FLUTTERFIRE_CONFIGURE',
    iosBundleId: 'com.blanchisserie.app',
  );
}
