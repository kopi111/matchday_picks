import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/themes.dart';
import '../../data/study.dart';
import '../../data/uk_time.dart';
import '../../model/picks.dart';
import '../../state/picks_repository.dart';
import '../../state/settings.dart';
import '../cards.dart';
import '../format.dart';
import '../widgets.dart';
import 'settings_sheet.dart';

/// Today: the tickets the app writes for the chosen day, then that day's strong picks.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  String? _day; // chosen day; null = today, or the next day with matches

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<PicksRepository>();
    final settings = context.watch<Settings>();
    final study = context.read<Study>();

    // Pick the day to show: the user's choice, else today, else the next match day.
    final days = repo.days;
    final today = localDayKey(DateTime.now());
    final day = _day != null && days.contains(_day)
        ? _day!
        : (days.contains(today)
              ? today
              : (days.isNotEmpty ? days.first : today));
    final matches = repo.onDay(day);
    final tickets = writeTickets(
      matches,
      study,
      useBest: settings.useBestPrice,
      hideWeak: settings.hideWeakLeagues,
    );
    final strong = matches.where((m) => m.covered && m.hasStrongPick).toList();
    final dayDate = DateTime.parse('${day}T12:00:00');

    return ScreenScaffold(
      onRefresh: () => repo.load(force: true),
      children: [
        AppHeader(
          eyebrow: Format.day(dayDate),
          title: day == today ? 'Today\'s' : 'Matchday',
          accentWord: 'picks',
          onSettings: () => showSettingsSheet(context),
        ),
        ...statusWidgets(context, repo),
        if (repo.status == LoadStatus.ready) ...[
          DayChips(
            days: days,
            selected: day,
            counts: {for (final d in days) d: repo.onDay(d).length},
            onSelect: (d) => setState(() => _day = d),
          ),
          SectionTitle(
            'Written tickets',
            note:
                '\$${settings.stake} each · ${settings.useBestPrice ? 'best price' : 'Bet365'}',
          ),
          if (days.isEmpty)
            const EmptyState(
              title: 'Fixtures not out yet',
              message:
                  'The free feed publishes the weekend\'s fixtures mid-week. Pull down to refresh later.',
              icon: Icons.event_busy_rounded,
            )
          else if (tickets.isEmpty)
            const EmptyState(
              title: 'No ticket today',
              message:
                  'None of these matches has a strong pick with a price in a league where strong picks have held up. Not betting is the pick.',
              icon: Icons.do_not_disturb_on_outlined,
            )
          else
            for (final (index, ticket) in tickets.indexed)
              TicketCard(number: index + 1, legs: ticket),
          Hint(
            'Each selection shows what it pays as a \$${settings.stake} single. Over five seasons, strong singles and trebles at the best price came out about even; at Bet365 they lost 3–7%. Check team news before kick-off.',
          ),
          SectionTitle(
            'Strong picks',
            note: '${strong.length} of ${matches.length} matches',
          ),
          if (strong.isEmpty)
            const EmptyState(
              title: 'No strong picks on this day',
              message: 'Open Matches to see every pick.',
            ),
          for (final m in strong) MatchCard(matchPicks: m),
        ],
      ],
    );
  }
}

/// Shared page layout: pull-to-refresh, side padding, room for the floating tab bar.
class ScreenScaffold extends StatelessWidget {
  const ScreenScaffold({super.key, required this.children, this.onRefresh});
  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 6,
        16,
        110,
      ),
      children: children,
    );
    return onRefresh == null
        ? list
        : RefreshIndicator(
            onRefresh: onRefresh!,
            color: context.palette.accent,
            child: list,
          );
  }
}

/// Loading, error and offline messages shared by the data screens.
List<Widget> statusWidgets(BuildContext context, PicksRepository repo) {
  final p = context.palette;
  return [
    if (repo.status == LoadStatus.loading)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: p.accent,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              repo.progress,
              textAlign: TextAlign.center,
              style: TextStyle(color: p.muted),
            ),
            const SizedBox(height: 4),
            Text(
              'The first load downloads three seasons per league; after that it is quick.',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.faint, fontSize: 12),
            ),
          ],
        ),
      ),
    if (repo.status == LoadStatus.failed)
      EmptyState(
        title: 'No data yet',
        message: repo.error ?? 'Something went wrong.',
        icon: Icons.wifi_off_rounded,
      ),
    if (repo.status == LoadStatus.ready && repo.offline)
      Notice(
        'No connection to football-data.co.uk. Showing the saved copy${repo.updatedAt == null ? '' : ' from ${Format.time(repo.updatedAt!)}'}; prices may have moved.',
        icon: Icons.wifi_off_rounded,
      ),
  ];
}

/// Horizontal day selector: "Mon 26 · 10".
class DayChips extends StatelessWidget {
  const DayChips({
    super.key,
    required this.days,
    required this.selected,
    required this.counts,
    required this.onSelect,
  });
  final List<String> days;
  final String selected;
  final Map<String, int> counts;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final day = days[index];
          final on = day == selected;
          return ChoiceChipBox(
            on: on,
            onTap: () => onSelect(day),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: Format.shortDay(DateTime.parse('${day}T12:00:00')),
                  ),
                  TextSpan(
                    text: '  ${counts[day] ?? 0}',
                    style: TextStyle(
                      color: on ? p.background.withValues(alpha: 0.7) : p.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A pill-shaped toggle used for day and league filters.
class ChoiceChipBox extends StatelessWidget {
  const ChoiceChipBox({
    super.key,
    required this.on,
    required this.onTap,
    required this.child,
  });
  final bool on;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: on ? p.text : p.surface,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: on ? p.text : p.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: DefaultTextStyle(
            style: TextStyle(
              color: on ? p.background : p.text,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              fontFamily: AppFonts.body,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
