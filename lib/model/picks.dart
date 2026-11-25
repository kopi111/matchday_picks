import '../data/match_record.dart';
import '../data/study.dart';
import 'league_model.dart';
import 'score_matrix.dart';

/// The three markets the app covers.
enum Market { result, btts, goals }

extension MarketLabel on Market {
  /// Short name shown on pills and tickets.
  String get short => switch (this) {
    Market.result => '1X2',
    Market.btts => 'BTTS',
    Market.goals => 'O/U 2.5',
  };

  /// Key used in the study file.
  String get studyKey => switch (this) {
    Market.result => 'result',
    Market.btts => 'btts',
    Market.goals => 'goals',
  };
}

/// The model's choice in one market for one match.
class Pick {
  Pick({
    required this.market,
    required this.choice,
    required this.label,
    required this.shortLabel,
    required this.probability,
    required this.bet365,
    required this.best,
    required this.band,
    this.bookmakerFair,
  });

  final Market market;
  final String
  choice; // 'home' / 'draw' / 'away' / 'yes' / 'no' / 'over' / 'under'
  final String label; // "Galatasaray to win", "Over 2.5 goals"
  final String shortLabel; // "Galatasaray", "Over 2.5"
  final double probability; // model chance
  final double? bet365; // Bet365 opening price, if published
  final double? best; // highest price across bookmakers, if published
  final ConfidenceBand band; // how similar picks did historically
  final double? bookmakerFair; // Bet365's chance with the margin removed

  /// Strong = picks at this confidence historically won 60%+.
  bool get isStrong => band.hitRate >= Study.strongHitRate;

  /// Fair odds: the price at which this pick would break even if the model is right.
  double get fairOdds => 1 / probability;

  /// The price to use: the best price when [useBest], otherwise Bet365; falls back to whichever exists.
  double? price({required bool useBest}) =>
      useBest ? (best ?? bet365) : (bet365 ?? best);

  /// True when the model is 10+ points away from Bet365: usually missing team news.
  bool get disagreesWithBookmaker =>
      bookmakerFair != null && (probability - bookmakerFair!).abs() > 0.10;
}

/// All three picks for one match, plus the expected goals behind them.
class MatchPicks {
  MatchPicks({
    required this.match,
    required this.covered,
    this.expectedHome,
    this.expectedAway,
    this.picks = const {},
    this.scores = const [],
    this.result = const {},
    this.error,
  });

  final MatchRecord match;
  final bool covered; // false when a team has too few league matches
  final double? expectedHome;
  final double? expectedAway;
  final Map<Market, Pick> picks;
  final List<({int home, int away, double probability})>
  scores; // most likely scorelines
  final Map<String, double> result; // home / draw / away chances
  final String? error; // the league could not be modelled

  bool get hasStrongPick => picks.values.any((p) => p.isStrong);

  /// Prices the three markets for [match] with a fitted [league] model.
  static MatchPicks price(LeagueModel league, MatchRecord match, Study study) {
    // Expected goals and the full scoreline grid.
    final expected = league.expectedGoals(match.home, match.away);
    final matrix = ScoreMatrix(
      expected.home,
      expected.away,
      ModelSettings.dixonColesRho,
    );

    // Match result: the most likely of home / draw / away.
    final result = {
      'home': matrix.sumWhere((h, a) => h > a),
      'draw': matrix.sumWhere((h, a) => h == a),
      'away': matrix.sumWhere((h, a) => h < a),
    };
    final side = result.entries.reduce((a, b) => b.value > a.value ? b : a).key;
    final fair = _removeMargin([
      match.bet365.home,
      match.bet365.draw,
      match.bet365.away,
    ]);
    final resultPick = Pick(
      market: Market.result,
      choice: side,
      label: side == 'draw'
          ? 'Draw'
          : '${side == 'home' ? match.home : match.away} to win',
      shortLabel: side == 'draw'
          ? 'Draw'
          : (side == 'home' ? match.home : match.away),
      probability: result[side]!,
      bet365: match.bet365.of(side),
      best: match.best.of(side),
      band: study.bandFor('result', result[side]!),
      bookmakerFair: fair?[['home', 'draw', 'away'].indexOf(side)],
    );

    // Both teams to score: yes if the model gives it 50%+.
    final bttsYes = matrix.sumWhere((h, a) => h > 0 && a > 0);
    final yes = bttsYes >= 0.5;
    final bttsPick = Pick(
      market: Market.btts,
      choice: yes ? 'yes' : 'no',
      label: 'Both teams score: ${yes ? 'Yes' : 'No'}',
      shortLabel: yes ? 'Yes' : 'No',
      probability: yes ? bttsYes : 1 - bttsYes,
      bet365: null, // the free data has no BTTS prices
      best: null,
      band: study.bandFor('btts', yes ? bttsYes : 1 - bttsYes),
    );

    // Over/Under 2.5: whichever side is 50%+.
    final over = matrix.sumWhere((h, a) => h + a > 2.5);
    final isOver = over >= 0.5;
    final goalsFair = _removeMargin([
      match.bet365.over25,
      match.bet365.under25,
    ]);
    final goalsPick = Pick(
      market: Market.goals,
      choice: isOver ? 'over' : 'under',
      label: '${isOver ? 'Over' : 'Under'} 2.5 goals',
      shortLabel: isOver ? 'Over 2.5' : 'Under 2.5',
      probability: isOver ? over : 1 - over,
      bet365: isOver ? match.bet365.over25 : match.bet365.under25,
      best: isOver ? match.best.over25 : match.best.under25,
      band: study.bandFor('goals', isOver ? over : 1 - over),
      bookmakerFair: goalsFair?[isOver ? 0 : 1],
    );

    return MatchPicks(
      match: match,
      covered: league.covers(match.home, match.away),
      expectedHome: expected.home,
      expectedAway: expected.away,
      picks: {
        Market.result: resultPick,
        Market.btts: bttsPick,
        Market.goals: goalsPick,
      },
      scores: matrix.mostLikely(6),
      result: result,
    );
  }

  /// Bookmaker chances with the margin taken out proportionally; null if a price is missing.
  static List<double>? _removeMargin(List<double?> prices) {
    if (prices.any((p) => p == null)) return null;
    final implied = prices.map((p) => 1 / p!).toList();
    final total = implied.fold<double>(0, (s, v) => s + v);
    return implied.map((v) => v / total).toList();
  }
}

/// One selection on a written ticket.
class TicketLeg {
  TicketLeg(this.matchPicks, this.pick);
  final MatchPicks matchPicks;
  final Pick pick;
}

/// Writes tickets with the study's rules: strong picks with a price, one per match (its most confident),
/// weak leagues left out (optional), good leagues first, trebles first, then a double or single for the rest.
List<List<TicketLeg>> writeTickets(
  List<MatchPicks> matches,
  Study study, {
  required bool useBest,
  required bool hideWeak,
}) {
  final legs = <TicketLeg>[];
  for (final m in matches) {
    if (!m.covered || m.error != null) continue;
    final league = study.leagues[m.match.league];
    if (hideWeak && (league?.isWeak ?? false)) continue;
    // Candidate picks: strong, priced, and the model not wildly away from the bookmaker.
    final options = m.picks.values
        .where(
          (p) =>
              p.isStrong &&
              p.price(useBest: useBest) != null &&
              !p.disagreesWithBookmaker,
        )
        .toList();
    if (options.isEmpty) continue;
    options.sort((a, b) => b.probability.compareTo(a.probability));
    legs.add(TicketLeg(m, options.first));
  }
  // Good leagues first, then the most confident picks.
  int rank(TicketLeg leg) =>
      switch (study.leagues[leg.matchPicks.match.league]?.tag) {
        'good' => 0,
        'weak' => 2,
        _ => 1,
      };
  legs.sort(
    (a, b) => rank(a) != rank(b)
        ? rank(a) - rank(b)
        : b.pick.probability.compareTo(a.pick.probability),
  );

  // Trebles first; whatever is left becomes a double or a single.
  final tickets = <List<TicketLeg>>[];
  for (var i = 0; i < legs.length; i += 3) {
    tickets.add(legs.sublist(i, i + 3 > legs.length ? legs.length : i + 3));
  }
  return tickets;
}
