import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/velox_theme.dart';
import '../main.dart';

/// Nom affiché du partenaire, déduit du compte connecté.
/// Ex: "karim.h@velox.dj" -> "Karim H".
String proDisplayName() {
  final u = FirebaseAuth.instance.currentUser;
  String base;
  if (u?.displayName != null && u!.displayName!.trim().isNotEmpty) {
    base = u.displayName!.trim();
  } else if (u?.email != null && u!.email!.isNotEmpty) {
    base = u.email!.split('@').first;
  } else {
    base = 'Partenaire';
  }
  base = base.replaceAll(RegExp(r'[._\-]+'), ' ').trim();
  if (base.isEmpty) base = 'Partenaire';
  base = base
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : ''))
      .join(' ');
  return base;
}

/// En-tête "Bienvenue Mr X" + rôle.
class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({super.key, required this.role});
  final String role; // 'Livreur' | 'Taxi'

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: vc.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: vc.primary, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Icon(
            role == 'Taxi' ? Icons.local_taxi : Icons.two_wheeler,
            color: vc.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bienvenue', style: TextStyle(color: vc.dim, fontSize: 13)),
              Text(
                'Mr ${proDisplayName()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: vc.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w900),
              ),
              Text(
                role == 'Taxi' ? 'Chauffeur VTC' : 'Livreur partenaire',
                style:
                    TextStyle(color: vc.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Grand bouton EN LIGNE / HORS LIGNE.
class OnlineToggle extends StatelessWidget {
  const OnlineToggle({
    super.key,
    required this.online,
    required this.onTap,
    required this.onlineLabel,
    required this.offlineLabel,
  });
  final bool online;
  final VoidCallback onTap;
  final String onlineLabel;
  final String offlineLabel;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 66,
        decoration: BoxDecoration(
          color: online ? vc.primary : vc.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: online ? vc.primary : vc.line, width: 1.5),
        ),
        child: Center(
          child: Text(
            online ? onlineLabel : offlineLabel,
            style: TextStyle(
              color: online ? vc.onPrimary : vc.dim,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

/// Carte statistique avec compteur animé.
class ProStat extends StatelessWidget {
  const ProStat({
    super.key,
    required this.label,
    required this.value,
    this.unit = '',
  });
  final String label;
  final int value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      builder: (context, v, _) => Container(
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
                  color: vc.primary, fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte "note moyenne" cliquable -> ouvre les avis.
class NoteCard extends StatelessWidget {
  const NoteCard({super.key, required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    final note = role == 'Taxi' ? '4.9' : '4.8';
    final nb = role == 'Taxi' ? 128 : 96;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AvisScreen(role: role)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: vc.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: vc.line),
        ),
        child: Row(
          children: [
            Icon(Icons.star, color: vc.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Note moyenne',
                      style: TextStyle(color: vc.dim, fontSize: 12)),
                  Text('$note ★ · $nb avis',
                      style: TextStyle(
                          color: vc.onSurface, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: vc.dim),
          ],
        ),
      ),
    );
  }
}

/// État vide façon "Tout est clair".
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.wb_sunny_outlined,
  });
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 96, color: Colors.amber),
            const SizedBox(height: 20),
            Text(title,
                style: TextStyle(
                    color: vc.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: vc.dim, fontSize: 15, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

/// Un avis client.
class Avis {
  final String name;
  final int stars;
  final String comment;
  final String when;
  const Avis(this.name, this.stars, this.comment, this.when);
}

/// Écran "Avis clients".
class AvisScreen extends StatelessWidget {
  const AvisScreen({super.key, required this.role});
  final String role;

  List<Avis> get _data => role == 'Taxi'
      ? const [
          Avis('Inès A.', 5, 'Chauffeur ponctuel et très courtois.', "Aujourd'hui"),
          Avis('Omar S.', 5, 'Conduite douce, voiture propre.', 'Hier'),
          Avis('Farah M.', 4, 'Bon trajet, un peu de retard au départ.', 'Hier'),
          Avis('Yacin D.', 5, 'Parfait pour aller à l\'aéroport.', 'Il y a 2 j'),
          Avis('Hodan K.', 5, 'Je recommande, très pro.', 'Il y a 3 j'),
        ]
      : const [
          Avis('Sahra M.', 5, 'Livraison rapide, repas encore chaud !', "Aujourd'hui"),
          Avis('Bilal R.', 5, 'Très aimable, merci.', 'Hier'),
          Avis('Nadia H.', 4, 'Bien, mais un peu d\'attente.', 'Hier'),
          Avis('Karim A.', 5, 'Toujours au top.', 'Il y a 2 j'),
          Avis('Lula G.', 5, 'Livreur sympa et rapide.', 'Il y a 4 j'),
        ];

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    final avg = (_data.fold<int>(0, (s, a) => s + a.stars) / _data.length);
    return Scaffold(
      appBar: AppBar(title: const Text('Avis clients')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: vc.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: vc.line),
            ),
            child: Row(
              children: [
                Text(avg.toStringAsFixed(1),
                    style: TextStyle(
                        color: vc.primary,
                        fontSize: 40,
                        fontWeight: FontWeight.w900)),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < avg.round() ? Icons.star : Icons.star_border,
                          color: vc.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${_data.length} avis clients',
                        style: TextStyle(color: vc.dim)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final a in _data)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                      Text(a.name,
                          style: TextStyle(
                              color: vc.onSurface,
                              fontWeight: FontWeight.w800)),
                      Text(a.when,
                          style: TextStyle(color: vc.dim, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < a.stars ? Icons.star : Icons.star_border,
                        color: vc.primary,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(a.comment, style: TextStyle(color: vc.dim, height: 1.4)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// ───────────────────────── PARAMÈTRES (épuré + fonctionnel) ─────────────────
class ParametresScreen extends StatelessWidget {
  const ParametresScreen({super.key, required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;

    Widget tile(IconData icon, String label, String sub, Widget page) {
      return Column(
        children: [
          ListTile(
            leading: Icon(icon, color: vc.primary),
            title: Text(label,
                style: TextStyle(
                    color: vc.onSurface, fontWeight: FontWeight.w700)),
            subtitle: Text(sub, style: TextStyle(color: vc.dim, fontSize: 12)),
            trailing: Icon(Icons.chevron_right, color: vc.dim),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => page)),
          ),
          Divider(height: 1, color: vc.line),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        tile(Icons.person_outline, 'Profil', 'Vos informations',
            ProfilScreen(role: role)),
        tile(Icons.account_balance_wallet_outlined, 'Mes gains',
            'Détail des revenus', GainsScreen(role: role)),
        tile(Icons.history, 'Historique', 'Vos missions passées',
            HistoriqueScreen(role: role)),
        tile(Icons.star_outline, 'Avis clients', 'Ce que disent les clients',
            AvisScreen(role: role)),
        tile(Icons.tune, 'Réglages', 'Thème, notifications',
            const ReglagesScreen()),
        tile(Icons.support_agent, 'Aide & support', 'Nous contacter',
            const SupportScreen()),
      ],
    );
  }
}

/// ───────────────────────── PROFIL ──────────────────────────────────────────
class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key, required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    final email = FirebaseAuth.instance.currentUser?.email ?? '—';
    final note = role == 'Taxi' ? '4.9' : '4.8';

    Widget info(IconData ic, String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(ic, color: vc.primary, size: 20),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(color: vc.dim)),
              const Spacer(),
              Flexible(
                child: Text(value,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: vc.onSurface, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: vc.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: vc.primary, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                      role == 'Taxi' ? Icons.local_taxi : Icons.two_wheeler,
                      color: vc.primary,
                      size: 38),
                ),
                const SizedBox(height: 12),
                Text('Mr ${proDisplayName()}',
                    style: TextStyle(
                        color: vc.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
                Text(role == 'Taxi' ? 'Chauffeur VTC' : 'Livreur partenaire',
                    style: TextStyle(color: vc.primary)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: vc.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: vc.line),
            ),
            child: Column(
              children: [
                info(Icons.email_outlined, 'Email', email),
                Divider(height: 1, color: vc.line),
                info(Icons.badge_outlined, 'Statut', 'Partenaire vérifié'),
                Divider(height: 1, color: vc.line),
                info(Icons.star, 'Note', '$note ★'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
            ),
          ),
        ],
      ),
    );
  }
}

/// ───────────────────────── GAINS ───────────────────────────────────────────
class GainsScreen extends StatelessWidget {
  const GainsScreen({super.key, required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    final today = role == 'Taxi' ? 8450 : 4200;
    final week = role == 'Taxi' ? 41200 : 24800;
    final month = role == 'Taxi' ? 168000 : 96500;

    Widget big(String label, int value) => Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: vc.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: vc.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: vc.dim, fontSize: 13)),
              const SizedBox(height: 6),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: value),
                duration: const Duration(milliseconds: 900),
                builder: (context, v, _) => Text('$v DJF',
                    style: TextStyle(
                        color: vc.primary,
                        fontSize: 30,
                        fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Mes gains')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          big("Aujourd'hui", today),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: ProStat(label: 'Cette semaine', value: week, unit: 'DJF')),
              const SizedBox(width: 12),
              Expanded(child: ProStat(label: 'Ce mois', value: month, unit: 'DJF')),
            ],
          ),
          const SizedBox(height: 18),
          Text('Derniers versements',
              style: TextStyle(
                  color: vc.onSurface, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          for (final p in const [
            ['Lun.', 3800],
            ['Mar.', 5200],
            ['Mer.', 4100],
            ['Jeu.', 6300],
          ])
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: vc.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: vc.line),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${p[0]}', style: TextStyle(color: vc.dim)),
                  Text('+${p[1]} DJF',
                      style: TextStyle(
                          color: vc.primary, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// ───────────────────────── HISTORIQUE ──────────────────────────────────────
class HistoriqueScreen extends StatelessWidget {
  const HistoriqueScreen({super.key, required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    final items = role == 'Taxi'
        ? const [
            ['Héron → Aéroport', '1 800 DJF', "Aujourd'hui 11:20"],
            ['Balbala → Centre', '900 DJF', "Aujourd'hui 09:05"],
            ['Gabode → Plateau', '1 200 DJF', 'Hier 18:40'],
          ]
        : const [
            ['Chez Ayan → Inès A.', '450 DJF', "Aujourd'hui 12:10"],
            ['Pizza Layla → Omar S.', '600 DJF', "Aujourd'hui 10:30"],
            ['Le Gourmet → Farah M.', '500 DJF', 'Hier 19:15'],
          ];

    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          for (final it in items)
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
                        Text('${it[0]}',
                            style: TextStyle(
                                color: vc.onSurface,
                                fontWeight: FontWeight.w700)),
                        Text('${it[2]}',
                            style:
                                TextStyle(color: vc.dim, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text('${it[1]}',
                      style: TextStyle(
                          color: vc.primary, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// ───────────────────────── RÉGLAGES ────────────────────────────────────────
class ReglagesScreen extends StatefulWidget {
  const ReglagesScreen({super.key});
  @override
  State<ReglagesScreen> createState() => _ReglagesScreenState();
}

class _ReglagesScreenState extends State<ReglagesScreen> {
  bool _notifs = true;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        children: [
          SwitchListTile(
            value: isDark,
            activeColor: vc.primary,
            secondary: Icon(Icons.dark_mode, color: vc.primary),
            title: Text('Mode sombre',
                style: TextStyle(
                    color: vc.onSurface, fontWeight: FontWeight.w600)),
            onChanged: (v) =>
                themeModeNotifier.value = v ? ThemeMode.dark : ThemeMode.light,
          ),
          Divider(height: 1, color: vc.line),
          SwitchListTile(
            value: _notifs,
            activeColor: vc.primary,
            secondary: Icon(Icons.notifications_active_outlined,
                color: vc.primary),
            title: Text('Notifications',
                style: TextStyle(
                    color: vc.onSurface, fontWeight: FontWeight.w600)),
            subtitle: Text('Nouvelles missions et messages',
                style: TextStyle(color: vc.dim, fontSize: 12)),
            onChanged: (v) => setState(() => _notifs = v),
          ),
          Divider(height: 1, color: vc.line),
          ListTile(
            leading: Icon(Icons.language, color: vc.primary),
            title: Text('Langue',
                style: TextStyle(
                    color: vc.onSurface, fontWeight: FontWeight.w600)),
            trailing: Text('Français', style: TextStyle(color: vc.dim)),
          ),
        ],
      ),
    );
  }
}

/// ───────────────────────── SUPPORT ─────────────────────────────────────────
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;

    Widget row(IconData ic, String label, String value) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: vc.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: vc.line),
          ),
          child: Row(
            children: [
              Icon(ic, color: vc.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(color: vc.dim, fontSize: 12)),
                    Text(value,
                        style: TextStyle(
                            color: vc.onSurface,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy, color: vc.dim, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Copié'),
                        behavior: SnackBarBehavior.floating),
                  );
                },
              ),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Aide & support')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text('Besoin d\'aide ? Contactez l\'équipe VELOX.',
              style: TextStyle(color: vc.dim, height: 1.4)),
          const SizedBox(height: 16),
          row(Icons.phone, 'Téléphone', '+253 77 00 00 00'),
          row(Icons.chat, 'WhatsApp', '+253 77 00 00 00'),
          row(Icons.email_outlined, 'Email', 'support@velox.dj'),
          const SizedBox(height: 8),
          Text('Horaires : 7j/7, de 7h à 23h.',
              style: TextStyle(color: vc.dim)),
        ],
      ),
    );
  }
}
