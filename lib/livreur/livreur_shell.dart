import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/velox_theme.dart';
import '../i18n/app_lang.dart';
import '../common/pro_common.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';

class LivreurShell extends StatefulWidget {
  const LivreurShell({super.key});
  @override
  State<LivreurShell> createState() => _LivreurShellState();
}

class _LivreurShellState extends State<LivreurShell>
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
      role: 'livreur',
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
          role: 'livreur', online: true, lat: _lat, lng: _lng);
    } else {
      FirestoreService.setPartnerOnline(role: 'livreur', online: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    final pages = [
      _LivreurHome(online: _online, onToggle: () => _setOnline(!_online)),
      _LivreurOrders(online: _online, lat: _lat, lng: _lng),
      const _LivreurActive(),
      const ParametresScreen(role: 'Livreur'),
    ];
    final titles = [
      tr('title_livreur'),
      tr('tab_orders'),
      tr('title_active_delivery'),
      tr('tab_settings')
    ];

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
                  role: 'livreur', online: false);
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
              icon: const Icon(Icons.inventory_2_outlined),
              label: tr('tab_orders')),
          NavigationDestination(
              icon: const Icon(Icons.two_wheeler), label: tr('tab_inflight')),
          NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              label: tr('tab_settings')),
        ],
      ),
    );
  }
}

class _LivreurHome extends StatelessWidget {
  const _LivreurHome({required this.online, required this.onToggle});
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
        final deliveries = ((p['deliveries'] ?? 0) as num).toInt();
        final weekly = (p['weekly'] as List?)
            ?.map((e) => (e as num).toInt())
            .toList();
        List<DonutSeg>? segs;
        if (p['delivered'] != null || p['refused'] != null) {
          segs = [
            DonutSeg(tr('seg_delivered'), ((p['delivered'] ?? 0) as num).toDouble(),
                const Color(0xFF31D63B)),
            DonutSeg(tr('seg_refused'), ((p['refused'] ?? 0) as num).toDouble(),
                const Color(0xFFFFC107)),
          ];
        }
        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const WelcomeHeader(role: 'Livreur'),
            const SizedBox(height: 18),
            OnlineToggle(
              online: online,
              onTap: onToggle,
              onlineLabel: tr('sub_on_livreur'),
              offlineLabel: tr('sub_off_livreur'),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                    child: ProStat(
                        label: tr('gains_day'), value: gains, unit: 'DJF')),
                const SizedBox(width: 12),
                Expanded(
                    child:
                        ProStat(label: tr('deliveries'), value: deliveries)),
              ],
            ),
            const SizedBox(height: 14),
            PerformanceCard(weekly: weekly),
            const SizedBox(height: 14),
            RepartitionCard(segments: segs),
            const SizedBox(height: 14),
            NoteCard(role: 'Livreur'),
            const SizedBox(height: 18),
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: vc.primary, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    online
                        ? tr('tip_on_livreur')
                        : tr('tip_off_livreur'),
                    style: TextStyle(color: vc.dim, height: 1.4),
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

class _LivreurOrders extends StatelessWidget {
  const _LivreurOrders({required this.online, this.lat, this.lng});
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
      stream: FirestoreService.pendingOrders(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = List<Map<String, dynamic>>.from(snap.data ?? const []);
        if (orders.isEmpty) {
          return EmptyState(
            title: tr('all_clear'),
            subtitle: tr('all_clear_sub'),
          );
        }
        // Distance (km) si on a notre position ET les coordonnées de la commande.
        double? distOf(Map<String, dynamic> o) {
          if (lat == null || lng == null) return null;
          final dl = o['deliveryLocation'];
          final ol = (dl is Map) ? dl['latitude'] : null;
          final og = (dl is Map) ? dl['longitude'] : null;
          if (ol is num && og is num) {
            return LocationService.km(lat!, lng!, ol.toDouble(), og.toDouble());
          }
          return null;
        }

        // Tri : la plus proche en premier ; celles sans coordonnées à la fin.
        orders.sort((a, b) {
          final da = distOf(a), db = distOf(b);
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(18),
          itemCount: orders.length,
          itemBuilder: (context, i) {
            final o = orders[i];
            final d = distOf(o);
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
                          '${o['restaurantName'] ?? 'Restaurant'} → ${o['customerName'] ?? 'Client'}',
                          style: TextStyle(
                              color: vc.onSurface,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text('${o['total'] ?? 0} DJF',
                          style: TextStyle(
                              color: vc.primary,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (d != null) ...[
                        Icon(Icons.near_me, size: 14, color: vc.primary),
                        const SizedBox(width: 4),
                        Text('${d.toStringAsFixed(1)} km',
                            style: TextStyle(
                                color: vc.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Text('${o['deliveryAddress'] ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: vc.dim)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        try {
                          final ok = await FirestoreService.acceptOrder(
                              o['id'] as String);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(ok
                                      ? tr('order_accepted')
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

class _LivreurActive extends StatelessWidget {
  const _LivreurActive();

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
      stream: FirestoreService.myActiveOrders(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data ?? const [];
        if (list.isEmpty) {
          return EmptyState(
            title: tr('no_delivery'),
            subtitle: tr('no_delivery_sub'),
            icon: Icons.two_wheeler,
          );
        }
        final o = list.first;
        final status = (o['status'] ?? 'ready') as String;
        final steps = ['ready', 'delivering', 'completed'];
        final labels = [tr('step_accepted'), tr('step_picked'), tr('step_delivered')];
        final idx = steps.indexOf(status).clamp(0, steps.length - 1);
        final address = (o['deliveryAddress'] ?? 'Djibouti').toString();
        final phone = (o['customerPhone'] ?? '').toString();

        return Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${o['restaurantName'] ?? 'Restaurant'} → ${o['customerName'] ?? 'Client'}',
                style: TextStyle(
                    color: vc.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(address, style: TextStyle(color: vc.dim)),
              const SizedBox(height: 18),
              for (int i = 0; i < steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        i < idx
                            ? Icons.check_circle
                            : (i == idx
                                ? Icons.radio_button_checked
                                : Icons.circle_outlined),
                        color: i <= idx ? vc.primary : vc.dim,
                      ),
                      const SizedBox(width: 10),
                      Text(labels[i],
                          style: TextStyle(
                              color: i <= idx ? vc.onSurface : vc.dim,
                              fontWeight:
                                  i == idx ? FontWeight.w700 : FontWeight.w400)),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _launch(
                        context,
                        Uri.parse(
                            'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address)}'),
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
                          idx < steps.length - 1 ? steps[idx + 1] : null;
                      if (next == null) return;
                      try {
                        if (next == 'completed') {
                          await FirestoreService.completeOrder(
                              o['id'] as String, (o['total'] ?? 0) as num);
                        } else {
                          await FirestoreService.setOrderStatus(
                              o['id'] as String, next);
                        }
                      } catch (_) {}
                    },
                    child: Text(
                      status == 'ready'
                          ? tr('mark_picked')
                          : (status == 'delivering'
                              ? tr('mark_delivered')
                              : tr('delivery_done')),
                    ),
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
