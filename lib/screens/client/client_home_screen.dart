import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../providers/commande_providers.dart';
import '../../providers/services_providers.dart';
import '../../widgets/commande_card.dart';
import 'commande_detail_screen.dart';
import 'creer_commande_screen.dart';
import 'historique_screen.dart';

/// Écran d'accueil du client : commande(s) en cours + accès rapide à
/// l'historique et à une nouvelle demande de collecte.
class ClientHomeScreen extends ConsumerWidget {
  final UserModel utilisateur;

  const ClientHomeScreen({super.key, required this.utilisateur});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commandesAsync = ref.watch(commandesClientProvider(utilisateur.uid));

    return Scaffold(
      appBar: AppBar(
        title: Text('Bonjour ${utilisateur.nom.split(' ').first}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historique',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => HistoriqueScreen(clientId: utilisateur.uid)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () => ref.read(authServiceProvider).deconnexion(),
          ),
        ],
      ),
      body: commandesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (commandes) {
          final actives = commandes.where((c) => c.statut.estActive).toList();

          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  actives.isEmpty ? 'Aucune commande en cours' : 'Commande(s) en cours',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (actives.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Demandez une collecte, on s\'occupe du reste.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                else
                  ...actives.map(
                    (c) => CommandeCard(
                      commande: c,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => CommandeDetailScreen(commande: c)),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Demander une collecte'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreerCommandeScreen(utilisateur: utilisateur),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
