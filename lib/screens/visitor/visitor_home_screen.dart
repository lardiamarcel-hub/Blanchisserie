import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/tarif_providers.dart';
import '../auth/phone_login_screen.dart';

/// Écran d'accueil public : consultable sans connexion. Présente les
/// services proposés ; la connexion n'est demandée qu'au moment de
/// passer réellement une commande.
class VisitorHomeScreen extends ConsumerWidget {
  const VisitorHomeScreen({super.key});

  void _allerALaConnexion(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tarifsAsync = ref.watch(tarifsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blanchisserie'),
        actions: [
          TextButton(
            onPressed: () => _allerALaConnexion(context),
            child: const Text('Se connecter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(Icons.local_laundry_service_rounded, size: 56, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            'Votre linge, collecté et livré chez vous',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            "Service de blanchisserie pour l'immeuble et le quartier, à Ouagadougou.",
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 28),
          Text('Comment ça marche', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          const _EtapeExplication(
            numero: '1',
            titre: 'Vous demandez une collecte',
            description: 'Choisissez un créneau et le type de service, en quelques instants.',
          ),
          const _EtapeExplication(
            numero: '2',
            titre: 'On collecte votre linge',
            description: 'Un collecteur passe chez vous à l\'heure convenue.',
          ),
          const _EtapeExplication(
            numero: '3',
            titre: 'On vous livre, propre et repassé',
            description: 'Vous êtes prévenu à chaque étape, jusqu\'à la livraison.',
          ),
          const SizedBox(height: 28),
          Text('Nos services', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          tarifsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const Text(
              'Grille tarifaire indisponible pour le moment.',
              style: TextStyle(color: Colors.black54),
            ),
            data: (tarifs) {
              if (tarifs.isEmpty) {
                return const Text(
                  'Grille tarifaire bientôt disponible.',
                  style: TextStyle(color: Colors.black54),
                );
              }
              return Column(
                children: tarifs.map((tarif) {
                  return Card(
                    child: ListTile(
                      title: Text(tarif.typeService.libelle),
                      subtitle: Text(tarif.description),
                      trailing: Text(
                        '${formaterPrix(tarif.prixParKg)} / kg',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Demander une collecte'),
            onPressed: () => _allerALaConnexion(context),
          ),
          const SizedBox(height: 8),
          const Text(
            'La connexion se fait par numéro de téléphone (code reçu par SMS), '
            'uniquement au moment de commander.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black45, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _EtapeExplication extends StatelessWidget {
  final String numero;
  final String titre;
  final String description;

  const _EtapeExplication({required this.numero, required this.titre, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.bleuPrincipal,
            child: Text(numero, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(description, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
