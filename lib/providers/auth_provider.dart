import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import 'services_providers.dart';

/// État de connexion Firebase Auth (null = déconnecté).
final etatAuthProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).changementsUtilisateur;
});

/// Profil Firestore (`users/{uid}`) de l'utilisateur actuellement connecté,
/// mis à jour en temps réel. Null tant que non connecté.
final profilUtilisateurProvider = StreamProvider<UserModel?>((ref) {
  final auth = ref.watch(etatAuthProvider).valueOrNull;
  if (auth == null) return Stream.value(null);
  return ref.watch(firestoreServiceProvider).streamUtilisateur(auth.uid);
});

/// À la toute première connexion, `users/{uid}` n'existe pas encore : ce
/// provider crée le profil (récupération d'un pré-enregistrement gérant
/// pour un collecteur, ou profil client vierge par défaut). Le stream
/// [profilUtilisateurProvider] capte ensuite le document nouvellement créé.
final resolutionProfilProvider =
    FutureProvider.family<void, ({String uid, String telephone})>((ref, params) async {
  await ref.watch(firestoreServiceProvider).resoudreProfilApresConnexion(
        uid: params.uid,
        telephone: params.telephone,
      );
});

/// Initialise les notifications push et enregistre le token FCM une seule
/// fois par utilisateur connecté (Riverpod met ce Future en cache tant que
/// le provider reste "watché" avec le même [uid]).
final synchronisationNotificationProvider = FutureProvider.family<void, String>((ref, uid) async {
  final notifService = ref.watch(notificationServiceProvider);
  await notifService.initialiser();
  final token = await notifService.obtenirToken();
  final firestoreService = ref.watch(firestoreServiceProvider);
  if (token != null) {
    await firestoreService.enregistrerTokenNotification(uid, token);
  }
  notifService.surRenouvellementToken.listen((nouveauToken) {
    firestoreService.enregistrerTokenNotification(uid, nouveauToken);
  });
});
