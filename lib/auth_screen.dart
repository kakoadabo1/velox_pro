import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'theme/velox_theme.dart';
import 'i18n/app_lang.dart';
import 'services/firestore_service.dart';
import 'livreur/livreur_shell.dart';
import 'driver/driver_shell.dart';

/// Page de connexion VELOX : logo animé + email/mot de passe, et en bas les
/// deux boutons de rôle (Livreur / Taxi VTC). Taper un bouton connecte ET
/// redirige vers la page du rôle choisi.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  String? _loadingRole; // 'livreur' | 'driver' | null

  late final AnimationController _intro;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..forward();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signInAs(String role) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loadingRole = role);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      // Vérification SERVEUR du rôle : le compte doit être un partenaire
      // approuvé pour ce rôle (doc partners/{uid} contrôlé par l'admin).
      final allowed = await FirestoreService.hasRole(role);
      if (!allowed) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(tr('role_denied')),
                behavior: SnackBarBehavior.floating),
          );
        }
        return;
      }
      if (!mounted) return;
      final Widget shell =
          role == 'livreur' ? const LivreurShell() : const DriverShell();
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => shell));
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'invalid-email' => 'Adresse email invalide.',
        'user-disabled' => 'Ce compte a été désactivé.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'Email ou mot de passe incorrect.',
        'too-many-requests' => 'Trop de tentatives. Réessayez plus tard.',
        'network-request-failed' => 'Pas de connexion internet.',
        _ => 'Échec de la connexion (${e.code}).',
      };
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Une erreur est survenue.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingRole = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final busy = _loadingRole != null;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => themeModeNotifier.value =
                        isDark ? ThemeMode.light : ThemeMode.dark,
                    icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                        color: vc.dim),
                  ),
                ),

                // ── Logo animé ──
                _Appear(
                  controller: _intro,
                  start: 0.0,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, child) {
                        final t = _pulse.value;
                        return Container(
                          width: 132,
                          height: 132,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: vc.primary.withValues(alpha: 0.25 + 0.2 * t),
                                blurRadius: 24 + 16 * t,
                                spreadRadius: 1 + 2 * t,
                              ),
                            ],
                          ),
                          child: child,
                        );
                      },
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo.png',
                          width: 132,
                          height: 132,
                          fit: BoxFit.cover,
                          // Repli si le logo n'est pas encore ajouté.
                          errorBuilder: (context, error, stack) => Container(
                            width: 132,
                            height: 132,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: vc.surface,
                              border: Border.all(color: vc.primary, width: 3),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'V',
                              style: TextStyle(
                                color: vc.primary,
                                fontSize: 64,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _Appear(
                  controller: _intro,
                  start: 0.1,
                  child: Text(
                    'VELOX',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: vc.primary,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                _Appear(
                  controller: _intro,
                  start: 0.16,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      children: [
                        Text(
                          tr('login_welcome'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: vc.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tr('login_sub'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: vc.dim, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                _Appear(
                  controller: _intro,
                  start: 0.24,
                  child: _GlowField(
                    controller: _email,
                    hint: tr('email_hint'),
                    prefixIcon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Email invalide'
                        : null,
                    enabled: !busy,
                  ),
                ),
                const SizedBox(height: 16),
                _Appear(
                  controller: _intro,
                  start: 0.3,
                  child: _GlowField(
                    controller: _password,
                    hint: tr('password_hint'),
                    prefixIcon: Icons.lock_outline,
                    obscure: _obscure,
                    validator: (v) => (v == null || v.length < 4)
                        ? '4 caractères minimum'
                        : null,
                    enabled: !busy,
                    suffix: GestureDetector(
                      onTap: () => setState(() => _obscure = !_obscure),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (c, a) => ScaleTransition(
                            scale: a,
                            child: FadeTransition(opacity: a, child: c)),
                        child: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          key: ValueKey(_obscure),
                          color: vc.dim,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                _Appear(
                  controller: _intro,
                  start: 0.38,
                  child: Text(
                    tr('connect_as'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: vc.dim,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 14),

                // ── 2 boutons de rôle (connexion + redirection) ──
                _Appear(
                  controller: _intro,
                  start: 0.44,
                  child: _RoleButton(
                    icon: Icons.two_wheeler,
                    label: tr('btn_livreur'),
                    filled: true,
                    loading: _loadingRole == 'livreur',
                    enabled: !busy,
                    onTap: () => _signInAs('livreur'),
                  ),
                ),
                const SizedBox(height: 14),
                _Appear(
                  controller: _intro,
                  start: 0.5,
                  child: _RoleButton(
                    icon: Icons.local_taxi,
                    label: tr('btn_taxi'),
                    filled: false,
                    loading: _loadingRole == 'driver',
                    enabled: !busy,
                    onTap: () => _signInAs('driver'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatefulWidget {
  const _RoleButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_RoleButton> createState() => _RoleButtonState();
}

class _RoleButtonState extends State<_RoleButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    final fg = widget.filled ? vc.onPrimary : vc.primary;
    final active = widget.enabled && !widget.loading;

    return Listener(
      onPointerDown: active ? (_) => setState(() => _scale = 0.97) : null,
      onPointerUp: (_) => setState(() => _scale = 1),
      onPointerCancel: (_) => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        child: SizedBox(
          height: 60,
          child: Material(
            color: widget.filled ? vc.primary : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: widget.filled
                  ? BorderSide.none
                  : BorderSide(color: vc.primary, width: 1.5),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: active ? widget.onTap : null,
              child: Center(
                child: widget.loading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: fg),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(widget.icon, color: fg),
                          const SizedBox(width: 12),
                          Text(
                            widget.label,
                            style: TextStyle(
                              color: fg,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Apparition en cascade (fondu + glissé).
class _Appear extends StatelessWidget {
  const _Appear(
      {required this.controller, required this.start, required this.child});
  final AnimationController controller;
  final double start;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final end = (start + 0.5).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
        parent: controller, curve: Interval(start, end, curve: Curves.easeOut));
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
            offset: Offset(0, 18 * (1 - anim.value)), child: child),
      ),
      child: child,
    );
  }
}

/// Champ avec bordure qui s'illumine en vert au focus.
class _GlowField extends StatefulWidget {
  const _GlowField({
    required this.controller,
    required this.hint,
    this.validator,
    this.obscure = false,
    this.suffix,
    this.prefixIcon,
    this.keyboardType,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final bool obscure;
  final Widget? suffix;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final bool enabled;

  @override
  State<_GlowField> createState() => _GlowFieldState();
}

class _GlowFieldState extends State<_GlowField>
    with SingleTickerProviderStateMixin {
  late final FocusNode _node;
  late final AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _node = FocusNode()..addListener(_onFocus);
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
  }

  void _onFocus() => _node.hasFocus ? _ac.forward() : _ac.reverse();

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _node.dispose();
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    return AnimatedBuilder(
      animation: _ac,
      builder: (context, child) {
        final t = _ac.value;
        return Container(
          decoration: BoxDecoration(
            color: vc.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Color.lerp(vc.line, vc.primary, t)!,
              width: 1.2 + t * 0.6,
            ),
            boxShadow: [
              BoxShadow(
                color: vc.primary.withValues(alpha: 0.25 * t),
                blurRadius: 14 * t,
                spreadRadius: t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: TextFormField(
        controller: widget.controller,
        focusNode: _node,
        validator: widget.validator,
        obscureText: widget.obscure,
        keyboardType: widget.keyboardType,
        enabled: widget.enabled,
        style: TextStyle(color: vc.onSurface),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(color: vc.dim),
          prefixIcon: widget.prefixIcon == null
              ? null
              : Icon(widget.prefixIcon, color: vc.dim),
          suffixIcon: widget.suffix,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
