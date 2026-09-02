import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/commande_model.dart';
import '../../models/user_model.dart';
import '../../providers/services_providers.dart';
import '../../providers/tarif_providers.dart';

/// Création d'une demande de collecte : type de service, créneau, note
/// libre optionnelle. Le poids (et donc le prix exact) sera renseigné par
/// le collecteur au moment de la collecte.
class CreerCommandeScreen extends ConsumerStatefulWidget {
  final UserModel utilisateur;

  const CreerCommandeScreen({super.key, required this.utilisateur});

  @override
  ConsumerState<CreerCommandeScreen> createState() => _CreerCommandeScreenState();
}

class _CreerCommandeScreenState extends ConsumerState<CreerCommandeScreen> {
  TypeService _typeService = TypeService.standard;
  CreneauHoraire _creneau = CreneauHoraire.matin;
  final _controleurNote = TextEditingController();
  bool _envoiEnCours = false;

  @override
  void dispose() {
    _controleurNote.dispose();
    super.dispose();
  }

  Future<void> _envoyerDemande() async {
    setState(() => _envoiEnCours = true);

    final maintenant = DateTime.now();
    final commande = CommandeModel(
      id: '',
      clientId: widget.utilisateur.uid,
      statut: StatutCommande.demandeCreee,
      typeService: _typeService,
      creneauSouhaite: _creneau,
      note: _controleurNote.text.trim().isEmpty ? null : _controleurNote.text.trim(),
      historiqueStatuts: [
        HistoriqueStatut(statut: StatutCommande.demandeCreee, horodatage: maintenant),
      ],
      dateCreation: maintenant,
      clientNom: widget.utilisateur.nom,
      clientTelephone: widget.utilisateur.telephone,
      clientAdresse: widget.utilisateur.adresseAffichee,
    );

    await ref.read(firestoreServiceProvider).creerCommande(commande);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande envoyée ! Nous vous contactons bientôt.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tarifsAsync = ref.watch(tarifsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle collecte')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Type de service', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            tarifsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Erreur tarifs : $e'),
              data: (tarifs) {
                return Column(
                  children: TypeService.values.map((type) {
                    final tarif = tarifs.where((t) => t.typeService == type).toList();
                    final prixParKg = tarif.isNotEmpty ? tarif.first.prixParKg : null;
                    return Card(
                      child: RadioListTile<TypeService>(
                        value: type,
                        groupValue: _typeService,
                        onChanged: (v) => setState(() => _typeService = v!),
                        title: Text(type.libelle),
                        subtitle: prixParKg != null
                            ? Text('${formaterPrix(prixParKg)} / kg')
                            : null,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            Text('Créneau souhaité', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Column(
              children: CreneauHoraire.values.map((creneau) {
                return Card(
                  child: RadioListTile<CreneauHoraire>(
                    value: creneau,
                    groupValue: _creneau,
                    onChanged: (v) => setState(() => _creneau = v!),
                    title: Text(creneau.libelle),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text('Note (facultatif)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _controleurNote,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Ex : 2 sacs, dont un de draps',
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _envoiEnCours ? null : _envoyerDemande,
              child: _envoiEnCours
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Envoyer la demande'),
            ),
          ],
        ),
      ),
    );
  }
}
