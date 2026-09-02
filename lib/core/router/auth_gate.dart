import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/phone_login_screen.dart';
import '../../screens/auth/profile_setup_screen.dart';
import '../../screens/client/client_home_screen.dart';
import '../../screens/collecteur/collecteur_home_screen.dart';
import '../../screens/gerant/gerant_dashboard_screen.dart';
import '../../screens/splash_screen.dart';

/// Aiguille l'utilisateur vers le bon écran selon son état de connexion,
/// son rôle et l'avancement de son profil. C'est le seul endroit de l'app
/// qui décide "quel écran racine afficher".
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etatAuth = ref.watch(etatAuthProvider);

    return etatAuth.when(
      loading: () => const SplashScreen(),
      error: (_, __) => const PhoneLoginScreen(),
      data: (utilisateurFirebase) {
        if (utilisateurFirebase == null) return const PhoneLoginScreen();

        final profil = ref.watch(profilUtilisateurProvider);
        return profil.when(
          loading: () => const SplashScreen(),
          error: (_, __) => const SplashScreen(),
          data: (utilisateur) {
            if (utilisateur == null) {
              // Première connexion : crée le profil Firestore, puis le
              // stream ci-dessus captera automatiquement le document créé.
              ref.watch(resolutionProfilProvider((
                uid: utilisateurFirebase.uid,
                telephone: utilisateurFirebase.phoneNumber ?? '',
              )));
              return const SplashScreen();
            }

            ref.watch(synchronisationNotificationProvider(utilisateur.uid));

            if (utilisateur.role == RoleUtilisateur.client && !utilisateur.profilComplet) {
              return ProfileSetupScreen(utilisateur: utilisateur);
            }

            switch (utilisateur.role) {
              case RoleUtilisateur.client:
                return ClientHomeScreen(utilisateur: utilisateur);
              case RoleUtilisateur.collecteur:
                return CollecteurHomeScreen(utilisateur: utilisateur);
              case RoleUtilisateur.gerant:
                return const GerantDashboardScreen();
            }
          },
        );
      },
    );
  }
}
