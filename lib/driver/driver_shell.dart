import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/velox_theme.dart';
import '../common/pro_common.dart';
import '../services/firestore_service.dart';

class DriverShell extends StatefulWidget {
  const DriverShell({super.key});

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  int _tab = 0;
  bool _online = false; // conservé entre les onglets
  bool _onRide = false;
  Timer? _incoming;

  @override
  void dispose() {
    _incoming?.cancel();
    super.dispose();
  }

  void _setOnline(bool v) {
    setState(() => _online = v);
    FirestoreService.setPartnerOnline(role: 'driver', online: v);
    _incoming?.cancel();
    if (_online && !_onRide) {
      _incoming = Timer(const Duration(seconds: 2), _showRideRequest);
    }
  }

  void _showRideRequest() {
    if (!mounted || !_online || _onRide) return;
    final vc = context.vc;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: vc.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => _RideRequestSheet(
        onAccept: () {
          Navigator.pop(ctx);
          setState(() {
            _onRide = true;
            _tab = 2; // bascule sur "En cours"
          });
        },
        onRefuse: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    final pages = [
      _DriverHome(
        online: _online,
        onRide: _onRide,
        onToggle: () => _setOnline(!_online),
      ),
      const _DriverCourses(),
      _onRide
          ? _ActiveRide(onEnd: () => setState(() => _onRide = false))
          : const EmptyState(
              title: 'Aucune course',
              subtitle: 'Aucune course en cours pour le moment.',
              icon: Icons.local_taxi_outlined,
            ),
      const ParametresScreen(role: 'Taxi'),
    ];

    final titles = ['VELOX Taxi', 'Courses', 'Course en cours', 'Paramètres'];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(titles[_tab],
                style: const TextStyle(
                    fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _online ? vc.primary : vc.dim,
              ),
            ),
          ],
        ),
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
              icon: Icon(Icons.receipt_long_outlined), label: 'Courses'),
          NavigationDestination(
              icon: Icon(Icons.local_taxi), label: 'En cours'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined), label: 'Paramètres'),
        ],
      ),
    );
  }
}

class _DriverHome extends StatelessWidget {
  const _DriverHome({
    required this.online,
    required this.onRide,
    required this.onToggle,
  });
  final bool online;
  final bool onRide;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const WelcomeHeader(role: 'Taxi'),
        const SizedBox(height: 18),
        _GainsCard(),
        const SizedBox(height: 18),
        OnlineToggle(
          online: online,
          onTap: onToggle,
          onlineLabel: 'En attente de course',
          offlineLabel: 'Activez pour recevoir des courses',
        ),
        const SizedBox(height: 12),
        const NoteCard(role: 'Taxi'),
        const SizedBox(height: 14),
        const PerformanceCard(role: 'Taxi'),
        const SizedBox(height: 14),
        const RepartitionCard(role: 'Taxi'),
        const SizedBox(height: 18),
        Row(
          children: [
            Icon(Icons.info_outline, color: vc.primary, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                onRide
                    ? 'Course en cours — voir l\'onglet En cours.'
                    : (online
                        ? 'Une demande de course va arriver…'
                        : 'Passez en ligne pour recevoir des courses.'),
                style: TextStyle(color: vc.dim),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DriverCourses extends StatelessWidget {
  const _DriverCourses();

  static const _history = [
    {'from': 'Héron', 'to': 'Aéroport', 'price': 1800, 'when': "Aujourd'hui 11:20"},
    {'from': 'Balbala', 'to': 'Centre-ville', 'price': 900, 'when': "Aujourd'hui 09:05"},
    {'from': 'Gabode', 'to': 'Plateau', 'price': 1200, 'when': 'Hier 18:40'},
    {'from': 'Aéroport', 'to': 'Héron', 'price': 1800, 'when': 'Hier 16:10'},
  ];

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text('Historique des courses',
            style: TextStyle(
                color: vc.onSurface, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        for (final c in _history)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: vc.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: vc.line),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: vc.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${c['from']} → ${c['to']}',
                          style: TextStyle(
                              color: vc.onSurface,
                              fontWeight: FontWeight.w700)),
                      Text('${c['when']}',
                          style: TextStyle(color: vc.dim, fontSize: 12)),
                    ],
                  ),
                ),
                Text('${c['price']} DJF',
                    style: TextStyle(
                        color: vc.primary, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
      ],
    );
  }
}

class _GainsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: vc.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gains aujourd\'hui',
              style: TextStyle(color: vc.dim, fontSize: 13)),
          const SizedBox(height: 6),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: 8450),
            duration: const Duration(milliseconds: 1000),
            builder: (context, v, _) => Text(
              '$v DJF',
              style: TextStyle(
                  color: vc.primary, fontSize: 34, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 4),
          Text('6 courses · note 4.9 ★',
              style: TextStyle(color: vc.dim, fontSize: 12)),
        ],
      ),
    );
  }
}

class _RideRequestSheet extends StatefulWidget {
  const _RideRequestSheet({required this.onAccept, required this.onRefuse});
  final VoidCallback onAccept;
  final VoidCallback onRefuse;

  @override
  State<_RideRequestSheet> createState() => _RideRequestSheetState();
}

class _RideRequestSheetState extends State<_RideRequestSheet> {
  int _left = 12;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_left <= 1) {
        timer.cancel();
        if (mounted) widget.onRefuse();
      } else {
        setState(() => _left--);
      }
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 18, 20, 18 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Nouvelle course',
                  style: TextStyle(
                      color: vc.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: vc.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Text('$_left',
                    style: TextStyle(
                        color: vc.primary, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Quartier Héron → Aéroport de Djibouti',
              style: TextStyle(color: vc.onSurface)),
          const SizedBox(height: 4),
          Text('12 min · 5.4 km · 1 800 DJF', style: TextStyle(color: vc.dim)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onRefuse,
                  child: const Text('Refuser'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: widget.onAccept,
                  child: const Text('Accepter'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveRide extends StatefulWidget {
  const _ActiveRide({required this.onEnd});
  final VoidCallback onEnd;

  @override
  State<_ActiveRide> createState() => _ActiveRideState();
}

class _ActiveRideState extends State<_ActiveRide> {
  int _eta = 12 * 60;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _eta = _eta > 0 ? _eta - 1 : 0);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Future<void> _launch(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Aucune application disponible'),
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    final mm = (_eta ~/ 60).toString().padLeft(2, '0');
    final ss = (_eta % 60).toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: vc.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: vc.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ARRIVÉE DANS',
                    style: TextStyle(color: vc.dim, fontSize: 12)),
                const SizedBox(height: 4),
                Text('$mm:$ss',
                    style: TextStyle(
                        color: vc.primary,
                        fontSize: 40,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('COURSE EN COURS',
              style: TextStyle(
                  color: vc.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('Vers Aéroport · 1 800 DJF', style: TextStyle(color: vc.dim)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _launch(Uri.parse(
                      'https://www.google.com/maps/dir/?api=1&destination=Aeroport+de+Djibouti')),
                  icon: const Icon(Icons.navigation),
                  label: const Text('Naviguer'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _launch(Uri.parse('tel:+25377000000')),
                  icon: const Icon(Icons.phone),
                  label: const Text('Appeler'),
                ),
              ),
            ],
          ),
          const Spacer(),
          SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: widget.onEnd,
                child: const Text('Terminer la course'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
