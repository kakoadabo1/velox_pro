import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/velox_theme.dart';
import '../common/pro_common.dart';

class LivreurShell extends StatefulWidget {
  const LivreurShell({super.key});

  @override
  State<LivreurShell> createState() => _LivreurShellState();
}

class _LivreurShellState extends State<LivreurShell> {
  int _tab = 0;
  bool _online = false; // statut conservé entre les onglets

  void _setOnline(bool v) => setState(() => _online = v);

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    final pages = [
      _LivreurHome(online: _online, onToggle: () => _setOnline(!_online)),
      _LivreurOrders(online: _online),
      const _LivreurActive(),
      const ParametresScreen(role: 'Livreur'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('VELOX Livreur',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
        leading: IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Se déconnecter',
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ),
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: vc.surface,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined), label: 'Accueil'),
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined), label: 'Commandes'),
          NavigationDestination(
              icon: Icon(Icons.two_wheeler), label: 'En cours'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined), label: 'Paramètres'),
        ],
      ),
    );
  }
}

/// Dashboard d'accueil.
class _LivreurHome extends StatelessWidget {
  const _LivreurHome({required this.online, required this.onToggle});
  final bool online;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const WelcomeHeader(role: 'Livreur'),
        const SizedBox(height: 18),
        OnlineToggle(
          online: online,
          onTap: onToggle,
          onlineLabel: 'EN LIGNE — disponible',
          offlineLabel: 'HORS LIGNE — touchez pour démarrer',
        ),
        const SizedBox(height: 18),
        Row(
          children: const [
            Expanded(child: ProStat(label: 'Gains (jour)', value: 4200, unit: 'FDJ')),
            SizedBox(width: 12),
            Expanded(child: ProStat(label: 'Livraisons', value: 11)),
          ],
        ),
        const SizedBox(height: 12),
        const NoteCard(role: 'Livreur'),
        const SizedBox(height: 18),
        Text('Astuce',
            style:
                TextStyle(color: vc.onSurface, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          online
              ? 'Vous êtes en ligne. Les nouvelles commandes arrivent dans l\'onglet Commandes.'
              : 'Passez en ligne pour recevoir des commandes.',
          style: TextStyle(color: vc.dim, height: 1.5),
        ),
      ],
    );
  }
}

class _LivreurOrders extends StatefulWidget {
  const _LivreurOrders({required this.online});
  final bool online;
  @override
  State<_LivreurOrders> createState() => _LivreurOrdersState();
}

class _LivreurOrdersState extends State<_LivreurOrders> {
  final List<Map<String, dynamic>> _orders = [
    {'id': 1040, 'resto': 'Chez Ayan', 'client': 'Inès A.', 'km': 2.3, 'gain': 450},
    {'id': 1041, 'resto': 'Pizza Layla', 'client': 'Omar S.', 'km': 3.8, 'gain': 600},
  ];

  void _remove(int id, String msg) {
    setState(() => _orders.removeWhere((o) => o['id'] == id));
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    if (!widget.online) {
      return const EmptyState(
        title: 'Hors ligne',
        subtitle: 'Passez en ligne depuis l\'accueil pour recevoir des commandes.',
        icon: Icons.power_settings_new,
      );
    }
    if (_orders.isEmpty) {
      return const EmptyState(
        title: 'Tout est clair',
        subtitle: 'Vous n\'avez pas de commandes pour le moment',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: _orders.length,
      itemBuilder: (context, i) {
        final o = _orders[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: vc.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: vc.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Commande #${o['id']}',
                      style: TextStyle(
                          color: vc.onSurface, fontWeight: FontWeight.w800)),
                  Text('+${o['gain']} FDJ',
                      style: TextStyle(
                          color: vc.primary, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 8),
              Text('${o['resto']} → ${o['client']} · ${o['km']} km',
                  style: TextStyle(color: vc.dim)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _remove(o['id'] as int, 'Commande refusée'),
                      child: const Text('Refuser'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => _remove(
                          o['id'] as int, 'Commande acceptée — voir En cours'),
                      child: const Text('Accepter'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LivreurActive extends StatefulWidget {
  const _LivreurActive();
  @override
  State<_LivreurActive> createState() => _LivreurActiveState();
}

class _LivreurActiveState extends State<_LivreurActive> {
  final _steps = ['Accepté', 'En route resto', 'Commande récupérée', 'Livrée'];
  int _step = 1;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Livraison en cours',
              style: TextStyle(
                  color: vc.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('Chez Ayan → Inès A. · 2.3 km', style: TextStyle(color: vc.dim)),
          const SizedBox(height: 20),
          for (int i = 0; i < _steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    i < _step
                        ? Icons.check_circle
                        : (i == _step
                            ? Icons.radio_button_checked
                            : Icons.circle_outlined),
                    color: i <= _step ? vc.primary : vc.dim,
                  ),
                  const SizedBox(width: 10),
                  Text(_steps[i],
                      style: TextStyle(
                        color: i <= _step ? vc.onSurface : vc.dim,
                        fontWeight:
                            i == _step ? FontWeight.w700 : FontWeight.w400,
                      )),
                ],
              ),
            ),
          const Spacer(),
          SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _step < _steps.length - 1
                    ? () => setState(() => _step++)
                    : null,
                child: Text(_step < _steps.length - 1
                    ? 'Étape suivante'
                    : 'Livraison terminée ✓'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
