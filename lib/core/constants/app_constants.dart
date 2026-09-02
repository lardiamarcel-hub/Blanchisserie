/// Rôle d'un utilisateur de l'application.
enum RoleUtilisateur { client, collecteur, gerant }

extension RoleUtilisateurX on RoleUtilisateur {
  String get valeur => name;

  static RoleUtilisateur depuisTexte(String? texte) {
    return RoleUtilisateur.values.firstWhere(
      (r) => r.name == texte,
      orElse: () => RoleUtilisateur.client,
    );
  }
}

/// Statuts possibles d'une commande, dans l'ordre du cycle de vie normal.
enum StatutCommande {
  demandeCreee,
  collectePlanifiee,
  collecteEffectuee,
  enTraitement,
  pret,
  enLivraison,
  livree,
  annulee,
}

extension StatutCommandeX on StatutCommande {
  String get valeur => name;

  static StatutCommande depuisTexte(String? texte) {
    return StatutCommande.values.firstWhere(
      (s) => s.name == texte,
      orElse: () => StatutCommande.demandeCreee,
    );
  }

  /// Libellé affiché en français pour ce statut.
  String get libelle {
    switch (this) {
      case StatutCommande.demandeCreee:
        return 'Demande envoyée';
      case StatutCommande.collectePlanifiee:
        return 'Collecte planifiée';
      case StatutCommande.collecteEffectuee:
        return 'Linge collecté';
      case StatutCommande.enTraitement:
        return 'En traitement';
      case StatutCommande.pret:
        return 'Prêt';
      case StatutCommande.enLivraison:
        return 'En livraison';
      case StatutCommande.livree:
        return 'Livré';
      case StatutCommande.annulee:
        return 'Annulée';
    }
  }

  bool get estActive => this != StatutCommande.livree && this != StatutCommande.annulee;

  /// Étape suivante logique dans le cycle de vie (null si terminal).
  StatutCommande? get suivant {
    switch (this) {
      case StatutCommande.demandeCreee:
        return StatutCommande.collectePlanifiee;
      case StatutCommande.collectePlanifiee:
        return StatutCommande.collecteEffectuee;
      case StatutCommande.collecteEffectuee:
        return StatutCommande.enTraitement;
      case StatutCommande.enTraitement:
        return StatutCommande.pret;
      case StatutCommande.pret:
        return StatutCommande.enLivraison;
      case StatutCommande.enLivraison:
        return StatutCommande.livree;
      case StatutCommande.livree:
      case StatutCommande.annulee:
        return null;
    }
  }
}

/// Type de service demandé pour une commande.
enum TypeService { standard, express24h, pressingPiece }

extension TypeServiceX on TypeService {
  String get valeur => name;

  static TypeService depuisTexte(String? texte) {
    return TypeService.values.firstWhere(
      (t) => t.name == texte,
      orElse: () => TypeService.standard,
    );
  }

  String get libelle {
    switch (this) {
      case TypeService.standard:
        return 'Lavage + repassage standard';
      case TypeService.express24h:
        return 'Express 24h';
      case TypeService.pressingPiece:
        return 'Pressing à la pièce';
    }
  }
}

/// Créneau horaire souhaité pour la collecte.
enum CreneauHoraire { matin, apresMidi, soir }

extension CreneauHoraireX on CreneauHoraire {
  String get valeur => name;

  static CreneauHoraire depuisTexte(String? texte) {
    return CreneauHoraire.values.firstWhere(
      (c) => c.name == texte,
      orElse: () => CreneauHoraire.matin,
    );
  }

  String get libelle {
    switch (this) {
      case CreneauHoraire.matin:
        return 'Matin (7h - 12h)';
      case CreneauHoraire.apresMidi:
        return 'Après-midi (12h - 17h)';
      case CreneauHoraire.soir:
        return 'Soir (17h - 20h)';
    }
  }
}

/// Mode de paiement déclaré par le collecteur à la livraison.
enum ModePaiement { especes, mobileMoney }

extension ModePaiementX on ModePaiement {
  String get valeur => name;

  static ModePaiement depuisTexte(String? texte) {
    return ModePaiement.values.firstWhere(
      (m) => m.name == texte,
      orElse: () => ModePaiement.especes,
    );
  }

  String get libelle {
    switch (this) {
      case ModePaiement.especes:
        return 'Espèces';
      case ModePaiement.mobileMoney:
        return 'Mobile Money';
    }
  }
}

/// Noms des collections Firestore, centralisés pour éviter les fautes de frappe.
class FirestoreCollections {
  static const String users = 'users';
  static const String commandes = 'commandes';
  static const String tarifs = 'tarifs';
}
