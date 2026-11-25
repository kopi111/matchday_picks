import 'package:flutter/foundation.dart';

import '../data/football_data.dart';
import '../data/match_record.dart';
import '../data/study.dart';
import '../data/uk_time.dart';
import '../model/league_model.dart';
import '../model/picks.dart';

/// Where the data is in its life: loading, ready, or failed with no saved copy.
enum LoadStatus { loading, ready, failed }

/// A past pick settled against the final score.
class SettledPick {
  SettledPick(this.matchPicks, this.pick, this.won, this.score);
  final MatchPicks matchPicks;
  final Pick pick;
  final bool won;
  final String score;
}

/// Downloads fixtures and results, fits each league, and prices every match's three picks.
class PicksRepository extends ChangeNotifier {
  PicksRepository(this.study, {FootballDataClient? client})
    : _client = client ?? FootballDataClient();

  final Study study;
  final FootballDataClient _client;

  LoadStatus status = LoadStatus.loading;
  String progress = 'Starting…';
  String? error;
  DateTime? updatedAt;
  bool offline = false;

  /// Upcoming matches with picks, soonest first.
  List<MatchPicks> upcoming = [];

  /// This week's already-played matches, settled where the result file has the score.
  List<SettledPick> settled = [];
  int awaitingResults = 0;

  /// Loads everything; [force] skips the saved copies and downloads again.
  Future<void> load({bool force = false}) async {
    status = upcoming.isEmpty ? LoadStatus.loading : status;
    error = null;
    _client.usedSavedCopy = false;
    _setProgress('Downloading this week\'s fixtures…');
    try {
      // Fixtures for the week, limited to leagues the model has five-season data for.
      final fixtures = (await _client.fixtures(
        force: force,
      )).where((f) => study.leagues.containsKey(f.league)).toList();
      final leagues = fixtures.map((f) => f.league).toSet().toList()..sort();
      final now = DateTime.now().toUtc();

      final priced = <MatchPicks>[];
      final playedThisWeek = <MatchPicks>[];
      final results = <String, MatchRecord>{};

      // Fit one league at a time: download three seasons, fit as of now (upcoming) and as of each
      // played match's day (so settled picks never use their own result).
      for (final (index, league) in leagues.indexed) {
        _setProgress(
          'Fitting ${study.leagues[league]!.name} (${index + 1} of ${leagues.length})…',
        );
        final leagueFixtures = fixtures
            .where((f) => f.league == league)
            .toList();
        try {
          final history = await _client.leagueHistory(league, force: force);
          for (final m in history.where((m) => m.played)) {
            results[m.id] = m;
          }
          final model = LeagueModel.fit(history, now);
          for (final fixture in leagueFixtures.where(
            (f) => f.kickoff.isAfter(now),
          )) {
            priced.add(MatchPicks.price(model, fixture, study));
          }
          // Played fixtures: refit as of the start of their day, so the pick is what the app would have said.
          final byDay = <String, List<MatchRecord>>{};
          for (final f in leagueFixtures.where(
            (f) => !f.kickoff.isAfter(now),
          )) {
            byDay
                .putIfAbsent(
                  f.kickoff.toIso8601String().substring(0, 10),
                  () => [],
                )
                .add(f);
          }
          for (final entry in byDay.entries) {
            final dayModel = LeagueModel.fit(
              history,
              DateTime.parse('${entry.key}T00:00:00Z'),
            );
            playedThisWeek.addAll(
              entry.value.map((f) => MatchPicks.price(dayModel, f, study)),
            );
          }
        } catch (leagueError) {
          // One league failing (e.g. too few matches) must not stop the rest.
          priced.addAll(
            leagueFixtures
                .where((f) => f.kickoff.isAfter(now))
                .map(
                  (f) => MatchPicks(
                    match: f,
                    covered: false,
                    error: '$leagueError',
                  ),
                ),
          );
        }
        // Let the UI breathe between leagues.
        await Future<void>.delayed(Duration.zero);
      }

      upcoming = priced
        ..sort((a, b) => a.match.kickoff.compareTo(b.match.kickoff));
      _settle(playedThisWeek, results);
      offline = _client.usedSavedCopy;
      updatedAt = DateTime.now();
      status = LoadStatus.ready;
    } catch (loadError) {
      // Nothing saved and no internet: say so plainly.
      error =
          'Could not reach football-data.co.uk and there is no saved copy yet. Connect to the internet and pull to refresh.';
      debugPrint('load failed: $loadError');
      status = upcoming.isEmpty ? LoadStatus.failed : LoadStatus.ready;
    }
    notifyListeners();
  }

  /// Settles each played match's strong picks against the result file.
  void _settle(List<MatchPicks> played, Map<String, MatchRecord> results) {
    settled = [];
    awaitingResults = 0;
    for (final mp in played) {
      final result = results[mp.match.id];
      if (result == null) {
        awaitingResults++;
        continue;
      }
      final h = result.homeGoals!;
      final a = result.awayGoals!;
      for (final pick in mp.picks.values) {
        settled.add(SettledPick(mp, pick, _won(pick, h, a), '$h-$a'));
      }
    }
  }

  static bool _won(Pick pick, int h, int a) => switch (pick.market) {
    Market.result =>
      pick.choice ==
          (h > a
              ? 'home'
              : h == a
              ? 'draw'
              : 'away'),
    Market.btts => (h > 0 && a > 0) == (pick.choice == 'yes'),
    Market.goals => (h + a > 2.5) == (pick.choice == 'over'),
  };

  void _setProgress(String text) {
    progress = text;
    notifyListeners();
  }

  /// Local day keys that have upcoming matches, in order.
  List<String> get days =>
      upcoming.map((m) => localDayKey(m.match.kickoff)).toSet().toList()
        ..sort();

  /// Upcoming matches on one local day.
  List<MatchPicks> onDay(String day) =>
      upcoming.where((m) => localDayKey(m.match.kickoff) == day).toList();
}
