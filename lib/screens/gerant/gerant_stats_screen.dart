import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/commande_providers.dart';

/// Indicateurs simples calculés côté client à partir des commandes
/// récentes : suffisant pour le volume d'une V1 (un immeuble + quartier).
class GerantStatsScreen extends ConsumerWidget {
  const GerantStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commandesAsync = ref.watch(toutesCommandesProvider(null));

    return commandesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur : $e')),
      data: (commandes) {
        final maintenant = DateTime.now();
        final debutJour = DateTime(maintenant.year, maintenant.month, maintenant.day);
        final debutSemaine = debutJour.subtract(Duration(days: debutJour.weekday - 1));
        final debutMois = DateTime(maintenant.year, maintenant.month);

        final duJour = commandes.where((c) => c.dateCreation.isAfter(debutJour)).length;
        final delaSemaine = commandes.where((c) => c.dateCreation.isAfter(debutSemaine)).length;
        final duMois = commandes.where((c) => c.dateCreation.isAfter(debutMois)).length;

        final livreesDuMois = commandes.where(
          (c) => c.statut == StatutCommande.livree && c.dateCreation.isAfter(debutMois),
        );
        final kgTraites = livreesDuMois.fold<double>(0, (s, c) => s + (c.poidsReelKg ?? 0));
        final caEstime = livreesDuMois.fold<double>(0, (s, c) => s + (c.prixFinal ?? c.prixEstime ?? 0));

        final aEncaisser = commandes.where(
          (c) => c.statut == StatutCommande.livree && !c.paye,
        ).length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _CarteIndicateur(titre: "Commandes aujourd'hui", valeur: '$duJour'),
                _CarteIndicateur(titre: 'Cette semaine', valeur: '$delaSemaine'),
                _CarteIndicateur(titre: 'Ce mois-ci', valeur: '$duMois'),
                _CarteIndicateur(
                  titre: 'À encaisser',
                  valeur: '$aEncaisser',
                  couleur: aEncaisser > 0 ? AppTheme.orangeAlerte : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ce mois-ci', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kg traités'),
                        Text(formaterPoids(kgTraites), style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Chiffre d'affaires estimé"),
                        Text(
                          formaterPrix(caEstime),
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.vertSucces),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CarteIndicateur extends StatelessWidget {
  final String titre;
  final String valeur;
  final Color? couleur;

  const _CarteIndicateur({required this.titre, required this.valeur, this.couleur});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              valeur,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: couleur ?? AppTheme.bleuPrincipal,
              ),
            ),
            const SizedBox(height: 4),
            Text(titre, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
