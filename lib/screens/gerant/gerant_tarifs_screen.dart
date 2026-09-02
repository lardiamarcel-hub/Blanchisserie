import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/tarif_model.dart';
import '../../providers/services_providers.dart';
import '../../providers/tarif_providers.dart';

/// Grille tarifaire éditable par le gérant (prix au kg par type de
/// service). Initialise des tarifs par défaut au premier lancement.
class GerantTarifsScreen extends ConsumerStatefulWidget {
  const GerantTarifsScreen({super.key});

  @override
  ConsumerState<GerantTarifsScreen> createState() => _GerantTarifsScreenState();
}

class _GerantTarifsScreenState extends ConsumerState<GerantTarifsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(firestoreServiceProvider).initialiserTarifsParDefautSiVide(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tarifsAsync = ref.watch(tarifsProvider);

    return tarifsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur : $e')),
      data: (tarifs) {
        if (tarifs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tarifs.length,
          itemBuilder: (context, index) => _CarteTarif(tarif: tarifs[index]),
        );
      },
    );
  }
}

class _CarteTarif extends ConsumerStatefulWidget {
  final TarifModel tarif;

  const _CarteTarif({required this.tarif});

  @override
  ConsumerState<_CarteTarif> createState() => _CarteTarifState();
}

class _CarteTarifState extends ConsumerState<_CarteTarif> {
  late final TextEditingController _controleurPrix;
  bool _enregistrementEnCours = false;

  @override
  void initState() {
    super.initState();
    _controleurPrix = TextEditingController(text: widget.tarif.prixParKg.toStringAsFixed(0));
  }

  @override
  void didUpdateWidget(covariant _CarteTarif oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tarif.prixParKg != widget.tarif.prixParKg) {
      _controleurPrix.text = widget.tarif.prixParKg.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _controleurPrix.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    final nouveauPrix = double.tryParse(_controleurPrix.text.replaceAll(',', '.'));
    if (nouveauPrix == null || nouveauPrix <= 0) return;

    setState(() => _enregistrementEnCours = true);
    await ref.read(firestoreServiceProvider).enregistrerTarif(
          TarifModel(
            typeService: widget.tarif.typeService,
            prixParKg: nouveauPrix,
            description: widget.tarif.description,
          ),
        );
    if (mounted) {
      setState(() => _enregistrementEnCours = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.tarif.typeService.libelle} mis à jour')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.tarif.typeService.libelle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controleurPrix,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Prix par kg', suffixText: 'FCFA'),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _enregistrementEnCours ? null : _enregistrer,
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
