import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'theme/velox_theme.dart';
import 'role_selection_screen.dart';

/// Écran de connexion. Après authentification réussie, on redirige vers
/// l'écran de choix de rôle (Livreur / Taxi VTC).
///
/// L'auth est ici SIMULÉE (validation des champs non vides). Branche Firebase
/// Auth à l'endroit indiqué dans `_signIn`.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      // Connecté → on va au choix de rôle.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      );
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
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
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
                const SizedBox(height: 8),
                Text(
                  'VELOX',
                  style: TextStyle(
                    color: vc.primary,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Connexion espace pro',
                    style: TextStyle(color: vc.dim, fontSize: 15)),
                const SizedBox(height: 32),

                _GlowField(
                  controller: _email,
                  hint: 'Adresse email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Email invalide' : null,
                  enabled: !_loading,
                ),
                const SizedBox(height: 16),
                _GlowField(
                  controller: _password,
                  hint: 'Mot de passe',
                  obscure: _obscure,
                  validator: (v) =>
                      (v == null || v.length < 4) ? '4 caractères minimum' : null,
                  enabled: !_loading,
                  suffix: GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (c, a) =>
                          ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: c)),
                      child: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        key: ValueKey(_obscure),
                        color: vc.dim,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: _loading ? null : _signIn,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('SE CONNECTER',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(child: Divider(color: vc.line)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('ou', style: TextStyle(color: vc.dim)),
                    ),
                    Expanded(child: Divider(color: vc.line)),
                  ],
                ),
                const SizedBox(height: 20),

                OutlinedButton.icon(
                  onPressed: _loading
                      ? null
                      : () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Connexion par téléphone (OTP) à brancher.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          ),
                  icon: const Icon(Icons.phone_android),
                  label: const Text('Se connecter avec Téléphone'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
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
    this.keyboardType,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final bool obscure;
  final Widget? suffix;
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
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
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
            borderRadius: BorderRadius.circular(12),
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
          suffixIcon: widget.suffix,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
