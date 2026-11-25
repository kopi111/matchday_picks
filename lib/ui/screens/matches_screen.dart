import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/study.dart';
import '../../data/uk_time.dart';
import '../../state/picks_repository.dart';
import '../cards.dart';
import '../format.dart';
import '../widgets.dart';
import 'settings_sheet.dart';
import 'today_screen.dart';

/// Matches: every match on a day, filterable by league, each with its three picks.
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  String? _day;
  String _league = 'All';
  bool _strongOnly = false;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<PicksRepository>();
    final study = context.read<Study>();

    // Same day logic as Today: the chosen day, else today, else the next match day.
    final days = repo.days;
    final today = localDayKey(DateTime.now());
    final day = _day != null && days.contains(_day)
        ? _day!
        : (days.contains(today)
              ? today
              : (days.isNotEmpty ? days.first : today));
    final onDay = repo.onDay(day);
    final leagues = [
      'All',
      ...{
        for (final m in onDay)
          study.leagues[m.match.league]?.name ?? m.match.league,
      },
    ];
    final league = leagues.contains(_league) ? _league : 'All';
    final shown = onDay
        .where(
          (m) =>
              league == 'All' ||
              (study.leagues[m.match.league]?.name ?? m.match.league) == league,
        )
        .where((m) => !_strongOnly || m.hasStrongPick)
        .toList();

    return ScreenScaffold(
      onRefresh: () => repo.load(force: true),
      children: [
        AppHeader(
          eyebrow: Format.day(DateTime.parse('${day}T12:00:00')),
          title: 'Matches',
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
          const SizedBox(height: 8),
          // League filter plus a "strong only" toggle.
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ChoiceChipBox(
                  on: _strongOnly,
                  onTap: () => setState(() => _strongOnly = !_strongOnly),
                  child: const Text('★ Strong only'),
                ),
                for (final name in leagues) ...[
                  const SizedBox(width: 8),
                  ChoiceChipBox(
                    on: name == league,
                    onTap: () => setState(() => _league = name),
                    child: Text(name),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (shown.isEmpty)
            const EmptyState(
              title: 'No matches here',
              message:
                  'Try another day or league. The weekend list usually appears by Wednesday.',
            )
          else
            for (final m in shown) MatchCard(matchPicks: m),
        ],
      ],
    );
  }
}
