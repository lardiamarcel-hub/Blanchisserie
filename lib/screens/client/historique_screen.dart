import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/commande_providers.dart';
import '../../widgets/commande_card.dart';
import 'commande_detail_screen.dart';

/// Historique des commandes passées (livrées ou annulées) d'un client.
class HistoriqueScreen extends ConsumerWidget {
  final String clientId;

  const HistoriqueScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commandesAsync = ref.watch(commandesClientProvider(clientId));

    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: commandesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (commandes) {
          final terminees = commandes.where((c) => !c.statut.estActive).toList();
          if (terminees.isEmpty) {
            return const Center(child: Text('Aucune commande terminée pour le moment.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: terminees.length,
            itemBuilder: (context, index) {
              final commande = terminees[index];
              return CommandeCard(
                commande: commande,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CommandeDetailScreen(commande: commande)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
