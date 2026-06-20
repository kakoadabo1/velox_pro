import 'package:flutter/material.dart';

/// Palette VELOX exposée comme ThemeExtension : noir + vert en sombre,
/// blanc + vert en clair. Accès via `context.vc`.
@immutable
class VeloxColors extends ThemeExtension<VeloxColors> {
  final Color bg;
  final Color surface;
  final Color line;
  final Color primary;
  final Color onPrimary;
  final Color onSurface;
  final Color dim;

  const VeloxColors({
    required this.bg,
    required this.surface,
    required this.line,
    required this.primary,
    required this.onPrimary,
    required this.onSurface,
    required this.dim,
  });

  static const dark = VeloxColors(
    bg: Color(0xFF0E0E0E),
    surface: Color(0xFF161616),
    line: Color(0xFF2A2A2A),
    primary: Color(0xFF9FFF88),
    onPrimary: Color(0xFF063D00),
    onSurface: Color(0xFFFFFFFF),
    dim: Color(0xFFADAAAB),
  );

  static const light = VeloxColors(
    bg: Color(0xFFF5F5F5),
    surface: Color(0xFFFFFFFF),
    line: Color(0xFFE3E3E3),
    primary: Color(0xFF12AD2B),
    onPrimary: Color(0xFFFFFFFF),
    onSurface: Color(0xFF0E0E0E),
    dim: Color(0xFF6B6B6B),
  );

  @override
  VeloxColors copyWith({
    Color? bg,
    Color? surface,
    Color? line,
    Color? primary,
    Color? onPrimary,
    Color? onSurface,
    Color? dim,
  }) {
    return VeloxColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      line: line ?? this.line,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      onSurface: onSurface ?? this.onSurface,
      dim: dim ?? this.dim,
    );
  }

  @override
  VeloxColors lerp(ThemeExtension<VeloxColors>? other, double t) {
    if (other is! VeloxColors) return this;
    return VeloxColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      line: Color.lerp(line, other.line, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      dim: Color.lerp(dim, other.dim, t)!,
    );
  }
}

extension VeloxThemeX on BuildContext {
  VeloxColors get vc => Theme.of(this).extension<VeloxColors>()!;
}

ThemeData veloxTheme(Brightness brightness) {
  final vc = brightness == Brightness.dark ? VeloxColors.dark : VeloxColors.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: vc.primary,
    brightness: brightness,
  ).copyWith(
    primary: vc.primary,
    onPrimary: vc.onPrimary,
    surface: vc.surface,
    onSurface: vc.onSurface,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: vc.bg,
    colorScheme: scheme,
    extensions: const [],
    appBarTheme: AppBarTheme(
      backgroundColor: vc.bg,
      foregroundColor: vc.onSurface,
      elevation: 0,
      centerTitle: true,
    ),
  ).copyWith(extensions: [vc]);
}
