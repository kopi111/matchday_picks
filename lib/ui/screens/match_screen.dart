import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/themes.dart';
import '../../data/study.dart';
import '../../model/picks.dart';
import '../../state/settings.dart';
import '../format.dart';
import '../widgets.dart';

/// Match detail: expected goals, the win/draw/win split, the three picks with prices and payouts,
/// the likely scores, and how strong picks have done in this league.
class MatchScreen extends StatelessWidget {
  const MatchScreen({super.key, required this.matchPicks});
  final MatchPicks matchPicks;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final study = context.read<Study>();
    final settings = context.watch<Settings>();
    final match = matchPicks.match;
    final league = study.leagues[match.league];
    final caution = matchPicks.picks.values
        .where((pick) => pick.disagreesWithBookmaker)
        .toList();

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.of(context).padding.top + 4,
          16,
          32,
        ),
        children: [
          // Back button.
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.chevron_left_rounded, color: p.muted),
              label: Text(
                'Back',
                style: TextStyle(color: p.muted, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          _Hero(
            matchPicks: matchPicks,
            leagueName:
                '${league?.country ?? ''} · ${league?.name ?? match.league}',
          ),
          const SizedBox(height: 10),
          for (final pick in caution)
            Notice(
              'Model is ${((pick.probability - pick.bookmakerFair!).abs() * 100).round()} points away from Bet365 on "${pick.label}". Gaps this big usually mean the model is missing team news (injuries, rotation), not that the bookmaker is wrong.',
              icon: Icons.warning_amber_rounded,
            ),
          // The three picks.
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardTitle('The three picks'),
                for (final (index, market) in Market.values.indexed) ...[
                  if (index > 0)
                    Divider(height: 22, color: p.line.withValues(alpha: 0.6)),
                  _PickBlock(
                    pick: matchPicks.picks[market]!,
                    stake: settings.stake,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Most likely scorelines.
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardTitle('Most likely scores'),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.9,
                  children: [
                    for (final score in matchPicks.scores)
                      Container(
                        decoration: BoxDecoration(
                          color: p.raised,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Mono('${score.home}-${score.away}', size: 17),
                            Text(
                              Format.percent(score.probability),
                              style: TextStyle(color: p.muted, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // League record from the study.
          if (league != null)
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _CardTitle('League record')),
                      leagueTag(league.tag),
                    ],
                  ),
                  Text(
                    'Strong picks in ${league.name} won ${Format.percent(league.hitRate)} of ${league.bets} over five seasons: '
                    '${Format.signedPercent(league.roiBet365)} at Bet365, ${Format.signedPercent(league.roiBest)} at the best price.',
                    style: TextStyle(color: p.muted, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          const Hint(
            'Expected goals come from the app\'s own model (team attack and defence ratings from three seasons of results), not provider xG. Line-ups and injuries are not in the free data.',
          ),
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
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
}

/// Top card: crests (initials), expected goals, and the home/draw/away split bar.
class _Hero extends StatelessWidget {
  const _Hero({required this.matchPicks, required this.leagueName});
  final MatchPicks matchPicks;
  final String leagueName;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final match = matchPicks.match;
    final result = matchPicks.result;
    Widget team(String name, double? xg, Color color) => Expanded(
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              _initials(name),
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: p.background,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: p.text,
            ),
          ),
          const SizedBox(height: 8),
          Mono(xg == null ? '–' : xg.toStringAsFixed(2), size: 26),
          Text(
            'expected goals',
            style: TextStyle(color: p.muted, fontSize: 11),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.line),
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.3,
          colors: [
            Color.alphaBlend(p.accent.withValues(alpha: 0.14), p.surface),
            p.surface,
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            '${leagueName.toUpperCase()} · ${Format.shortDay(match.kickoff).toUpperCase()} ${Format.time(match.kickoff)}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: p.muted,
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              team(match.home, matchPicks.expectedHome, p.accent),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'v',
                  style: TextStyle(color: p.faint, fontWeight: FontWeight.w600),
                ),
              ),
              team(match.away, matchPicks.expectedAway, p.cool),
            ],
          ),
          if (result.isNotEmpty) ...[
            const SizedBox(height: 14),
            // Home / draw / away as one split bar.
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 30,
                child: Row(
                  children: [
                    for (final (key, color) in [
                      ('home', p.accent),
                      ('draw', p.muted),
                      ('away', p.cool),
                    ])
                      Expanded(
                        flex: (result[key]! * 1000).round(),
                        child: Container(
                          color: color,
                          alignment: Alignment.center,
                          child: Mono(
                            Format.percent(result[key]!),
                            size: 12,
                            color: p.background,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Home',
                    style: TextStyle(color: p.muted, fontSize: 11),
                  ),
                ),
                Text('Draw', style: TextStyle(color: p.muted, fontSize: 11)),
                Expanded(
                  child: Text(
                    'Away',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: p.muted, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// "Galatasaray" -> "GA", "Paris SG" -> "PS".
  static String _initials(String name) {
    final words = name
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.length > 1) return (words[0][0] + words[1][0]).toUpperCase();
    return name.substring(0, name.length < 2 ? name.length : 2).toUpperCase();
  }
}

/// One pick: label, probability, why, and three price boxes (Bet365, best, what the stake pays).
class _PickBlock extends StatelessWidget {
  const _PickBlock({required this.pick, required this.stake});
  final Pick pick;
  final int stake;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final best = pick.price(useBest: true);
    Widget box(String label, String value, {bool accent = false}) => Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
        decoration: BoxDecoration(
          color: p.raised,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: p.muted,
                fontSize: 9.5,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
            Mono(value, size: 14, color: accent ? p.accent : p.text),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                pick.label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15.5,
                  color: p.text,
                ),
              ),
            ),
            Mono(
              Format.percent(pick.probability),
              size: 16,
              color: pick.isStrong ? p.accent : p.text,
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${pick.isStrong ? '★ Strong pick · ' : ''}similar picks won ${Format.percent(pick.band.hitRate)} of ${pick.band.bets} · fair odds ${pick.fairOdds.toStringAsFixed(2)}',
          style: TextStyle(color: p.muted, fontSize: 12.5),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            box('Bet365', Format.odds(pick.bet365)),
            const SizedBox(width: 6),
            box(
              'Best price',
              Format.odds(pick.best),
              accent: pick.best != null,
            ),
            const SizedBox(width: 6),
            box(
              '\$$stake pays',
              best == null ? '—' : Format.money(stake * best),
            ),
          ],
        ),
        if (pick.market == Market.btts)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'No BTTS prices in the free data: it needs odds above ${(1 / pick.band.hitRate).toStringAsFixed(2)} to break even.',
              style: TextStyle(color: p.muted, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
