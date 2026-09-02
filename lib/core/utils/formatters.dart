import 'package:intl/intl.dart';

/// Formatte un montant en francs CFA, sans décimales (ex: "3 250 FCFA").
String formaterPrix(num? montant) {
  if (montant == null) return '—';
  final formateur = NumberFormat.decimalPattern('fr_FR');
  return '${formateur.format(montant.round())} FCFA';
}

String formaterDateHeure(DateTime date) {
  return DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(date);
}

String formaterDate(DateTime date) {
  return DateFormat('dd/MM/yyyy', 'fr_FR').format(date);
}

String formaterPoids(num? kg) {
  if (kg == null) return '—';
  return '${kg.toStringAsFixed(1)} kg';
}
