import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Écran affiché pendant la résolution de l'état de connexion / du profil.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.bleuPrincipal,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_laundry_service_rounded, color: Colors.white, size: 64),
            SizedBox(height: 16),
            Text(
              'Blanchisserie',
              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
