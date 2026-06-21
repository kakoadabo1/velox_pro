import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/velox_theme.dart';
import '../i18n/app_lang.dart';
import '../main.dart';
import '../services/firestore_service.dart';

/// Photo de profil (session).
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
            border: hasPhoto ? null : Border.all(color: vc.primary, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasPhoto
              ? Image.file(File(path),
                  width: size, height: size, fit: BoxFit.cover)
              : Icon(role == 'Taxi' ? Icons.local_taxi : Icons.two_wheeler,
                  color: vc.primary, size: size * 0.5),
        );
      },
    );
  }
}

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

class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({super.key, required this.role});
  final String role;

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
              Text(tr('welcome'), style: TextStyle(color: vc.dim, fontSize: 13)),
              Text('Mr ${proDisplayName()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: vc.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.w900)),
              Text(role == 'Taxi' ? tr('role_driver') : tr('role_livreur'),
                  style:
                      TextStyle(color: vc.primary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

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
        color: online ? vc.primary.withValues(alpha: 0.14) : vc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: online ? vc.primary : vc.line, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: online ? vc.primary : vc.line, shape: BoxShape.circle),
            child: Icon(online ? Icons.power_settings_new : Icons.power_off,
                color: online ? vc.onPrimary : vc.dim),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(online ? tr('available') : tr('unavailable'),
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

class ProStat extends StatelessWidget {
  const ProStat(
      {super.key, required this.label, required this.value, this.unit = ''});
  final String label;
  final int value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 800),
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
            Text(unit.isEmpty ? '$v' : '$v $unit',
                style: TextStyle(
                    color: vc.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class NoteCard extends StatelessWidget {
  const NoteCard({super.key, required this.role, this.rating, this.count});
  final String role;
  final double? rating;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    final noteTxt = rating != null ? rating!.toStringAsFixed(1) : '—';
    final nbTxt = count != null ? '$count ${tr('reviews_n')}' : tr('no_reviews_yet');
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
                  Text(tr('note_avg'),
                      style: TextStyle(color: vc.dim, fontSize: 12)),
                  Text('$noteTxt ★ · $nbTxt',
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

class EmptyState extends StatelessWidget {
  EmptyState({
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
                    fontSize: 26,
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

/// ─────────────────────────────── AVIS ──────────────────────────────────────
class AvisScreen extends StatelessWidget {
  const AvisScreen({super.key, required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    return Scaffold(
      appBar: AppBar(title: Text(tr('client_reviews'))),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService.myReviews(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data ?? const [];
          if (data.isEmpty) {
            return EmptyState(
              title: tr('no_reviews'),
              subtitle: tr('no_reviews_sub'),
              icon: Icons.star_border,
            );
          }
          final avg = data.fold<num>(0, (s, a) => s + (a['stars'] ?? 0)) /
              data.length;
          return ListView(
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
                    Text('${data.length} ${tr('reviews_n')}',
                        style: TextStyle(color: vc.dim)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (final a in data)
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
                      Text('${a['authorName'] ?? 'Client'}',
                          style: TextStyle(
                              color: vc.onSurface,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < ((a['stars'] ?? 0) as num).toInt()
                                ? Icons.star
                                : Icons.star_border,
                            color: vc.primary,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('${a['comment'] ?? ''}',
                          style: TextStyle(color: vc.dim, height: 1.4)),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// ───────────────────────────── PARAMÈTRES ──────────────────────────────────
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
        tile(Icons.person_outline, tr('profile'), tr('profile_sub'),
            ProfilScreen(role: role)),
        tile(Icons.account_balance_wallet_outlined, tr('my_gains'),
            tr('my_gains_sub'), GainsScreen(role: role)),
        tile(Icons.history, tr('history'), tr('history_sub'),
            HistoriqueScreen(role: role)),
        tile(Icons.star_outline, tr('client_reviews'), tr('client_reviews_sub'),
            AvisScreen(role: role)),
        tile(Icons.tune, tr('settings'), tr('settings_sub'),
            const ReglagesScreen()),
        tile(Icons.support_agent, tr('help_support'), tr('help_support_sub'),
            const SupportScreen()),
      ],
    );
  }
}

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key, required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    final email = FirebaseAuth.instance.currentUser?.email ?? '—';

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
      appBar: AppBar(title: Text(tr('profile'))),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: FirestoreService.partnerStream(),
        builder: (context, snap) {
          final p = snap.data ?? const {};
          final rating = p['rating'];
          return ListView(
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
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => ProfileStore.pickFromGallery(),
                      icon: const Icon(Icons.upload),
                      label: Text(tr('change_photo')),
                    ),
                    Text('Mr ${proDisplayName()}',
                        style: TextStyle(
                            color: vc.onSurface,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                    Text(
                        role == 'Taxi'
                            ? tr('role_driver')
                            : tr('role_livreur'),
                        style: TextStyle(color: vc.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: vc.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: vc.line),
                ),
                child: Column(
                  children: [
                    info(Icons.email_outlined, tr('email'), email),
                    Divider(height: 1, color: vc.line),
                    info(Icons.badge_outlined, tr('status'),
                        tr('status_verified')),
                    Divider(height: 1, color: vc.line),
                    info(Icons.star, tr('note'),
                        rating != null ? '$rating ★' : '—'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await FirestoreService.setPartnerOnline(
                        role: role == 'Taxi' ? 'driver' : 'livreur',
                        online: false);
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: Text(tr('logout')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class GainsScreen extends StatelessWidget {
  const GainsScreen({super.key, required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    return Scaffold(
      appBar: AppBar(title: Text(tr('my_gains'))),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: FirestoreService.partnerStream(),
        builder: (context, snap) {
          final p = snap.data ?? const {};
          final today = (p['gainsToday'] ?? 0) as num;
          final week = (p['gainsWeek'] ?? 0) as num;
          final month = (p['gainsMonth'] ?? 0) as num;
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
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
                    Text(tr('today'),
                        style: TextStyle(color: vc.dim, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text('$today DJF',
                        style: TextStyle(
                            color: vc.primary,
                            fontSize: 30,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: ProStat(
                          label: tr('this_week'),
                          value: week.toInt(),
                          unit: 'DJF')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: ProStat(
                          label: tr('this_month'),
                          value: month.toInt(),
                          unit: 'DJF')),
                ],
              ),
              const SizedBox(height: 18),
              Text(tr('gains_update_note'),
                  style: TextStyle(color: vc.dim)),
            ],
          );
        },
      ),
    );
  }
}

class HistoriqueScreen extends StatelessWidget {
  const HistoriqueScreen({super.key, required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    final taxi = role == 'Taxi';
    return Scaffold(
      appBar: AppBar(title: Text(tr('history'))),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: taxi
            ? FirestoreService.completedRides()
            : FirestoreService.completedOrders(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data ?? const [];
          if (data.isEmpty) {
            return EmptyState(
              title: tr('no_mission'),
              subtitle: tr('no_mission_sub'),
              icon: Icons.history,
            );
          }
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              for (final m in data)
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
                        child: Text(
                          taxi
                              ? '${m['from'] ?? '?'} → ${m['to'] ?? '?'}'
                              : '${m['restaurantName'] ?? 'Restaurant'} → ${m['clientName'] ?? 'Client'}',
                          style: TextStyle(
                              color: vc.onSurface,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                          '${taxi ? (m['price'] ?? 0) : (m['total'] ?? 0)} DJF',
                          style: TextStyle(
                              color: vc.primary,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class ReglagesScreen extends StatefulWidget {
  const ReglagesScreen({super.key});
  @override
  State<ReglagesScreen> createState() => _ReglagesScreenState();
}

class _ReglagesScreenState extends State<ReglagesScreen> {
  bool _notifs = true;

  void _pickLanguage(BuildContext context) {
    final vc = context.vc;
    showModalBottomSheet(
      context: context,
      backgroundColor: vc.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(tr('choose_language'),
                  style: TextStyle(
                      color: vc.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ),
            for (final e in kLanguageNames.entries)
              ListTile(
                title: Text(e.value,
                    style: TextStyle(color: vc.onSurface)),
                trailing: localeNotifier.value == e.key
                    ? Icon(Icons.check, color: vc.primary)
                    : null,
                onTap: () {
                  localeNotifier.value = e.key;
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(tr('settings'))),
      body: ListView(
        children: [
          SwitchListTile(
            value: isDark,
            activeColor: vc.primary,
            secondary: Icon(Icons.dark_mode, color: vc.primary),
            title: Text(tr('dark_mode'),
                style: TextStyle(
                    color: vc.onSurface, fontWeight: FontWeight.w600)),
            onChanged: (v) =>
                themeModeNotifier.value = v ? ThemeMode.dark : ThemeMode.light,
          ),
          Divider(height: 1, color: vc.line),
          SwitchListTile(
            value: _notifs,
            activeColor: vc.primary,
            secondary:
                Icon(Icons.notifications_active_outlined, color: vc.primary),
            title: Text(tr('notifications'),
                style: TextStyle(
                    color: vc.onSurface, fontWeight: FontWeight.w600)),
            onChanged: (v) => setState(() => _notifs = v),
          ),
          Divider(height: 1, color: vc.line),
          ListTile(
            leading: Icon(Icons.language, color: vc.primary),
            title: Text(tr('language'),
                style: TextStyle(
                    color: vc.onSurface, fontWeight: FontWeight.w600)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(kLanguageNames[localeNotifier.value] ?? 'Français',
                    style: TextStyle(color: vc.dim)),
                Icon(Icons.chevron_right, color: vc.dim),
              ],
            ),
            onTap: () => _pickLanguage(context),
          ),
        ],
      ),
    );
  }
}

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
                    SnackBar(
                        content: Text(tr('copied')),
                        behavior: SnackBarBehavior.floating),
                  );
                },
              ),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(tr('help_support'))),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(tr('support_intro'),
              style: TextStyle(color: vc.dim, height: 1.4)),
          const SizedBox(height: 16),
          row(Icons.phone, tr('phone'), '+253 77 00 00 00'),
          row(Icons.chat, tr('whatsapp'), '+253 77 00 00 00'),
          row(Icons.email_outlined, tr('email'), 'support@velox.dj'),
          const SizedBox(height: 8),
          Text(tr('hours'),
              style: TextStyle(color: vc.dim)),
        ],
      ),
    );
  }
}

/// ─────────────────────────── GRAPHIQUES ────────────────────────────────────
class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart(
      {super.key,
      required this.values,
      this.labels = const ['L', 'M', 'M', 'J', 'V', 'S', 'D']});
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
              text: vc.dim),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter(
      {required this.values,
      required this.labels,
      required this.progress,
      required this.bar,
      required this.text});
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
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, chartH - h, barW, h), const Radius.circular(6)),
        paint,
      );
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

class DonutSeg {
  final String label;
  final double value;
  final Color color;
  const DonutSeg(this.label, this.value, this.color);
}

class DonutChart extends StatelessWidget {
  const DonutChart(
      {super.key,
      required this.segments,
      this.centerLabel = '',
      this.centerValue = ''});
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
          painter:
              _DonutPainter(segments: segments, progress: t, track: vc.line),
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
      canvas.drawArc(
        inner,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = seg.color,
      );
      start += (seg.value / total) * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.progress != progress;
}

Widget _chartPlaceholder(BuildContext context, String title) {
  final vc = context.vc;
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: vc.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: vc.line),
    ),
    child: Row(
      children: [
        Icon(Icons.insights, color: vc.dim),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: vc.onSurface, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(tr('no_data'),
                  style: TextStyle(color: vc.dim, fontSize: 12)),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Carte Performance : alimentée par les vraies données (sinon placeholder).
class PerformanceCard extends StatelessWidget {
  const PerformanceCard({super.key, this.weekly});
  final List<int>? weekly;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    final w = weekly;
    if (w == null || w.isEmpty || w.every((e) => e == 0)) {
      return _chartPlaceholder(context, tr('performance_7'));
    }
    final total = w.fold<int>(0, (s, e) => s + e);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => PerformanceDetailScreen(weekly: w)),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [vc.primary.withValues(alpha: 0.22), vc.surface],
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
                Text(tr('performance_7'),
                    style: TextStyle(
                        color: vc.onSurface, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('$total DJF',
                    style: TextStyle(
                        color: vc.primary, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 14),
            WeeklyBarChart(values: w),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(tr('see_more'),
                    style: TextStyle(
                        color: vc.primary, fontWeight: FontWeight.w700)),
                Icon(Icons.chevron_right, color: vc.primary, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RepartitionCard extends StatelessWidget {
  const RepartitionCard({super.key, this.segments});
  final List<DonutSeg>? segments;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    final segs = segments;
    if (segs == null || segs.isEmpty) {
      return _chartPlaceholder(context, tr('repartition'));
    }
    final done = segs.first.value.toInt();
    final tot = segs.fold<double>(0, (s, e) => s + e.value).toInt();
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => RepartitionDetailScreen(segments: segs)),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: vc.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: vc.line),
        ),
        child: Column(
          children: [
            Row(
              children: [
                DonutChart(
                    segments: segs,
                    centerValue: '$done/$tot',
                    centerLabel: tr('missions')),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('repartition'),
                          style: TextStyle(
                              color: vc.onSurface,
                              fontWeight: FontWeight.w800)),
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
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(tr('see_more'),
                    style: TextStyle(
                        color: vc.primary, fontWeight: FontWeight.w700)),
                Icon(Icons.chevron_right, color: vc.primary, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PerformanceDetailScreen extends StatelessWidget {
  const PerformanceDetailScreen({super.key, required this.weekly});
  final List<int> weekly;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    final total = weekly.fold<int>(0, (s, e) => s + e);
    final avg = (total / weekly.length).round();
    final best = weekly.reduce((a, b) => a > b ? a : b);
    Widget stat(String label, String value) => Expanded(
          child: Container(
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
                Text(value,
                    style: TextStyle(
                        color: vc.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Performance')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [vc.primary.withValues(alpha: 0.22), vc.surface],
              ),
              border: Border.all(color: vc.line),
            ),
            child: WeeklyBarChart(values: weekly),
          ),
          const SizedBox(height: 14),
          Row(children: [
            stat('Total', '$total DJF'),
            const SizedBox(width: 12),
            stat('Moyenne', '$avg DJF'),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            stat('Meilleur', '$best DJF'),
            const SizedBox(width: 12),
            stat('Jours', '${weekly.length}'),
          ]),
        ],
      ),
    );
  }
}

class RepartitionDetailScreen extends StatelessWidget {
  const RepartitionDetailScreen({super.key, required this.segments});
  final List<DonutSeg> segments;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    final tot = segments.fold<double>(0, (s, e) => s + e.value);
    final rate =
        tot == 0 ? 0 : ((segments.first.value / tot) * 100).round();
    return Scaffold(
      appBar: AppBar(title: Text(tr('repartition'))),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Center(
            child: DonutChart(
                segments: segments,
                centerValue: '$rate%',
                centerLabel: tr('success')),
          ),
          const SizedBox(height: 24),
          for (final s in segments)
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
                  Container(
                    width: 14,
                    height: 14,
                    decoration:
                        BoxDecoration(color: s.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(s.label,
                        style: TextStyle(
                            color: vc.onSurface,
                            fontWeight: FontWeight.w700)),
                  ),
                  Text(
                      '${s.value.toInt()} · ${tot == 0 ? 0 : ((s.value / tot) * 100).round()}%',
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
