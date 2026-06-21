import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/velox_theme.dart';

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

/// Onglet "Paramètres" : menu façon tiroir (comme le concurrent).
class ParametresScreen extends StatelessWidget {
  const ParametresScreen({
    super.key,
    required this.role,
    required this.online,
    required this.onToggleOnline,
  });
  final String role;
  final bool online;
  final ValueChanged<bool> onToggleOnline;

  void _soon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('$label — bientôt disponible'),
          behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    Widget tile(IconData icon, String label,
        {VoidCallback? onTap, Widget? trailing}) {
      return Column(
        children: [
          ListTile(
            leading: Icon(icon, color: vc.primary),
            title: Text(label,
                style: TextStyle(
                    color: vc.onSurface, fontWeight: FontWeight.w600)),
            trailing: trailing ?? Icon(Icons.chevron_right, color: vc.dim),
            onTap: onTap ?? () => _soon(context, label),
          ),
          Divider(height: 1, color: vc.line),
        ],
      );
    }

    return ListView(
      children: [
        // Indisponible = inverse de "en ligne"
        Column(
          children: [
            SwitchListTile(
              value: !online,
              activeColor: vc.primary,
              title: Text('Indisponible',
                  style: TextStyle(
                      color: vc.onSurface, fontWeight: FontWeight.w600)),
              subtitle: Text(
                online ? 'Vous êtes en ligne' : 'Vous êtes hors ligne',
                style: TextStyle(color: vc.dim, fontSize: 12),
              ),
              onChanged: (v) => onToggleOnline(!v),
            ),
            Divider(height: 1, color: vc.line),
          ],
        ),
        tile(Icons.star_outline, 'Avis',
            onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AvisScreen(role: role)),
                )),
        tile(Icons.history, 'Historique'),
        tile(Icons.account_balance_wallet_outlined, 'Gains'),
        tile(
          Icons.chat_bubble_outline,
          'Chat with us',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: const BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: const Text('11',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ),
        tile(Icons.campaign_outlined, 'Annonces'),
        tile(Icons.settings_outlined, 'Réglages'),
        tile(Icons.school_outlined, 'Didacticiel'),
        tile(Icons.support_agent, 'Soutien'),
      ],
    );
  }
}
