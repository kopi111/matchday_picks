import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/themes.dart';
import '../../data/study.dart';
import '../../state/settings.dart';
import '../format.dart';
import '../widgets.dart';
import 'settings_sheet.dart';
import 'today_screen.dart';

/// Learn: an "is this bet worth it?" calculator, the league table, and the study's five rules.
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  double _chance = 0.67;
  double _odds = 1.50;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final study = context.read<Study>();
    final stake = context.watch<Settings>().stake;

    // Expected value of one bet: chance × odds − 1.
    final ev = _chance * _odds - 1;
    final leagues = study.leagues.values.toList()
      ..sort((a, b) => b.roiBet365.compareTo(a.roiBet365));

    return ScreenScaffold(
      children: [
        AppHeader(
          eyebrow: 'How the picks work',
          title: 'Learn',
          onSettings: () => showSettingsSheet(context),
        ),
        // Calculator.
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title(context, 'Is this bet worth it?'),
              _sliderLabel(context, 'Chance it wins', Format.percent(_chance)),
              Slider(
                value: _chance,
                min: 0.2,
                max: 0.9,
                divisions: 70,
                activeColor: p.accent,
                inactiveColor: p.line,
                onChanged: (v) => setState(() => _chance = v),
              ),
              _sliderLabel(context, 'Bookmaker odds', _odds.toStringAsFixed(2)),
              Slider(
                value: _odds,
                min: 1.1,
                max: 4.0,
                divisions: 290,
                activeColor: p.accent,
                inactiveColor: p.line,
                onChanged: (v) => setState(() => _odds = v),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Mono(
                    Format.signedPercent(ev),
                    size: 30,
                    color: ev >= 0 ? p.accent : p.loss,
                  ),
                  Text('  per bet', style: TextStyle(color: p.muted)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Break-even odds for a ${Format.percent(_chance)} chance: ${(1 / _chance).toStringAsFixed(2)}. '
                '\$$stake returns ${Format.money(stake * ev)} on average per bet.',
                style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.4),
              ),
              const SizedBox(height: 6),
              Text(
                'Tip: use the "similar picks won" figure from a pick as the chance, not the model\'s own number.',
                style: TextStyle(color: p.faint, fontSize: 12),
              ),
            ],
          ),
        ),
        // League table.
        const SectionTitle(
          'Which leagues pay',
          note: 'strong picks, five seasons',
        ),
        Panel(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _head(context, 'League')),
                  SizedBox(
                    width: 62,
                    child: _head(context, 'Bet365', right: true),
                  ),
                  SizedBox(
                    width: 62,
                    child: _head(context, 'Best', right: true),
                  ),
                  const SizedBox(width: 76),
                ],
              ),
              for (final league in leagues)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              league.name,
                              style: TextStyle(color: p.text, fontSize: 13.5),
                            ),
                            Text(
                              league.country,
                              style: TextStyle(color: p.muted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 62,
                        child: _pct(context, league.roiBet365),
                      ),
                      SizedBox(width: 62, child: _pct(context, league.roiBest)),
                      SizedBox(
                        width: 76,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Tag(
                            {'good': 'Good', 'weak': 'Weak'}[league.tag] ??
                                'Average',
                            tone: league.isGood
                                ? TagTone.good
                                : league.isWeak
                                ? TagTone.weak
                                : TagTone.plain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // The five rules.
        const SectionTitle('Five rules from the study'),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (index, rule) in const [
                (
                  'Take the best price',
                  'It turns about −2.6% per bet into roughly even. Compare bookmakers before you bet.',
                ),
                (
                  'Strong picks only',
                  'Picks that historically won 60%+ (marked ★).',
                ),
                (
                  'Singles up to trebles',
                  'Five-match tickets lost about 5–17%, ten-match tickets 24–34%.',
                ),
                (
                  'Mind the league',
                  'La Liga, Belgium, Turkey and Portugal held up; Serie A/B, Ligue 1/2 and the Eredivisie did not.',
                ),
                (
                  'Same stake, keep a record',
                  'Even good strategies finished fewer than half of weekends in profit.',
                ),
              ].indexed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: p.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Mono('${index + 1}', size: 13, color: p.accent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rule.$1,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: p.text,
                              ),
                            ),
                            Text(
                              rule.$2,
                              style: TextStyle(
                                color: p.muted,
                                fontSize: 12.5,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Hint(
          'Based on ${study.matches} matches in 21 leagues, every prediction made only with matches played before it. No pick is a sure thing; never bet more than you can afford to lose.',
        ),
      ],
    );
  }

  Widget _title(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(
        fontFamily: AppFonts.display,
        fontWeight: FontWeight.w700,
        fontSize: 16,
        color: context.palette.text,
      ),
    ),
  );

  Widget _sliderLabel(BuildContext context, String label, String value) =>
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(color: context.palette.muted, fontSize: 13),
            ),
            const Spacer(),
            Mono(value, size: 14),
          ],
        ),
      );

  Widget _head(BuildContext context, String text, {bool right = false}) => Text(
    text.toUpperCase(),
    textAlign: right ? TextAlign.right : TextAlign.left,
    style: TextStyle(
      color: context.palette.muted,
      fontSize: 10.5,
      letterSpacing: 0.8,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _pct(BuildContext context, double value) => Text(
    Format.signedPercent(value),
    textAlign: TextAlign.right,
    style: TextStyle(
      fontFamily: AppFonts.mono,
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: value >= 0 ? context.palette.accent : context.palette.loss,
    ),
  );
}
