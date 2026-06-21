import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/velox_theme.dart';
import '../main.dart';

/// Stockage simple de la photo de profil (en session).
class ProfileStore {
  static final ValueNotifier<String?> photoPath = ValueNotifier<String?>(null);

  static Future<void> pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? img =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (img != null) photoPath.value = img.path;
    } catch (_) {}
  }
}

/// Avatar du partenaire : photo si dispo, sinon icône du rôle.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.role, this.size = 48});
  final String role;
  final double size;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    return ValueListenableBuilder<String?>(
      valueListenable: ProfileStore.photoPath,
      builder: (context, path, _) {
        final hasPhoto = path != null && path.isNotEmpty;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: vc.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: hasPhoto
                ? null
                : Border.all(color: vc.primary, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasPhoto
              ? Image.file(
                  File(path),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                )
              : Icon(
                  role == 'Taxi' ? Icons.local_taxi : Icons.two_wheeler,
                  color: vc.primary,
                  size: size * 0.5,
                ),
        );
      },
    );
  }
}

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
        ProfileAvatar(role: role, size: 56),
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

/// Carte de disponibilité avec un interrupteur (ouvrir / fermer).
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: online
            ? vc.primary.withValues(alpha: 0.14)
            : vc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: online ? vc.primary : vc.line, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: online ? vc.primary : vc.line,
              shape: BoxShape.circle,
            ),
            child: Icon(
              online ? Icons.power_settings_new : Icons.power_off,
              color: online ? vc.onPrimary : vc.dim,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(online ? 'Disponible' : 'Indisponible',
                    style: TextStyle(
                        color: vc.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                const SizedBox(height: 2),
                Text(online ? onlineLabel : offlineLabel,
                    style: TextStyle(color: vc.dim, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: online,
            activeColor: vc.onPrimary,
            activeTrackColor: vc.primary,
            onChanged: (_) => onTap(),
          ),
        ],
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
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    ProfileAvatar(role: role, size: 110),
                    Material(
                      color: vc.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => ProfileStore.pickFromGallery(),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(Icons.photo_camera,
                              size: 18, color: vc.onPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => ProfileStore.pickFromGallery(),
                  icon: const Icon(Icons.upload),
                  label: const Text('Changer la photo'),
                ),
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
class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({super.key, required this.role});
  final String role;
  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
  int _period = 1; // 0 = jour, 1 = semaine, 2 = mois

  Map<String, List<List<String>>> get _data => widget.role == 'Taxi'
      ? {
          'jour': [
            ['Héron → Aéroport', '1 800 DJF', '11:20'],
            ['Balbala → Centre', '900 DJF', '09:05'],
          ],
          'semaine': [
            ['Héron → Aéroport', '1 800 DJF', 'Lun'],
            ['Gabode → Plateau', '1 200 DJF', 'Mar'],
            ['Centre → Balbala', '950 DJF', 'Jeu'],
            ['Aéroport → Héron', '1 800 DJF', 'Ven'],
          ],
          'mois': [
            ['Total 128 courses', '168 000 DJF', 'Juin'],
            ['Total 112 courses', '149 500 DJF', 'Mai'],
            ['Total 134 courses', '171 200 DJF', 'Avril'],
          ],
        }
      : {
          'jour': [
            ['Chez Ayan → Inès A.', '450 DJF', '12:10'],
            ['Pizza Layla → Omar S.', '600 DJF', '10:30'],
          ],
          'semaine': [
            ['Chez Ayan → Inès A.', '450 DJF', 'Lun'],
            ['Le Gourmet → Farah M.', '500 DJF', 'Mar'],
            ['Pizza Layla → Omar S.', '600 DJF', 'Mer'],
            ['Snack 7 → Bilal R.', '400 DJF', 'Ven'],
          ],
          'mois': [
            ['Total 96 livraisons', '96 500 DJF', 'Juin'],
            ['Total 88 livraisons', '88 200 DJF', 'Mai'],
            ['Total 102 livraisons', '101 800 DJF', 'Avril'],
          ],
        };

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    final key = ['jour', 'semaine', 'mois'][_period];
    final items = _data[key]!;
    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Jour')),
                ButtonSegment(value: 1, label: Text('Semaine')),
                ButtonSegment(value: 2, label: Text('Mois')),
              ],
              selected: {_period},
              onSelectionChanged: (s) => setState(() => _period = s.first),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
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
                              Text(it[0],
                                  style: TextStyle(
                                      color: vc.onSurface,
                                      fontWeight: FontWeight.w700)),
                              Text(it[2],
                                  style: TextStyle(
                                      color: vc.dim, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(it[1],
                            style: TextStyle(
                                color: vc.primary,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
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

/// ───────────────────────── GRAPHIQUES ──────────────────────────────────────
/// Histogramme hebdo animé (gains par jour).
class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({
    super.key,
    required this.values,
    this.labels = const ['L', 'M', 'M', 'J', 'V', 'S', 'D'],
  });
  final List<int> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => SizedBox(
        height: 130,
        child: CustomPaint(
          painter: _BarPainter(
            values: values,
            labels: labels,
            progress: t,
            bar: vc.primary,
            text: vc.dim,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.values,
    required this.labels,
    required this.progress,
    required this.bar,
    required this.text,
  });
  final List<int> values;
  final List<String> labels;
  final double progress;
  final Color bar;
  final Color text;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV = values.reduce(math.max).toDouble().clamp(1, double.infinity);
    final n = values.length;
    const gap = 10.0;
    const labelH = 22.0;
    final chartH = size.height - labelH;
    final barW = (size.width - gap * (n - 1)) / n;
    final paint = Paint()..color = bar;

    for (int i = 0; i < n; i++) {
      final h = (values[i] / maxV) * chartH * progress;
      final x = i * (barW + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, chartH - h, barW, h),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, paint);

      final tp = TextPainter(
        text: TextSpan(
            text: labels[i % labels.length],
            style: TextStyle(color: text, fontSize: 11)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + (barW - tp.width) / 2, chartH + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.progress != progress || old.values != values;
}

/// Donut animé (répartition).
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.segments,
    this.centerLabel = '',
    this.centerValue = '',
  });
  final List<DonutSeg> segments;
  final String centerLabel;
  final String centerValue;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => SizedBox(
        height: 130,
        width: 130,
        child: CustomPaint(
          painter: _DonutPainter(segments: segments, progress: t, track: vc.line),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(centerValue,
                    style: TextStyle(
                        color: vc.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 18)),
                Text(centerLabel,
                    style: TextStyle(color: vc.dim, fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DonutSeg {
  final String label;
  final double value;
  final Color color;
  const DonutSeg(this.label, this.value, this.color);
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(
      {required this.segments, required this.progress, required this.track});
  final List<DonutSeg> segments;
  final double progress;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final total =
        segments.fold<double>(0, (s, e) => s + e.value).clamp(0.0001, 1e9);
    final rect = Offset.zero & size;
    const stroke = 18.0;
    final inner = rect.deflate(stroke / 2);
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(inner, 0, 2 * math.pi, false, bg);

    double start = -math.pi / 2;
    for (final seg in segments) {
      final sweep = (seg.value / total) * 2 * math.pi * progress;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = seg.color;
      canvas.drawArc(inner, start, sweep, false, p);
      start += (seg.value / total) * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.progress != progress;
}

/// Carte "Performance" : dégradé + histogramme hebdo.
class PerformanceCard extends StatelessWidget {
  const PerformanceCard({super.key, required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    final week = role == 'Taxi'
        ? [5200, 3800, 6100, 4900, 7300, 8450, 5600]
        : [2600, 3100, 2900, 3800, 4200, 4500, 3300];
    final total = week.fold<int>(0, (s, e) => s + e);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            vc.primary.withValues(alpha: 0.22),
            vc.surface,
          ],
        ),
        border: Border.all(color: vc.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: vc.primary, size: 20),
              const SizedBox(width: 8),
              Text('Performance · 7 jours',
                  style: TextStyle(
                      color: vc.onSurface, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('$total DJF',
                  style: TextStyle(
                      color: vc.primary, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 14),
          WeeklyBarChart(values: week),
        ],
      ),
    );
  }
}

/// Carte répartition (donut + légende).
class RepartitionCard extends StatelessWidget {
  const RepartitionCard({super.key, required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    final segs = role == 'Taxi'
        ? const [
            DonutSeg('Terminées', 24, Color(0xFF31D63B)),
            DonutSeg('Annulées', 3, Color(0xFFFF5252)),
          ]
        : const [
            DonutSeg('Livrées', 41, Color(0xFF31D63B)),
            DonutSeg('Refusées', 6, Color(0xFFFFC107)),
          ];
    final done = segs.first.value.toInt();
    final tot = segs.fold<double>(0, (s, e) => s + e.value).toInt();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: vc.line),
      ),
      child: Row(
        children: [
          DonutChart(
            segments: segs,
            centerValue: '$done/$tot',
            centerLabel: role == 'Taxi' ? 'courses' : 'livraisons',
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Répartition',
                    style: TextStyle(
                        color: vc.onSurface, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                for (final s in segs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                              color: s.color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text('${s.label} · ${s.value.toInt()}',
                            style: TextStyle(color: vc.dim)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
