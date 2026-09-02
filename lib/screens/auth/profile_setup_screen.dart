import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../../providers/services_providers.dart';

/// Complète le profil client après la première connexion : nom, et
/// adresse (soit dans l'immeuble via étage/appartement, soit adresse libre
/// pour un client du quartier).
class ProfileSetupScreen extends ConsumerStatefulWidget {
  final UserModel utilisateur;

  const ProfileSetupScreen({super.key, required this.utilisateur});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controleurNom = TextEditingController();
  final _controleurEtage = TextEditingController();
  final _controleurAppartement = TextEditingController();
  final _controleurAdresse = TextEditingController();

  bool _resideDansImmeuble = true;
  bool _enregistrementEnCours = false;

  @override
  void dispose() {
    _controleurNom.dispose();
    _controleurEtage.dispose();
    _controleurAppartement.dispose();
    _controleurAdresse.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enregistrementEnCours = true);

    final utilisateurMisAJour = widget.utilisateur.copyWith(
      nom: _controleurNom.text.trim(),
      etage: _resideDansImmeuble ? _controleurEtage.text.trim() : '',
      appartement: _resideDansImmeuble ? _controleurAppartement.text.trim() : '',
      adresse: _resideDansImmeuble ? '' : _controleurAdresse.text.trim(),
    );

    await ref.read(firestoreServiceProvider).mettreAJourProfil(utilisateurMisAJour);

    if (mounted) setState(() => _enregistrementEnCours = false);
    // AuthGate détecte le profil complet via le stream et bascule seul.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Votre profil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Encore une étape avant de commander',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _controleurNom,
                  decoration: const InputDecoration(labelText: 'Nom complet'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 20),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text("J'habite l'immeuble")),
                    ButtonSegment(value: false, label: Text('Autre adresse')),
                  ],
                  selected: {_resideDansImmeuble},
                  onSelectionChanged: (s) => setState(() => _resideDansImmeuble = s.first),
                ),
                const SizedBox(height: 20),
                if (_resideDansImmeuble) ...[
                  TextFormField(
                    controller: _controleurEtage,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Étage'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _controleurAppartement,
                    decoration: const InputDecoration(labelText: "Numéro d'appartement"),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                  ),
                ] else
                  TextFormField(
                    controller: _controleurAdresse,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Adresse',
                      hintText: 'Quartier, secteur, repère...',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                  ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _enregistrementEnCours ? null : _enregistrer,
                  child: _enregistrementEnCours
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Continuer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
