import 'package:flutter/material.dart';

/// The five themes picked in Settings → Theme.
enum AppThemeKey { matchday, floodlight, reggae, stadium, paper }

extension AppThemeName on AppThemeKey {
  String get label => switch (this) {
    AppThemeKey.matchday => 'Matchday',
    AppThemeKey.floodlight => 'Floodlight',
    AppThemeKey.reggae => 'Reggae Boyz',
    AppThemeKey.stadium => 'Stadium',
    AppThemeKey.paper => 'Paper slip',
  };
}

/// Every colour the app uses. "accent" is kept for strong picks and money coming back.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.raised,
    required this.line,
    required this.text,
    required this.muted,
    required this.faint,
    required this.accent,
    required this.onAccent,
    required this.warning,
    required this.loss,
    required this.cool,
    required this.isDark,
  });

  final Color background,
      surface,
      raised,
      line,
      text,
      muted,
      faint,
      accent,
      onAccent,
      warning,
      loss,
      cool;
  final bool isDark;

  /// The palette for each theme (same values as the approved mock-up).
  static AppPalette of(AppThemeKey key) => switch (key) {
    AppThemeKey.matchday => const AppPalette(
      background: Color(0xFFF3F6F0),
      surface: Color(0xFFFFFFFF),
      raised: Color(0xFFEDF2E8),
      line: Color(0xFFDBE3D5),
      text: Color(0xFF13201A),
      muted: Color(0xFF5B6B61),
      faint: Color(0xFF93A199),
      accent: Color(0xFF1D8A3A),
      onAccent: Color(0xFFFFFFFF),
      warning: Color(0xFFB26A00),
      loss: Color(0xFFCC3F35),
      cool: Color(0xFF2B7BBF),
      isDark: false,
    ),
    AppThemeKey.floodlight => const AppPalette(
      background: Color(0xFF07100C),
      surface: Color(0xFF0E1A14),
      raised: Color(0xFF14241C),
      line: Color(0xFF1E3329),
      text: Color(0xFFE8F1EB),
      muted: Color(0xFF8AA196),
      faint: Color(0xFF5D7268),
      accent: Color(0xFFC8F25A),
      onAccent: Color(0xFF10200A),
      warning: Color(0xFFF2B24A),
      loss: Color(0xFFF26B5B),
      cool: Color(0xFF74C4F0),
      isDark: true,
    ),
    AppThemeKey.reggae => const AppPalette(
      background: Color(0xFF0C0C09),
      surface: Color(0xFF17160E),
      raised: Color(0xFF222013),
      line: Color(0xFF34311D),
      text: Color(0xFFFBF6DF),
      muted: Color(0xFFB6AE88),
      faint: Color(0xFF7D775B),
      accent: Color(0xFFFED100),
      onAccent: Color(0xFF1B1600),
      warning: Color(0xFFFF9F1C),
      loss: Color(0xFFFF5A4E),
      cool: Color(0xFF22B14C),
      isDark: true,
    ),
    AppThemeKey.stadium => const AppPalette(
      background: Color(0xFF0A1224),
      surface: Color(0xFF101B33),
      raised: Color(0xFF17254A),
      line: Color(0xFF233357),
      text: Color(0xFFEAF0FF),
      muted: Color(0xFF93A3C6),
      faint: Color(0xFF62729A),
      accent: Color(0xFF5CE1E6),
      onAccent: Color(0xFF04161A),
      warning: Color(0xFFFFC15E),
      loss: Color(0xFFFF6B81),
      cool: Color(0xFF8FA8FF),
      isDark: true,
    ),
    AppThemeKey.paper => const AppPalette(
      background: Color(0xFFF5EEDF),
      surface: Color(0xFFFFFAF0),
      raised: Color(0xFFF0E6D2),
      line: Color(0xFFE1D4BB),
      text: Color(0xFF2A2118),
      muted: Color(0xFF786853),
      faint: Color(0xFFA6967C),
      accent: Color(0xFFC2410C),
      onAccent: Color(0xFFFFFFFF),
      warning: Color(0xFF9A5B00),
      loss: Color(0xFFB91C1C),
      cool: Color(0xFF1D4ED8),
      isDark: false,
    ),
  };

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) =>
      t < 0.5 || other == null ? this : other;
}

/// Font families bundled in assets/fonts (see pubspec.yaml).
class AppFonts {
  static const display = 'Bricolage';
  static const body = 'Inter';
  static const mono = 'JetBrainsMono';
}

/// Builds the Material theme for a palette, with the app's fonts and rounded cards.
ThemeData buildTheme(AppThemeKey key) {
  final p = AppPalette.of(key);
  final base = ThemeData(
    useMaterial3: true,
    brightness: p.isDark ? Brightness.dark : Brightness.light,
    fontFamily: AppFonts.body,
    scaffoldBackgroundColor: p.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: p.accent,
      brightness: p.isDark ? Brightness.dark : Brightness.light,
      surface: p.surface,
      primary: p.accent,
      onPrimary: p.onAccent,
    ),
  );
  return base.copyWith(
    extensions: [p],
    textTheme: base.textTheme.apply(
      bodyColor: p.text,
      displayColor: p.text,
      fontFamily: AppFonts.body,
    ),
    dividerColor: p.line,
    splashFactory: InkSparkle.splashFactory,
  );
}

/// Shortcut: `context.palette.accent`.
extension PaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
