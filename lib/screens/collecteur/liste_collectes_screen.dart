import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../models/commande_model.dart';
import '../../models/tarif_model.dart';
import '../../providers/commande_providers.dart';
import '../../providers/services_providers.dart';
import '../../providers/tarif_providers.dart';
import '../../widgets/commande_card.dart';

/// Liste des demandes de collecte du jour, triées par créneau horaire.
class ListeCollectesScreen extends ConsumerWidget {
  final String collecteurId;

  const ListeCollectesScreen({super.key, required this.collecteurId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commandesAsync = ref.watch(commandesACollecterProvider);
    final tarifsAsync = ref.watch(tarifsProvider);

    return commandesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur : $e')),
      data: (commandes) {
        if (commandes.isEmpty) {
          return const Center(child: Text('Aucune collecte en attente.'));
        }
        final trie = [...commandes]
          ..sort((a, b) => a.creneauSouhaite.index.compareTo(b.creneauSouhaite.index));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: trie.length,
          itemBuilder: (context, index) {
            final commande = trie[index];
            final estAMoi = commande.collecteurId == collecteurId;
            final tarifs = tarifsAsync.valueOrNull ?? [];

            return CommandeCard(
              commande: commande,
              afficherClient: true,
              actions: _boutonAction(context, ref, commande, estAMoi, tarifs),
            );
          },
        );
      },
    );
  }

  Widget _boutonAction(
    BuildContext context,
    WidgetRef ref,
    CommandeModel commande,
    bool estAMoi,
    List<TarifModel> tarifs,
  ) {
    if (commande.statut == StatutCommande.demandeCreee) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => ref.read(firestoreServiceProvider).mettreAJourStatut(
                commandeId: commande.id,
                nouveauStatut: StatutCommande.collectePlanifiee,
                collecteurId: collecteurId,
              ),
          child: const Text('Prendre en charge'),
        ),
      );
    }

    if (commande.statut == StatutCommande.collectePlanifiee) {
      if (!estAMoi) {
        return const Text('Déjà pris en charge', style: TextStyle(color: Colors.black45));
      }
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => _ouvrirDialoguePoids(context, ref, commande, tarifs),
          child: const Text('Collecte effectuée'),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _ouvrirDialoguePoids(
    BuildContext context,
    WidgetRef ref,
    CommandeModel commande,
    List<TarifModel> tarifs,
  ) async {
    final controleurPoids = TextEditingController();

    final poids = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Poids estimé'),
        content: TextField(
          controller: controleurPoids,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Poids (kg)', suffixText: 'kg'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final valeur = double.tryParse(controleurPoids.text.replaceAll(',', '.'));
              Navigator.of(dialogContext).pop(valeur);
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    if (poids == null || poids <= 0) return;

    final tarif = tarifs.where((t) => t.typeService == commande.typeService).toList();
    final prixParKg = tarif.isNotEmpty ? tarif.first.prixParKg : 0;

    await ref.read(firestoreServiceProvider).mettreAJourStatut(
      commandeId: commande.id,
      nouveauStatut: StatutCommande.collecteEffectuee,
      champsSupplementaires: {
        'poidsEstimeKg': poids,
        'prixEstime': poids * prixParKg,
      },
    );
  }
}
