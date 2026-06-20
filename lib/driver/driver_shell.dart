import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/velox_theme.dart';

class DriverShell extends StatefulWidget {
  const DriverShell({super.key});

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  bool _online = false;
  bool _onRide = false;
  Timer? _incoming;

  @override
  void dispose() {
    _incoming?.cancel();
    super.dispose();
  }

  void _toggleOnline() {
    setState(() => _online = !_online);
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
          setState(() => _onRide = true);
        },
        onRefuse: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    return Scaffold(
      appBar: AppBar(
        title: const Text('VELOX Taxi',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
        leading: IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Changer de rôle',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _onRide
          ? _ActiveRide(onEnd: () => setState(() => _onRide = false))
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _GainsCard(),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: _toggleOnline,
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      color: _online ? vc.primary.withValues(alpha: 0.1) : vc.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: _online ? vc.primary : vc.line, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        _online
                            ? 'EN LIGNE — en attente de course'
                            : 'HORS LIGNE — touchez pour démarrer',
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
                Text(
                  _online
                      ? 'Une demande de course va arriver…'
                      : 'Passez en ligne pour recevoir des courses.',
                  style: TextStyle(color: vc.dim),
                ),
              ],
            ),
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
          Text('Gains aujourd\'hui', style: TextStyle(color: vc.dim, fontSize: 13)),
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
          Text('6 courses · note 4.9 ★', style: TextStyle(color: vc.dim, fontSize: 12)),
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
                      color: vc.onSurface, fontSize: 18, fontWeight: FontWeight.w900)),
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
          Text('12 min · 5.4 km · 1 800 DJF',
              style: TextStyle(color: vc.dim)),
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
      setState(() => _eta = _eta > 5 ? _eta - 5 : 0);
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
                Text('ARRIVÉE DANS', style: TextStyle(color: vc.dim, fontSize: 12)),
                const SizedBox(height: 4),
                Text('$mm:$ss',
                    style: TextStyle(
                        color: vc.primary, fontSize: 40, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('COURSE EN COURS',
              style: TextStyle(color: vc.onSurface, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('Vers Aéroport · 1 800 DJF', style: TextStyle(color: vc.dim)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.navigation),
                  label: const Text('Naviguer'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone),
                  label: const Text('Appeler'),
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: widget.onEnd,
              child: const Text('Terminer la course'),
            ),
          ),
        ],
      ),
    );
  }
}
