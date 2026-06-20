import 'package:flutter/material.dart';
import 'theme/velox_theme.dart';
import 'auth_screen.dart';
import 'livreur/livreur_shell.dart';
import 'driver/driver_shell.dart';

/// Écran de lancement : deux boutons pour choisir le rôle, puis on entre dans
/// le flux correspondant (où se fera la vraie connexion Firebase).
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void _open(BuildContext context, Widget shell) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => shell));
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vc;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Se déconnecter',
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  ),
                  icon: Icon(Icons.logout, color: vc.dim),
                ),
              ),
              const Spacer(),
              Text(
                'VELOX',
                style: TextStyle(
                  color: vc.primary,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Comment voulez-vous vous connecter ?',
                style: TextStyle(color: vc.dim, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 44),

              // ── Livreur ──
              _RoleButton(
                icon: Icons.two_wheeler,
                label: 'LIVREUR',
                filled: true,
                onTap: () => _open(context, const LivreurShell()),
              ),
              const SizedBox(height: 16),

              // ── Taxi VTC ──
              _RoleButton(
                icon: Icons.local_taxi,
                label: 'TAXI VTC',
                filled: false,
                onTap: () => _open(context, const DriverShell()),
              ),

              const Spacer(),
              Text(
                'Vous pourrez changer de rôle en vous déconnectant.',
                style: TextStyle(color: vc.dim.withValues(alpha: 0.7), fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
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
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool filled;
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

    return Listener(
      onPointerDown: (_) => setState(() => _scale = 0.97),
      onPointerUp: (_) => setState(() => _scale = 1),
      onPointerCancel: (_) => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        child: SizedBox(
          width: double.infinity,
          height: 66,
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
              onTap: widget.onTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, color: fg),
                  const SizedBox(width: 12),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: fg,
                      fontSize: 17,
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
    );
  }
}
