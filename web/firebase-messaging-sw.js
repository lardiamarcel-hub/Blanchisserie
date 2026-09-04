// Service worker Firebase Cloud Messaging pour le web : affiche les
// notifications push reçues quand l'onglet n'est pas au premier plan (ou
// fermé). Les notifications reçues onglet actif sont, elles, gérées côté
// Dart (voir lib/services/notification_service.dart).
//
// IMPORTANT : remplacez les valeurs ci-dessous par celles de votre appli
// web Firebase (identiques à DefaultFirebaseOptions.web dans
// lib/firebase_options.dart, générées par `flutterfire configure`).
// Ce fichier tourne hors du contexte Dart/Flutter : il ne peut pas lire
// firebase_options.dart, les valeurs doivent donc être dupliquées ici.

importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'REMPLACER_APRES_FLUTTERFIRE_CONFIGURE',
  authDomain: 'REMPLACER_APRES_FLUTTERFIRE_CONFIGURE',
  projectId: 'REMPLACER_APRES_FLUTTERFIRE_CONFIGURE',
  storageBucket: 'REMPLACER_APRES_FLUTTERFIRE_CONFIGURE',
  messagingSenderId: 'REMPLACER_APRES_FLUTTERFIRE_CONFIGURE',
  appId: 'REMPLACER_APRES_FLUTTERFIRE_CONFIGURE',
});

// Le SDK compat affiche automatiquement une notification native pour tout
// message FCM contenant un payload "notification" reçu en arrière-plan ;
// aucun gestionnaire supplémentaire n'est nécessaire pour la V1.
firebase.messaging();
