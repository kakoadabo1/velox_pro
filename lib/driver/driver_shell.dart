import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/velox_theme.dart';
import '../i18n/app_lang.dart';
import '../common/pro_common.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';

class DriverShell extends StatefulWidget {
  const DriverShell({super.key});
  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell>
    with WidgetsBindingObserver {
  int _tab = 0;
  bool _online = false;
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_online) return;
    FirestoreService.setPartnerOnline(
      role: 'driver',
      online: state == AppLifecycleState.resumed,
    );
  }

  Future<void> _setOnline(bool v) async {
    setState(() => _online = v);
    if (v) {
      final pos = await LocationService.current();
      if (pos != null) {
        _lat = pos.latitude;
        _lng = pos.longitude;
        if (mounted) setState(() {});
      }
      FirestoreService.setPartnerOnline(
          role: 'driver', online: true, lat: _lat, lng: _lng);
    } else {
      FirestoreService.setPartnerOnline(role: 'driver', online: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    final pages = [
      _DriverHome(online: _online, onToggle: () => _setOnline(!_online)),
      _DriverRequests(online: _online, lat: _lat, lng: _lng),
      const _DriverActive(),
      const ParametresScreen(role: 'Taxi'),
    ];
    final titles = [tr('title_taxi'), tr('tab_requests'), tr('title_active_ride'), tr('tab_settings')];

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
                  color: _online ? vc.primary : vc.dim),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.logout),
          tooltip: tr('logout'),
          onPressed: () async {
            if (_online) {
              await FirestoreService.setPartnerOnline(
                  role: 'driver', online: false);
            }
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
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_outlined), label: tr('tab_home')),
          NavigationDestination(
              icon: const Icon(Icons.notifications_outlined),
              label: tr('tab_requests')),
          NavigationDestination(
              icon: const Icon(Icons.local_taxi), label: tr('tab_inflight')),
          NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              label: tr('tab_settings')),
        ],
      ),
    );
  }
}

class _DriverHome extends StatelessWidget {
  const _DriverHome({required this.online, required this.onToggle});
  final bool online;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    return StreamBuilder<Map<String, dynamic>>(
      stream: FirestoreService.partnerStream(),
      builder: (context, snap) {
        final p = snap.data ?? const {};
        final gains = ((p['gainsToday'] ?? 0) as num).toInt();
        final courses = ((p['rides'] ?? 0) as num).toInt();
        final weekly =
            (p['weekly'] as List?)?.map((e) => (e as num).toInt()).toList();
        List<DonutSeg>? segs;
        if (p['done'] != null || p['cancelled'] != null) {
          segs = [
            DonutSeg(tr('seg_done'), ((p['done'] ?? 0) as num).toDouble(),
                const Color(0xFF31D63B)),
            DonutSeg(tr('seg_cancelled'), ((p['cancelled'] ?? 0) as num).toDouble(),
                const Color(0xFFFF5252)),
          ];
        }
        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const WelcomeHeader(role: 'Taxi'),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: vc.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: vc.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('gains_today'),
                      style: TextStyle(color: vc.dim, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text('$gains DJF',
                      style: TextStyle(
                          color: vc.primary,
                          fontSize: 34,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('$courses ${tr('courses_n')}',
                      style: TextStyle(color: vc.dim, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            OnlineToggle(
              online: online,
              onTap: onToggle,
              onlineLabel: tr('sub_on_driver'),
              offlineLabel: tr('sub_off_driver'),
            ),
            const SizedBox(height: 14),
            PerformanceCard(weekly: weekly),
            const SizedBox(height: 14),
            RepartitionCard(segments: segs),
            const SizedBox(height: 14),
            NoteCard(role: 'Taxi'),
            const SizedBox(height: 18),
            Row(
              children: [
                Icon(Icons.info_outline, color: vc.primary, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    online
                        ? tr('tip_on_driver')
                        : tr('tip_off_driver'),
                    style: TextStyle(color: vc.dim),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _DriverRequests extends StatelessWidget {
  const _DriverRequests({required this.online, this.lat, this.lng});
  final bool online;
  final double? lat;
  final double? lng;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    if (!online) {
      return EmptyState(
        title: tr('offline_t'),
        subtitle: tr('offline_sub'),
        icon: Icons.power_settings_new,
      );
    }
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService.pendingRides(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final rides = List<Map<String, dynamic>>.from(snap.data ?? const []);
        if (rides.isEmpty) {
          return EmptyState(
            title: tr('no_request'),
            subtitle: tr('no_request_sub'),
            icon: Icons.local_taxi_outlined,
          );
        }
        // Distance jusqu'au point de départ de la course (fromLat / fromLng).
        double? distOf(Map<String, dynamic> r) {
          if (lat == null || lng == null) return null;
          final rl = r['fromLat'], rg = r['fromLng'];
          if (rl is num && rg is num) {
            return LocationService.km(
                lat!, lng!, rl.toDouble(), rg.toDouble());
          }
          return null;
        }

        rides.sort((a, b) {
          final da = distOf(a), db = distOf(b);
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(18),
          itemCount: rides.length,
          itemBuilder: (context, i) {
            final r = rides[i];
            final d = distOf(r);
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
                      Expanded(
                        child: Text(
                          '${r['from'] ?? '?'} → ${r['to'] ?? '?'}',
                          style: TextStyle(
                              color: vc.onSurface,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text('${r['price'] ?? 0} DJF',
                          style: TextStyle(
                              color: vc.primary,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                  if (d != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.near_me, size: 14, color: vc.primary),
                        const SizedBox(width: 4),
                        Text('${d.toStringAsFixed(1)} km',
                            style: TextStyle(
                                color: vc.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        try {
                          final ok = await FirestoreService.acceptRide(
                              r['id'] as String);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(ok
                                      ? tr('ride_accepted')
                                      : tr('already_taken')),
                                  behavior: SnackBarBehavior.floating),
                            );
                          }
                        } catch (_) {}
                      },
                      child: Text(tr('accept')),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DriverActive extends StatelessWidget {
  const _DriverActive();

  Future<void> _launch(BuildContext context, Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(tr('cant_open')),
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService.myActiveRides(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data ?? const [];
        if (list.isEmpty) {
          return EmptyState(
            title: tr('no_course'),
            subtitle: tr('no_course_sub'),
            icon: Icons.local_taxi_outlined,
          );
        }
        final r = list.first;
        final to = (r['to'] ?? 'Djibouti').toString();
        final phone = (r['clientPhone'] ?? '').toString();
        final status = (r['status'] ?? 'assignee') as String;

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
                    Text(tr('course_in_progress'),
                        style: TextStyle(
                            color: vc.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text('${r['from'] ?? '?'} → ${r['to'] ?? '?'}',
                        style: TextStyle(color: vc.onSurface)),
                    const SizedBox(height: 2),
                    Text('${r['price'] ?? 0} DJF',
                        style: TextStyle(
                            color: vc.primary, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _launch(
                        context,
                        Uri.parse(
                            'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(to)}'),
                      ),
                      icon: const Icon(Icons.navigation),
                      label: Text(tr('navigate')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: phone.isEmpty
                          ? null
                          : () => _launch(context, Uri.parse('tel:$phone')),
                      icon: const Icon(Icons.phone),
                      label: Text(tr('call')),
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
                    onPressed: () async {
                      final next =
                          status == 'assignee' ? 'en_route' : 'terminee';
                      try {
                        if (next == 'terminee') {
                          await FirestoreService.completeRide(
                              r['id'] as String, (r['price'] ?? 0) as num);
                        } else {
                          await FirestoreService.setRideStatus(
                              r['id'] as String, next);
                        }
                      } catch (_) {}
                    },
                    child: Text(status == 'assignee'
                        ? tr('start_ride')
                        : tr('end_ride')),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
