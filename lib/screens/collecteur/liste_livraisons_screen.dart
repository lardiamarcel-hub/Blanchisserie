import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../models/commande_model.dart';
import '../../models/tarif_model.dart';
import '../../providers/commande_providers.dart';
import '../../providers/services_providers.dart';
import '../../providers/tarif_providers.dart';
import '../../widgets/commande_card.dart';

/// Liste des commandes prêtes à livrer / en cours de livraison.
class ListeLivraisonsScreen extends ConsumerWidget {
  final String collecteurId;

  const ListeLivraisonsScreen({super.key, required this.collecteurId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commandesAsync = ref.watch(commandesALivrerProvider);
    final tarifsAsync = ref.watch(tarifsProvider);

    return commandesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur : $e')),
      data: (commandes) {
        if (commandes.isEmpty) {
          return const Center(child: Text('Aucune livraison en attente.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: commandes.length,
          itemBuilder: (context, index) {
            final commande = commandes[index];
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
    if (commande.statut == StatutCommande.pret) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => ref.read(firestoreServiceProvider).mettreAJourStatut(
                commandeId: commande.id,
                nouveauStatut: StatutCommande.enLivraison,
                collecteurId: collecteurId,
              ),
          child: const Text('Prendre en charge'),
        ),
      );
    }

    if (commande.statut == StatutCommande.enLivraison) {
      if (!estAMoi) {
        return const Text('Déjà pris en charge', style: TextStyle(color: Colors.black45));
      }
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => _ouvrirDialoguePaiement(context, ref, commande, tarifs),
          child: const Text('Livré'),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _ouvrirDialoguePaiement(
    BuildContext context,
    WidgetRef ref,
    CommandeModel commande,
    List<TarifModel> tarifs,
  ) async {
    final resultat = await showDialog<_ResultatLivraison>(
      context: context,
      builder: (_) => _DialoguePaiement(commande: commande),
    );
    if (resultat == null) return;

    final tarif = tarifs.where((t) => t.typeService == commande.typeService).toList();
    final prixParKg = tarif.isNotEmpty ? tarif.first.prixParKg : 0;
    final prixFinal = resultat.poidsReel * prixParKg;

    await ref.read(firestoreServiceProvider).mettreAJourStatut(
      commandeId: commande.id,
      nouveauStatut: StatutCommande.livree,
      champsSupplementaires: {
        'poidsReelKg': resultat.poidsReel,
        'prixFinal': prixFinal,
        'paye': resultat.paye,
        if (resultat.modePaiement != null) 'modePaiement': resultat.modePaiement!.valeur,
      },
    );
  }
}

class _ResultatLivraison {
  final double poidsReel;
  final ModePaiement? modePaiement;
  final bool paye;

  _ResultatLivraison({required this.poidsReel, required this.modePaiement, required this.paye});
}

enum _ChoixPaiement { especes, mobileMoney, aEncaisser }

class _DialoguePaiement extends StatefulWidget {
  final CommandeModel commande;

  const _DialoguePaiement({required this.commande});

  @override
  State<_DialoguePaiement> createState() => _DialoguePaiementState();
}

class _DialoguePaiementState extends State<_DialoguePaiement> {
  late final TextEditingController _controleurPoids;
  _ChoixPaiement _choix = _ChoixPaiement.especes;

  @override
  void initState() {
    super.initState();
    _controleurPoids = TextEditingController(
      text: widget.commande.poidsEstimeKg?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _controleurPoids.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmer la livraison'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controleurPoids,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Poids final (kg)', suffixText: 'kg'),
          ),
          const SizedBox(height: 16),
          const Text('Paiement', style: TextStyle(fontWeight: FontWeight.w600)),
          RadioListTile<_ChoixPaiement>(
            contentPadding: EdgeInsets.zero,
            value: _ChoixPaiement.especes,
            groupValue: _choix,
            onChanged: (v) => setState(() => _choix = v!),
            title: const Text('Payé en espèces'),
          ),
          RadioListTile<_ChoixPaiement>(
            contentPadding: EdgeInsets.zero,
            value: _ChoixPaiement.mobileMoney,
            groupValue: _choix,
            onChanged: (v) => setState(() => _choix = v!),
            title: const Text('Payé par Mobile Money'),
          ),
          RadioListTile<_ChoixPaiement>(
            contentPadding: EdgeInsets.zero,
            value: _ChoixPaiement.aEncaisser,
            groupValue: _choix,
            onChanged: (v) => setState(() => _choix = v!),
            title: const Text('À encaisser'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            final poids = double.tryParse(_controleurPoids.text.replaceAll(',', '.'));
            if (poids == null || poids <= 0) return;
            final resultat = _ResultatLivraison(
              poidsReel: poids,
              modePaiement: switch (_choix) {
                _ChoixPaiement.especes => ModePaiement.especes,
                _ChoixPaiement.mobileMoney => ModePaiement.mobileMoney,
                _ChoixPaiement.aEncaisser => null,
              },
              paye: _choix != _ChoixPaiement.aEncaisser,
            );
            Navigator.of(context).pop(resultat);
          },
          child: const Text('Confirmer'),
        ),
      ],
    );
  }
}
