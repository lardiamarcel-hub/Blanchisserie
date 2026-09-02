import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/services_providers.dart';
import '../../providers/tarif_providers.dart';

/// Le gérant crée ici les comptes collecteurs (nom + téléphone). Il n'y a
/// pas d'auto-inscription : la personne se connecte ensuite simplement par
/// OTP SMS avec ce numéro, et le rôle collecteur est appliqué automatiquement.
class GerantCollecteursScreen extends ConsumerStatefulWidget {
  const GerantCollecteursScreen({super.key});

  @override
  ConsumerState<GerantCollecteursScreen> createState() => _GerantCollecteursScreenState();
}

class _GerantCollecteursScreenState extends ConsumerState<GerantCollecteursScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controleurNom = TextEditingController();
  final _controleurTelephone = TextEditingController();
  bool _enregistrementEnCours = false;

  @override
  void dispose() {
    _controleurNom.dispose();
    _controleurTelephone.dispose();
    super.dispose();
  }

  String? _normaliserNumero(String saisie) {
    final nettoye = saisie.trim().replaceAll(' ', '');
    if (nettoye.isEmpty) return null;
    if (nettoye.startsWith('+')) return nettoye;
    if (nettoye.length == 8) return '+226$nettoye';
    return '+$nettoye';
  }

  Future<void> _creerCompte() async {
    if (!_formKey.currentState!.validate()) return;
    final numero = _normaliserNumero(_controleurTelephone.text);
    if (numero == null) return;

    setState(() => _enregistrementEnCours = true);
    await ref.read(firestoreServiceProvider).creerCompteCollecteur(
          telephone: numero,
          nom: _controleurNom.text.trim(),
        );

    if (mounted) {
      setState(() => _enregistrementEnCours = false);
      _controleurNom.clear();
      _controleurTelephone.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compte collecteur créé. La personne peut se connecter.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final collecteursAsync = ref.watch(collecteursProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nouveau collecteur', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _controleurNom,
                    decoration: const InputDecoration(labelText: 'Nom complet'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _controleurTelephone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de téléphone',
                      hintText: '70 00 00 00',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _enregistrementEnCours ? null : _creerCompte,
                    child: _enregistrementEnCours
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Créer le compte'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Collecteurs actifs', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        collecteursAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Erreur : $e'),
          data: (collecteurs) {
            if (collecteurs.isEmpty) {
              return const Text('Aucun collecteur pour le moment.', style: TextStyle(color: Colors.black54));
            }
            return Column(
              children: collecteurs
                  .map(
                    (c) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(c.nom),
                        subtitle: Text(c.telephone),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
