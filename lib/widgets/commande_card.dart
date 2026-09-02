import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../models/commande_model.dart';
import 'status_badge.dart';

/// Carte compacte résumant une commande, utilisée dans les listes client,
/// collecteur et gérant.
class CommandeCard extends StatelessWidget {
  final CommandeModel commande;
  final VoidCallback? onTap;
  final Widget? actions;
  final bool afficherClient;

  const CommandeCard({
    super.key,
    required this.commande,
    this.onTap,
    this.actions,
    this.afficherClient = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      commande.typeService.libelle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  StatusBadge(statut: commande.statut),
                ],
              ),
              const SizedBox(height: 6),
              if (afficherClient && commande.clientNom != null) ...[
                Text('${commande.clientNom} · ${commande.clientTelephone ?? ''}'),
                if (commande.clientAdresse != null) Text(commande.clientAdresse!),
                const SizedBox(height: 4),
              ],
              Text(
                'Créneau : ${commande.creneauSouhaite.libelle}',
                style: const TextStyle(color: Colors.black54),
              ),
              Text(
                formaterDateHeure(commande.dateCreation),
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              if (commande.note != null && commande.note!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Note : ${commande.note}', style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
              if (commande.prixEstime != null || commande.prixFinal != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Prix ${commande.prixFinal != null ? "final" : "estimé"} : '
                  '${formaterPrix(commande.prixFinal ?? commande.prixEstime)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
              if (actions != null) ...[
                const SizedBox(height: 10),
                actions!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
