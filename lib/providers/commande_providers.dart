import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../models/commande_model.dart';
import 'services_providers.dart';

final commandesClientProvider =
    StreamProvider.family<List<CommandeModel>, String>((ref, clientId) {
  return ref.watch(firestoreServiceProvider).streamCommandesClient(clientId);
});

final commandesACollecterProvider = StreamProvider<List<CommandeModel>>((ref) {
  return ref.watch(firestoreServiceProvider).streamCommandesACollecter();
});

final commandesALivrerProvider = StreamProvider<List<CommandeModel>>((ref) {
  return ref.watch(firestoreServiceProvider).streamCommandesALivrer();
});

final toutesCommandesProvider =
    StreamProvider.family<List<CommandeModel>, StatutCommande?>((ref, filtreStatut) {
  return ref.watch(firestoreServiceProvider).streamToutesCommandes(filtreStatut: filtreStatut);
});
