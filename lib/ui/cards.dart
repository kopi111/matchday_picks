import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/themes.dart';
import '../data/study.dart';
import '../model/picks.dart';
import '../state/settings.dart';
import 'format.dart';
import 'screens/match_screen.dart';
import 'widgets.dart';

/// Opens the match detail screen with a slide-up transition.
void openMatch(BuildContext context, MatchPicks matchPicks) {
  Navigator.of(context).push(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, _, _) => MatchScreen(matchPicks: matchPicks),
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

/// A written ticket styled like a betting slip: total payout on top, each selection with its own single payout.
class TicketCard extends StatelessWidget {
  const TicketCard({super.key, required this.number, required this.legs});
  final int number;
  final List<TicketLeg> legs;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final settings = context.watch<Settings>();
    final study = context.read<Study>();
    final useBest = settings.useBestPrice;

    // Combined odds multiply; the chance multiplies how often similar picks really won.
    final odds = legs.fold<double>(
      1,
      (total, leg) => total * leg.pick.price(useBest: useBest)!,
    );
    final chance = legs.fold<double>(
      1,
      (total, leg) => total * leg.pick.band.hitRate,
    );
    final kind = switch (legs.length) {
      1 => 'Single',
      2 => 'Double',
      3 => 'Treble',
      _ => '${legs.length}-match ticket',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.line),
      ),
      child: Column(
        children: [
          // Top: ticket name and what the stake pays if every selection wins.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ticket $number · $kind',
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: p.text,
                        ),
                      ),
                      Text(
                        '${legs.length} selection${legs.length > 1 ? 's' : ''} · odds ${odds.toStringAsFixed(2)}',
                        style: TextStyle(color: p.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Mono(
                      Format.money(settings.stake * odds),
                      size: 22,
                      color: p.accent,
                    ),
                    Text(
                      '\$${settings.stake} pays',
                      style: TextStyle(color: p.muted, fontSize: 11.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const PerforatedDivider(),
          // Each selection: what it is, its price, and what it pays on its own.
          for (final (index, leg) in legs.indexed) ...[
            if (index > 0)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: p.line.withValues(alpha: 0.6),
              ),
            _LegRow(
              leg: leg,
              stake: settings.stake,
              useBest: useBest,
              league: study.leagues[leg.matchPicks.match.league],
            ),
          ],
          const PerforatedDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Chance all win',
                    style: TextStyle(color: p.muted, fontSize: 12.5),
                  ),
                ),
                Mono(Format.percent(chance), size: 13.5),
                if (chance < 0.5)
                  Text(
                    '  · about 1 in ${(1 / chance).round()}',
                    style: TextStyle(color: p.muted, fontSize: 12.5),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegRow extends StatelessWidget {
  const _LegRow({
    required this.leg,
    required this.stake,
    required this.useBest,
    required this.league,
  });
  final TicketLeg leg;
  final int stake;
  final bool useBest;
  final LeagueRecord? league;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final match = leg.matchPicks.match;
    final price = leg.pick.price(useBest: useBest)!;
    return InkWell(
      onTap: () => openMatch(context, leg.matchPicks),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leg.pick.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: p.text,
                        ),
                      ),
                      Text(
                        '${match.home} v ${match.away} · ${Format.time(match.kickoff)}',
                        style: TextStyle(color: p.muted, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Mono(Format.odds(price), size: 16),
                    Mono(
                      '${Format.money(stake * price)} single',
                      size: 11,
                      color: p.muted,
                      weight: FontWeight.w500,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Tag(
                  '★ similar picks won ${Format.percent(leg.pick.band.hitRate)}',
                  tone: TagTone.strong,
                ),
                if (league != null)
                  Tag(
                    league!.name,
                    tone: league!.isGood ? TagTone.good : TagTone.plain,
                  ),
                Tag('model ${Format.percent(leg.pick.probability)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A match with its three picks as pills; strong picks glow in the accent colour.
class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.matchPicks});
  final MatchPicks matchPicks;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final study = context.read<Study>();
    final match = matchPicks.match;
    final league = study.leagues[match.league];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Panel(
        onTap: matchPicks.picks.isEmpty
            ? null
            : () => openMatch(context, matchPicks),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${Format.time(match.kickoff)} · ${league?.country ?? ''} · ${league?.name ?? match.league}',
                    style: TextStyle(color: p.muted, fontSize: 12),
                  ),
                ),
                leagueTag(league?.tag),
              ],
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: match.home),
                  TextSpan(
                    text: '  v  ',
                    style: TextStyle(
                      color: p.faint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(text: match.away),
                ],
              ),
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 16.5,
                color: p.text,
              ),
            ),
            const SizedBox(height: 10),
            if (matchPicks.error != null || !matchPicks.covered)
              Text(
                matchPicks.error != null
                    ? 'No model for this league yet.'
                    : 'Not enough evidence: one team has too few league matches (often a promoted side).',
                style: TextStyle(color: p.muted, fontSize: 12.5),
              )
            else
              Row(
                children: [
                  for (final market in Market.values) ...[
                    if (market != Market.result) const SizedBox(width: 6),
                    Expanded(child: PickPill(pick: matchPicks.picks[market]!)),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// One market's pick in a small tile: market name, choice, probability, bar.
class PickPill extends StatelessWidget {
  const PickPill({super.key, required this.pick});
  final Pick pick;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final strong = pick.isStrong;
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
      decoration: BoxDecoration(
        color: strong ? p.accent.withValues(alpha: 0.10) : p.raised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: strong ? p.accent.withValues(alpha: 0.45) : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${pick.market.short}${strong ? ' ★' : ''}',
            style: TextStyle(
              color: p.muted,
              fontSize: 10.5,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            pick.shortLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: p.text,
            ),
          ),
          Mono(
            Format.percent(pick.probability),
            size: 13.5,
            color: strong ? p.accent : p.text,
          ),
          const SizedBox(height: 5),
          ProbabilityBar(pick.probability, strong: strong),
        ],
      ),
    );
  }
}
