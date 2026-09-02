import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/commande_model.dart';
import '../../providers/services_providers.dart';

/// Détail d'une commande côté client : timeline de statuts + notation
/// possible une fois la commande livrée.
class CommandeDetailScreen extends ConsumerWidget {
  final CommandeModel commande;

  const CommandeDetailScreen({super.key, required this.commande});

  static const _etapesPrincipales = [
    StatutCommande.demandeCreee,
    StatutCommande.collectePlanifiee,
    StatutCommande.collecteEffectuee,
    StatutCommande.enTraitement,
    StatutCommande.pret,
    StatutCommande.enLivraison,
    StatutCommande.livree,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estAnnulee = commande.statut == StatutCommande.annulee;
    final indexActuel = _etapesPrincipales.indexOf(commande.statut);

    return Scaffold(
      appBar: AppBar(title: const Text('Détail de la commande')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(commande.typeService.libelle, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text('Créneau : ${commande.creneauSouhaite.libelle}'),
                  Text('Demandée le ${formaterDateHeure(commande.dateCreation)}'),
                  if (commande.note != null) ...[
                    const SizedBox(height: 6),
                    Text('Note : ${commande.note}'),
                  ],
                  if (commande.poidsReelKg != null) ...[
                    const SizedBox(height: 6),
                    Text('Poids : ${formaterPoids(commande.poidsReelKg)}'),
                  ],
                  if (commande.prixFinal != null || commande.prixEstime != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Prix ${commande.prixFinal != null ? "final" : "estimé"} : '
                      '${formaterPrix(commande.prixFinal ?? commande.prixEstime)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (estAnnulee)
            const Card(
              color: Color(0xFFFCEBEB),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Cette commande a été annulée.', style: TextStyle(color: AppTheme.rougeErreur)),
              ),
            )
          else ...[
            Text('Suivi de la commande', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ..._etapesPrincipales.asMap().entries.map((entry) {
              final index = entry.key;
              final etape = entry.value;
              final atteinte = indexActuel >= 0 && index <= indexActuel;
              return _LigneEtape(
                libelle: etape.libelle,
                atteinte: atteinte,
                estDerniere: index == _etapesPrincipales.length - 1,
              );
            }),
          ],
          if (commande.statut == StatutCommande.livree && commande.etoiles == null) ...[
            const SizedBox(height: 24),
            _NotationCommande(commande: commande),
          ],
          if (commande.etoiles != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Votre note : '),
                ...List.generate(
                  5,
                  (i) => Icon(
                    i < commande.etoiles! ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LigneEtape extends StatelessWidget {
  final String libelle;
  final bool atteinte;
  final bool estDerniere;

  const _LigneEtape({required this.libelle, required this.atteinte, required this.estDerniere});

  @override
  Widget build(BuildContext context) {
    final couleur = atteinte ? AppTheme.vertSucces : Colors.black26;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(atteinte ? Icons.check_circle : Icons.circle_outlined, color: couleur, size: 22),
            if (!estDerniere) Container(width: 2, height: 32, color: couleur),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            libelle,
            style: TextStyle(
              color: atteinte ? Colors.black87 : Colors.black45,
              fontWeight: atteinte ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

class _NotationCommande extends ConsumerStatefulWidget {
  final CommandeModel commande;

  const _NotationCommande({required this.commande});

  @override
  ConsumerState<_NotationCommande> createState() => _NotationCommandeState();
}

class _NotationCommandeState extends ConsumerState<_NotationCommande> {
  int _etoilesChoisies = 0;
  bool _envoiEnCours = false;

  Future<void> _envoyerNote() async {
    if (_etoilesChoisies == 0) return;
    setState(() => _envoiEnCours = true);
    await ref.read(firestoreServiceProvider).noterCommande(widget.commande.id, _etoilesChoisies);
    if (mounted) setState(() => _envoiEnCours = false);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comment était le service ?', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) {
                return IconButton(
                  icon: Icon(
                    i < _etoilesChoisies ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () => setState(() => _etoilesChoisies = i + 1),
                );
              }),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: (_etoilesChoisies == 0 || _envoiEnCours) ? null : _envoyerNote,
              child: const Text('Envoyer ma note'),
            ),
          ],
        ),
      ),
    );
  }
}
