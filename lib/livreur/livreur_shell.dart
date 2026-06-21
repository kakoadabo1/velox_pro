import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/velox_theme.dart';

class LivreurShell extends StatefulWidget {
  const LivreurShell({super.key});

  @override
  State<LivreurShell> createState() => _LivreurShellState();
}

class _LivreurShellState extends State<LivreurShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    final pages = [
      const _LivreurHome(),
      const _LivreurOrders(),
      const _LivreurActive(),
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
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: vc.surface,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Commandes'),
          NavigationDestination(icon: Icon(Icons.two_wheeler), label: 'En cours'),
        ],
      ),
    );
  }
}

class _LivreurHome extends StatefulWidget {
  const _LivreurHome();
  @override
  State<_LivreurHome> createState() => _LivreurHomeState();
}

class _LivreurHomeState extends State<_LivreurHome> {
  bool _online = false;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        GestureDetector(
          onTap: () => setState(() => _online = !_online),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: _online ? vc.primary.withValues(alpha: 0.1) : vc.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _online ? vc.primary : vc.line, width: 1.5),
            ),
            child: Center(
              child: Text(
                _online ? 'EN LIGNE — disponible' : 'HORS LIGNE — touchez pour démarrer',
                style: TextStyle(
                  color: _online ? vc.primary : vc.dim,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: _StatCard(label: 'Gains (jour)', value: 4200, unit: 'FDJ')),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Livraisons', value: 11, unit: '')),
          ],
        ),
        const SizedBox(height: 18),
        Text('Astuce', style: TextStyle(color: vc.onSurface, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          'Passez en ligne pour recevoir des commandes. Elles arrivent dans l\'onglet Commandes.',
          style: TextStyle(color: vc.dim, height: 1.5),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.unit});
  final String label;
  final int value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      builder: (context, v, _) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: vc.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: vc.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: vc.dim, fontSize: 12)),
              const SizedBox(height: 6),
              Text(
                unit.isEmpty ? '$v' : '$v $unit',
                style: TextStyle(
                  color: vc.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LivreurOrders extends StatefulWidget {
  const _LivreurOrders();
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    if (_orders.isEmpty) {
      return Center(
        child: Text('Aucune commande disponible', style: TextStyle(color: vc.dim)),
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
                      style: TextStyle(color: vc.onSurface, fontWeight: FontWeight.w800)),
                  Text('+${o['gain']} FDJ',
                      style: TextStyle(color: vc.primary, fontWeight: FontWeight.w800)),
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
                      onPressed: () =>
                          _remove(o['id'] as int, 'Commande acceptée — voir En cours'),
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
              style: TextStyle(color: vc.onSurface, fontSize: 20, fontWeight: FontWeight.w900)),
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
                        : (i == _step ? Icons.radio_button_checked : Icons.circle_outlined),
                    color: i <= _step ? vc.primary : vc.dim,
                  ),
                  const SizedBox(width: 10),
                  Text(_steps[i],
                      style: TextStyle(
                        color: i <= _step ? vc.onSurface : vc.dim,
                        fontWeight: i == _step ? FontWeight.w700 : FontWeight.w400,
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
