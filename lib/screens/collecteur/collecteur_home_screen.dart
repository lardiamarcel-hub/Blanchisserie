import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../../providers/services_providers.dart';
import 'liste_collectes_screen.dart';
import 'liste_livraisons_screen.dart';

/// Accueil du collecteur : deux onglets, collectes à faire et livraisons à
/// faire. Pas de carte/GPS en V1 — l'adresse texte et le téléphone
/// suffisent pour un périmètre d'un immeuble et son quartier.
class CollecteurHomeScreen extends ConsumerWidget {
  final UserModel utilisateur;

  const CollecteurHomeScreen({super.key, required this.utilisateur});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Bonjour ${utilisateur.nom.split(' ').first}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Déconnexion',
              onPressed: () => ref.read(authServiceProvider).deconnexion(),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.local_shipping_outlined), text: 'Collectes'),
              Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Livraisons'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListeCollectesScreen(collecteurId: utilisateur.uid),
            ListeLivraisonsScreen(collecteurId: utilisateur.uid),
          ],
        ),
      ),
    );
  }
}
