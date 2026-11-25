import 'package:flutter/material.dart';

import '../app/themes.dart';

/// Screen header: small uppercase line, big title with one word in the accent colour, settings button.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.accentWord,
    this.onSettings,
  });

  final String eyebrow;
  final String title;
  final String? accentWord;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Stack(
      children: [
        // Faint centre-circle pitch marking behind the title.
        Positioned(
          right: -70,
          top: -80,
          child: IgnorePointer(
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: p.accent.withValues(alpha: 0.10),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 8, 2, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      style: TextStyle(
                        color: p.muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: title),
                          if (accentWord != null)
                            TextSpan(
                              text: ' $accentWord',
                              style: TextStyle(color: p.accent),
                            ),
                        ],
                      ),
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w800,
                        fontSize: 30,
                        height: 1.05,
                        letterSpacing: -0.7,
                        color: p.text,
                      ),
                    ),
                  ],
                ),
              ),
              if (onSettings != null)
                IconButtonBox(
                  icon: Icons.tune_rounded,
                  tooltip: 'Settings',
                  onTap: onSettings!,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A square outlined icon button that matches the cards.
class IconButtonBox extends StatelessWidget {
  const IconButtonBox({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
          side: BorderSide(color: p.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, size: 20, color: p.text),
          ),
        ),
      ),
    );
  }
}

/// Section heading with a note on the right.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.note});
  final String title;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 20, 2, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 17.5,
                color: p.text,
              ),
            ),
          ),
          if (note != null)
            Text(note!, style: TextStyle(color: p.muted, fontSize: 12.5)),
        ],
      ),
    );
  }
}

/// Kinds of small rounded tags.
enum TagTone { strong, good, weak, warn, plain }

/// A small rounded label, e.g. "★ similar picks won 67%" or "Good league".
class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.tone = TagTone.plain});
  final String text;
  final TagTone tone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = switch (tone) {
      TagTone.strong || TagTone.good => p.accent,
      TagTone.weak => p.loss,
      TagTone.warn => p.warning,
      TagTone.plain => p.muted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone == TagTone.strong ? p.accent.withValues(alpha: 0.12) : null,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: tone == TagTone.plain ? p.line : color.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// The league tag from the five-season study.
Tag leagueTag(String? tag) => switch (tag) {
  'good' => const Tag('Good league', tone: TagTone.good),
  'weak' => const Tag('Weak league', tone: TagTone.weak),
  _ => const Tag('Average league'),
};

/// A rounded card with the theme's surface and outline.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.highlight = false,
  });
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: highlight ? p.accent.withValues(alpha: 0.5) : p.line,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// A thin bar showing a probability.
class ProbabilityBar extends StatelessWidget {
  const ProbabilityBar(this.value, {super.key, this.strong = false});
  final double value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 4,
        backgroundColor: p.line,
        color: strong ? p.accent : p.muted,
      ),
    );
  }
}

/// Dashed tear line with half-circle notches, like a betting slip.
class PerforatedDivider extends StatelessWidget {
  const PerforatedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: 16,
      child: CustomPaint(
        painter: _PerforationPainter(line: p.line, notch: p.background),
        size: const Size(double.infinity, 16),
      ),
    );
  }
}

class _PerforationPainter extends CustomPainter {
  _PerforationPainter({required this.line, required this.notch});
  final Color line;
  final Color notch;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    // Dashes across the middle.
    final dash = Paint()
      ..color = line
      ..strokeWidth = 2;
    for (var x = 16.0; x < size.width - 16; x += 10) {
      canvas.drawLine(Offset(x, y), Offset(x + 5, y), dash);
    }
    // Half-circle notches cut into each side.
    final fill = Paint()..color = notch;
    final edge = Paint()
      ..color = line
      ..style = PaintingStyle.stroke;
    for (final cx in [0.0, size.width]) {
      canvas.drawCircle(Offset(cx, y), 8, fill);
      canvas.drawCircle(Offset(cx, y), 8, edge);
    }
  }

  @override
  bool shouldRepaint(covariant _PerforationPainter old) =>
      old.line != line || old.notch != notch;
}

/// A dashed-outline box for "nothing here" messages.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.sports_soccer_rounded,
  });
  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.line),
      ),
      child: Column(
        children: [
          Icon(icon, color: p.faint, size: 30),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: p.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Amber notice, e.g. when showing the saved copy offline.
class Notice extends StatelessWidget {
  const Notice(this.text, {super.key, this.icon = Icons.info_outline_rounded});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: p.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: p.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: p.warning, fontSize: 12.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

/// Monospace text for odds and money, so digits line up.
class Mono extends StatelessWidget {
  const Mono(
    this.text, {
    super.key,
    this.size = 14,
    this.color,
    this.weight = FontWeight.w700,
  });
  final String text;
  final double size;
  final Color? color;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontFamily: AppFonts.mono,
      fontSize: size,
      fontWeight: weight,
      color: color ?? context.palette.text,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
  );
}

/// Small grey helper text.
class Hint extends StatelessWidget {
  const Hint(
    this.text, {
    super.key,
    this.padding = const EdgeInsets.fromLTRB(2, 10, 2, 0),
  });
  final String text;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Text(
      text,
      style: TextStyle(
        color: context.palette.muted,
        fontSize: 12.5,
        height: 1.4,
      ),
    ),
  );
}
