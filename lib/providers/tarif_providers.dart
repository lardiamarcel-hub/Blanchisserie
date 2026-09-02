import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tarif_model.dart';
import '../models/user_model.dart';
import 'services_providers.dart';

final tarifsProvider = StreamProvider<List<TarifModel>>((ref) {
  return ref.watch(firestoreServiceProvider).streamTarifs();
});

final collecteursProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(firestoreServiceProvider).streamCollecteurs();
});
