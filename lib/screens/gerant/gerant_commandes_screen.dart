import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/commande_providers.dart';
import '../../widgets/commande_card.dart';

/// Vue d'ensemble des commandes pour le gérant, avec filtre par statut.
class GerantCommandesScreen extends ConsumerStatefulWidget {
  const GerantCommandesScreen({super.key});

  @override
  ConsumerState<GerantCommandesScreen> createState() => _GerantCommandesScreenState();
}

class _GerantCommandesScreenState extends ConsumerState<GerantCommandesScreen> {
  StatutCommande? _filtre;

  @override
  Widget build(BuildContext context) {
    final commandesAsync = ref.watch(toutesCommandesProvider(_filtre));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _PucheFiltre(
                    label: 'Toutes',
                    selectionne: _filtre == null,
                    onTap: () => setState(() => _filtre = null),
                  ),
                  ...StatutCommande.values.map(
                    (s) => _PucheFiltre(
                      label: s.libelle,
                      selectionne: _filtre == s,
                      onTap: () => setState(() => _filtre = s),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: commandesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur : $e')),
            data: (commandes) {
              if (commandes.isEmpty) {
                return const Center(child: Text('Aucune commande.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: commandes.length,
                itemBuilder: (context, index) => CommandeCard(
                  commande: commandes[index],
                  afficherClient: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PucheFiltre extends StatelessWidget {
  final String label;
  final bool selectionne;
  final VoidCallback onTap;

  const _PucheFiltre({required this.label, required this.selectionne, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selectionne,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
