import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/services_providers.dart';
import 'gerant_collecteurs_screen.dart';
import 'gerant_commandes_screen.dart';
import 'gerant_stats_screen.dart';
import 'gerant_tarifs_screen.dart';

/// Écran racine du gérant : indicateurs, commandes, tarifs et collecteurs
/// accessibles via une barre de navigation basse.
class GerantDashboardScreen extends ConsumerStatefulWidget {
  const GerantDashboardScreen({super.key});

  @override
  ConsumerState<GerantDashboardScreen> createState() => _GerantDashboardScreenState();
}

class _GerantDashboardScreenState extends ConsumerState<GerantDashboardScreen> {
  int _ongletActif = 0;

  static const _titres = ['Indicateurs', 'Commandes', 'Tarifs', 'Collecteurs'];

  static const _ecrans = [
    GerantStatsScreen(),
    GerantCommandesScreen(),
    GerantTarifsScreen(),
    GerantCollecteursScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titres[_ongletActif]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () => ref.read(authServiceProvider).deconnexion(),
          ),
        ],
      ),
      body: IndexedStack(index: _ongletActif, children: _ecrans),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _ongletActif,
        onDestinationSelected: (i) => setState(() => _ongletActif = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Indicateurs'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Commandes'),
          NavigationDestination(icon: Icon(Icons.sell_outlined), label: 'Tarifs'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Collecteurs'),
        ],
      ),
    );
  }
}
