import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/services_providers.dart';

/// Écran de saisie du code OTP reçu par SMS.
class OtpScreen extends ConsumerStatefulWidget {
  final String identifiantVerification;
  final String numeroTelephone;

  const OtpScreen({
    super.key,
    required this.identifiantVerification,
    required this.numeroTelephone,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controleurCode = TextEditingController();
  bool _validationEnCours = false;
  String? _erreur;

  @override
  void dispose() {
    _controleurCode.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    final code = _controleurCode.text.trim();
    if (code.length < 6) {
      setState(() => _erreur = 'Le code doit contenir 6 chiffres.');
      return;
    }

    setState(() {
      _validationEnCours = true;
      _erreur = null;
    });

    try {
      await ref.read(authServiceProvider).confirmerCodeOtp(
            identifiantVerification: widget.identifiantVerification,
            code: code,
          );
      // La connexion réussie déclenche AuthGate qui gère la suite.
    } on FirebaseAuthException catch (e) {
      setState(() {
        _erreur = e.code == 'invalid-verification-code'
            ? 'Code incorrect. Veuillez réessayer.'
            : (e.message ?? 'Une erreur est survenue.');
      });
    } finally {
      if (mounted) setState(() => _validationEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vérification')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entrez le code reçu par SMS au ${widget.numeroTelephone}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controleurCode,
                keyboardType: TextInputType.number,
                autofocus: true,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: const InputDecoration(counterText: '', hintText: '••••••'),
              ),
              if (_erreur != null) ...[
                const SizedBox(height: 8),
                Text(_erreur!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _validationEnCours ? null : _valider,
                child: _validationEnCours
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Valider'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
