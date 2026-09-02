import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';

/// Représente un document de la collection `users`.
class UserModel {
  final String uid;
  final String telephone;
  final RoleUtilisateur role;
  final String nom;

  /// Adresse libre (pour les clients hors immeuble).
  final String? adresse;

  /// Étage dans l'immeuble (pour les résidents).
  final String? etage;

  /// Numéro d'appartement dans l'immeuble (pour les résidents).
  final String? appartement;

  final String? tokenNotification;
  final DateTime? dateCreation;

  const UserModel({
    required this.uid,
    required this.telephone,
    required this.role,
    required this.nom,
    this.adresse,
    this.etage,
    this.appartement,
    this.tokenNotification,
    this.dateCreation,
  });

  /// Adresse complète prête à afficher, qu'il s'agisse d'un résident de
  /// l'immeuble ou d'un client du quartier.
  String get adresseAffichee {
    if (etage != null && etage!.isNotEmpty) {
      final appart = (appartement != null && appartement!.isNotEmpty)
          ? ', Appt $appartement'
          : '';
      return 'Étage $etage$appart';
    }
    return adresse?.isNotEmpty == true ? adresse! : 'Adresse non renseignée';
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      telephone: data['telephone'] as String? ?? '',
      role: RoleUtilisateurX.depuisTexte(data['role'] as String?),
      nom: data['nom'] as String? ?? '',
      adresse: data['adresse'] as String?,
      etage: data['etage'] as String?,
      appartement: data['appartement'] as String?,
      tokenNotification: data['tokenNotification'] as String?,
      dateCreation: (data['dateCreation'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'telephone': telephone,
      'role': role.valeur,
      'nom': nom,
      if (adresse != null) 'adresse': adresse,
      if (etage != null) 'etage': etage,
      if (appartement != null) 'appartement': appartement,
      if (tokenNotification != null) 'tokenNotification': tokenNotification,
      'dateCreation': dateCreation != null
          ? Timestamp.fromDate(dateCreation!)
          : FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? nom,
    String? adresse,
    String? etage,
    String? appartement,
    String? tokenNotification,
  }) {
    return UserModel(
      uid: uid,
      telephone: telephone,
      role: role,
      nom: nom ?? this.nom,
      adresse: adresse ?? this.adresse,
      etage: etage ?? this.etage,
      appartement: appartement ?? this.appartement,
      tokenNotification: tokenNotification ?? this.tokenNotification,
      dateCreation: dateCreation,
    );
  }

  /// Vrai si le profil contient assez d'informations pour passer commande.
  bool get profilComplet {
    if (nom.isEmpty) return false;
    final aAdresseImmeuble = etage != null && etage!.isNotEmpty;
    final aAdresseLibre = adresse != null && adresse!.isNotEmpty;
    return aAdresseImmeuble || aAdresseLibre;
  }
}
