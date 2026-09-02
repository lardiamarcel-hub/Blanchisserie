import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/services_providers.dart';
import 'otp_screen.dart';

/// Premier écran : saisie du numéro de téléphone pour recevoir un code OTP.
class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _controleurTelephone = TextEditingController();
  bool _envoiEnCours = false;
  String? _erreur;

  @override
  void dispose() {
    _controleurTelephone.dispose();
    super.dispose();
  }

  String? _normaliserNumero(String saisie) {
    final nettoye = saisie.trim().replaceAll(' ', '');
    if (nettoye.isEmpty) return null;
    // Le Burkina Faso utilise l'indicatif +226 ; on l'ajoute si l'utilisateur
    // a saisi seulement les 8 chiffres locaux.
    if (nettoye.startsWith('+')) return nettoye;
    if (nettoye.length == 8) return '+226$nettoye';
    return '+$nettoye';
  }

  Future<void> _envoyerCode() async {
    final numero = _normaliserNumero(_controleurTelephone.text);
    if (numero == null) {
      setState(() => _erreur = 'Veuillez saisir un numéro de téléphone valide.');
      return;
    }

    setState(() {
      _envoiEnCours = true;
      _erreur = null;
    });

    final authService = ref.read(authServiceProvider);
    await authService.demarrerVerificationTelephone(
      numeroTelephone: numero,
      surCodeEnvoye: (identifiantVerification) {
        if (!mounted) return;
        setState(() => _envoiEnCours = false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              identifiantVerification: identifiantVerification,
              numeroTelephone: numero,
            ),
          ),
        );
      },
      surEchec: (FirebaseAuthException e) {
        if (!mounted) return;
        setState(() {
          _envoiEnCours = false;
          _erreur = e.message ?? "Impossible d'envoyer le code. Vérifiez le numéro.";
        });
      },
      surValidationAutomatique: () {
        if (!mounted) return;
        setState(() => _envoiEnCours = false);
        // La connexion se termine automatiquement ; AuthGate prendra le relais.
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_laundry_service_rounded,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text('Bienvenue', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text(
                'Connectez-vous avec votre numéro de téléphone pour '
                'demander une collecte de linge.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _controleurTelephone,
                keyboardType: TextInputType.phone,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Numéro de téléphone',
                  hintText: '70 00 00 00',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              if (_erreur != null) ...[
                const SizedBox(height: 12),
                Text(_erreur!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _envoiEnCours ? null : _envoyerCode,
                child: _envoiEnCours
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Recevoir le code par SMS'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
