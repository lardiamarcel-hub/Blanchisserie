import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';

/// Petit badge coloré affichant le libellé français d'un [StatutCommande].
class StatusBadge extends StatelessWidget {
  final StatutCommande statut;

  const StatusBadge({super.key, required this.statut});

  Color get _couleur {
    switch (statut) {
      case StatutCommande.demandeCreee:
      case StatutCommande.collectePlanifiee:
        return AppTheme.orangeAlerte;
      case StatutCommande.collecteEffectuee:
      case StatutCommande.enTraitement:
      case StatutCommande.pret:
      case StatutCommande.enLivraison:
        return AppTheme.bleuPrincipal;
      case StatutCommande.livree:
        return AppTheme.vertSucces;
      case StatutCommande.annulee:
        return AppTheme.rougeErreur;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _couleur.withValues(alpha: 0.4)),
      ),
      child: Text(
        statut.libelle,
        style: TextStyle(color: _couleur, fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}
