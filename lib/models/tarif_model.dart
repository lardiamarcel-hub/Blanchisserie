import '../core/constants/app_constants.dart';

/// Représente un document de la collection `tarifs`.
/// L'identifiant du document est directement la valeur de [TypeService].
class TarifModel {
  final TypeService typeService;
  final double prixParKg;
  final String description;

  const TarifModel({
    required this.typeService,
    required this.prixParKg,
    required this.description,
  });

  factory TarifModel.fromMap(String id, Map<String, dynamic> data) {
    return TarifModel(
      typeService: TypeServiceX.depuisTexte(data['typeService'] as String? ?? id),
      prixParKg: (data['prixParKg'] as num?)?.toDouble() ?? 0,
      description: data['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'typeService': typeService.valeur,
      'prixParKg': prixParKg,
      'description': description,
    };
  }
}
