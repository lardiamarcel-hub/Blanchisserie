import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';

/// Une entrée de l'historique des statuts d'une commande.
class HistoriqueStatut {
  final StatutCommande statut;
  final DateTime horodatage;

  const HistoriqueStatut({required this.statut, required this.horodatage});

  factory HistoriqueStatut.fromMap(Map<String, dynamic> data) {
    return HistoriqueStatut(
      statut: StatutCommandeX.depuisTexte(data['statut'] as String?),
      horodatage: (data['horodatage'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'statut': statut.valeur,
      'horodatage': Timestamp.fromDate(horodatage),
    };
  }
}

/// Représente un document de la collection `commandes`.
class CommandeModel {
  final String id;
  final String clientId;
  final String? collecteurId;
  final StatutCommande statut;
  final TypeService typeService;
  final CreneauHoraire creneauSouhaite;
  final double? poidsEstimeKg;
  final double? poidsReelKg;
  final double? prixEstime;
  final double? prixFinal;
  final ModePaiement? modePaiement;
  final bool paye;
  final String? note;
  final int? etoiles;
  final List<HistoriqueStatut> historiqueStatuts;
  final DateTime dateCreation;

  // Champs dénormalisés utiles à l'affichage côté collecteur/gérant sans
  // requête supplémentaire (évite une lecture Firestore par carte affichée).
  final String? clientNom;
  final String? clientTelephone;
  final String? clientAdresse;

  const CommandeModel({
    required this.id,
    required this.clientId,
    this.collecteurId,
    required this.statut,
    required this.typeService,
    required this.creneauSouhaite,
    this.poidsEstimeKg,
    this.poidsReelKg,
    this.prixEstime,
    this.prixFinal,
    this.modePaiement,
    this.paye = false,
    this.note,
    this.etoiles,
    this.historiqueStatuts = const [],
    required this.dateCreation,
    this.clientNom,
    this.clientTelephone,
    this.clientAdresse,
  });

  factory CommandeModel.fromMap(String id, Map<String, dynamic> data) {
    final historiqueRaw = data['historiqueStatuts'] as List<dynamic>? ?? [];
    return CommandeModel(
      id: id,
      clientId: data['clientId'] as String? ?? '',
      collecteurId: data['collecteurId'] as String?,
      statut: StatutCommandeX.depuisTexte(data['statut'] as String?),
      typeService: TypeServiceX.depuisTexte(data['typeService'] as String?),
      creneauSouhaite: CreneauHoraireX.depuisTexte(data['creneauSouhaite'] as String?),
      poidsEstimeKg: (data['poidsEstimeKg'] as num?)?.toDouble(),
      poidsReelKg: (data['poidsReelKg'] as num?)?.toDouble(),
      prixEstime: (data['prixEstime'] as num?)?.toDouble(),
      prixFinal: (data['prixFinal'] as num?)?.toDouble(),
      modePaiement: data['modePaiement'] != null
          ? ModePaiementX.depuisTexte(data['modePaiement'] as String?)
          : null,
      paye: data['paye'] as bool? ?? false,
      note: data['note'] as String?,
      etoiles: (data['etoiles'] as num?)?.toInt(),
      historiqueStatuts: historiqueRaw
          .map((e) => HistoriqueStatut.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      dateCreation: (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      clientNom: data['clientNom'] as String?,
      clientTelephone: data['clientTelephone'] as String?,
      clientAdresse: data['clientAdresse'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      if (collecteurId != null) 'collecteurId': collecteurId,
      'statut': statut.valeur,
      'typeService': typeService.valeur,
      'creneauSouhaite': creneauSouhaite.valeur,
      if (poidsEstimeKg != null) 'poidsEstimeKg': poidsEstimeKg,
      if (poidsReelKg != null) 'poidsReelKg': poidsReelKg,
      if (prixEstime != null) 'prixEstime': prixEstime,
      if (prixFinal != null) 'prixFinal': prixFinal,
      if (modePaiement != null) 'modePaiement': modePaiement!.valeur,
      'paye': paye,
      if (note != null) 'note': note,
      if (etoiles != null) 'etoiles': etoiles,
      'historiqueStatuts': historiqueStatuts.map((h) => h.toMap()).toList(),
      'dateCreation': Timestamp.fromDate(dateCreation),
      if (clientNom != null) 'clientNom': clientNom,
      if (clientTelephone != null) 'clientTelephone': clientTelephone,
      if (clientAdresse != null) 'clientAdresse': clientAdresse,
    };
  }
}
