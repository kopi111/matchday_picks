import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/themes.dart';
import '../../data/study.dart';
import '../../state/picks_repository.dart';
import '../../state/settings.dart';
import '../format.dart';
import '../widgets.dart';
import 'settings_sheet.dart';
import 'today_screen.dart';

/// Record: how this week's strong picks did, the five-season singles-versus-tickets results,
/// and the last weekend that was checked by hand.
class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final repo = context.watch<PicksRepository>();
    final study = context.read<Study>();
    final settings = context.watch<Settings>();

    // This week's strong picks that have a final score.
    final strong = repo.settled.where((s) => s.pick.isStrong).toList()
      ..sort(
        (a, b) =>
            b.matchPicks.match.kickoff.compareTo(a.matchPicks.match.kickoff),
      );
    final won = strong.where((s) => s.won).length;
    final priced = strong
        .where((s) => s.pick.price(useBest: settings.useBestPrice) != null)
        .toList();
    final profit = priced.fold<double>(
      0,
      (sum, s) =>
          sum +
          (s.won
              ? settings.stake *
                    (s.pick.price(useBest: settings.useBestPrice)! - 1)
              : -settings.stake.toDouble()),
    );

    return ScreenScaffold(
      onRefresh: () => repo.load(force: true),
      children: [
        AppHeader(
          eyebrow: 'How the picks did',
          title: 'Record',
          onSettings: () => showSettingsSheet(context),
        ),
        ...statusWidgets(context, repo),
        // This week so far.
        const SectionTitle('This week so far'),
        if (strong.isEmpty)
          EmptyState(
            title: 'Nothing settled yet',
            message: repo.awaitingResults > 0
                ? '${repo.awaitingResults} played matches are waiting for football-data.co.uk to post the scores (usually a day or two).'
                : 'Strong picks are settled here once their matches are played.',
            icon: Icons.hourglass_bottom_rounded,
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Strong picks won',
                  value: '$won / ${strong.length}',
                  note: Format.percent(won / strong.length),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Stat(
                  label: '\$${settings.stake} singles',
                  value: Format.money(profit),
                  color: profit >= 0 ? p.accent : p.loss,
                  note: '${priced.length} priced picks',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              children: [
                for (final s in strong.take(30))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          s.won
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          size: 20,
                          color: s.won ? p.accent : p.loss,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.pick.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: p.text,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${s.matchPicks.match.home} v ${s.matchPicks.match.away} · ${Format.shortDay(s.matchPicks.match.kickoff)}',
                                style: TextStyle(color: p.muted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Mono(s.score, size: 14),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (repo.awaitingResults > 0)
            Hint(
              '${repo.awaitingResults} more played matches are waiting for their scores.',
            ),
        ],
        // Five seasons: singles versus tickets.
        const SectionTitle('Singles or tickets?', note: 'five seasons'),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final size in [1, 2, 3, 5, 10]) ...[
                _RoiBar(
                  label: size == 1 ? 'Strong singles' : '$size-match tickets',
                  value: study.strategy('bet365', size).roi,
                  sub: 'Bet365',
                ),
                _RoiBar(
                  label: '',
                  value: study.strategy('best', size).roi,
                  sub: 'best price',
                ),
                const SizedBox(height: 6),
              ],
              Text(
                'Every extra leg multiplies the bookmaker\'s margin. At the best price, singles and trebles came out about even; 10-match tickets lost about a quarter of the stake.',
                style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.4),
              ),
            ],
          ),
        ),
        // The weekend checked by hand (bundled).
        SectionTitle(
          'Checked weekend',
          note: study.lastWeekend['label'] as String,
        ),
        Panel(
          child: Column(
            children: [
              for (final row in (study.lastWeekend['rows'] as List))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          row[0] as String,
                          style: TextStyle(color: p.text, fontSize: 13.5),
                        ),
                      ),
                      Text(
                        '${row[2]}/${row[1]}  ',
                        style: TextStyle(color: p.muted, fontSize: 12.5),
                      ),
                      Mono(
                        Format.money((row[3] as num).toDouble()),
                        size: 13.5,
                        color: (row[3] as num) >= 0 ? p.accent : p.loss,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                study.lastWeekend['luck'] as String,
                style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A small number tile.
class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.note,
    this.color,
  });
  final String label;
  final String value;
  final String? note;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Panel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: p.muted,
              fontSize: 10.5,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Mono(value, size: 21, color: color),
          if (note != null)
            Text(note!, style: TextStyle(color: p.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

/// A return bar centred on zero: green to the right for profit, red to the left for loss.
class _RoiBar extends StatelessWidget {
  const _RoiBar({required this.label, required this.value, required this.sub});
  final String label;
  final double value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final share = (value.abs() / 0.35).clamp(
      0.0,
      1.0,
    ); // 35% fills half the track
    final color = value >= 0 ? p.accent : p.loss;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label.isEmpty ? '… $sub' : '$label · $sub',
              style: TextStyle(
                color: label.isEmpty ? p.muted : p.text,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 10,
              child: LayoutBuilder(
                builder: (context, box) {
                  final half = box.maxWidth / 2;
                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: p.raised,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      Positioned(
                        left: value >= 0 ? half : half - half * share,
                        width: half * share,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      Positioned(
                        left: half,
                        top: -2,
                        bottom: -2,
                        child: Container(width: 1, color: p.muted),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          SizedBox(
            width: 62,
            child: Text(
              Format.signedPercent(value),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: AppFonts.mono,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
