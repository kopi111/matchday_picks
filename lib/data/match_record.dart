import 'uk_time.dart';

/// Bookmaker prices for the markets the app uses. Missing prices are null.
class Prices {
  const Prices({this.home, this.draw, this.away, this.over25, this.under25});

  final double? home;
  final double? draw;
  final double? away;
  final double? over25;
  final double? under25;

  /// Reads one set of price columns (e.g. Bet365 "B365H" or best-price "MaxH") from a CSV row.
  factory Prices.fromRow(Map<String, String> row, Map<String, String> columns) {
    return Prices(
      home: _odds(row[columns['home']]),
      draw: _odds(row[columns['draw']]),
      away: _odds(row[columns['away']]),
      over25: _odds(row[columns['over25']]),
      under25: _odds(row[columns['under25']]),
    );
  }

  /// The price for a side ('home', 'draw', 'away', 'over25', 'under25').
  double? of(String key) => switch (key) {
    'home' => home,
    'draw' => draw,
    'away' => away,
    'over25' => over25,
    'under25' => under25,
    _ => null,
  };

  /// Decimal odds must be above 1.00 to be a real price.
  static double? _odds(String? text) {
    final value = double.tryParse(text ?? '');
    return value != null && value > 1 ? value : null;
  }
}

/// One match from a football-data.co.uk file: a played result or an upcoming fixture.
class MatchRecord {
  MatchRecord({
    required this.league,
    required this.kickoff,
    required this.home,
    required this.away,
    required this.bet365,
    required this.best,
    this.homeGoals,
    this.awayGoals,
    this.homeShotsOnTarget,
    this.awayShotsOnTarget,
  });

  final String league;
  final DateTime kickoff;
  final String home;
  final String away;
  final Prices bet365;
  final Prices best;
  final int? homeGoals;
  final int? awayGoals;
  final int? homeShotsOnTarget;
  final int? awayShotsOnTarget;

  /// The same id scheme as the web dashboard: league|date|home|away.
  String get id =>
      '$league|${kickoff.toIso8601String().substring(0, 10)}|$home|$away';

  /// A match is played once both scores are known.
  bool get played => homeGoals != null && awayGoals != null;

  /// Builds a record from a CSV row; returns null for rows the file uses as padding.
  static MatchRecord? fromRow(Map<String, String> row) {
    final league = row['Div'] ?? '';
    final home = row['HomeTeam'] ?? '';
    final away = row['AwayTeam'] ?? '';
    final date = row['Date'] ?? '';
    if (league.isEmpty || home.isEmpty || away.isEmpty || date.isEmpty) {
      return null;
    }
    try {
      return MatchRecord(
        league: league,
        kickoff: parseUkKickoff(date, row['Time']),
        home: home,
        away: away,
        // Bet365 opening prices and the highest price across bookmakers (football-data's Max columns).
        bet365: Prices.fromRow(row, _bet365Columns),
        best: Prices.fromRow(row, _bestColumns),
        homeGoals: int.tryParse(row['FTHG'] ?? ''),
        awayGoals: int.tryParse(row['FTAG'] ?? ''),
        homeShotsOnTarget: int.tryParse(row['HST'] ?? ''),
        awayShotsOnTarget: int.tryParse(row['AST'] ?? ''),
      );
    } on FormatException {
      return null;
    }
  }

  static const _bet365Columns = {
    'home': 'B365H',
    'draw': 'B365D',
    'away': 'B365A',
    'over25': 'B365>2.5',
    'under25': 'B365<2.5',
  };
  static const _bestColumns = {
    'home': 'MaxH',
    'draw': 'MaxD',
    'away': 'MaxA',
    'over25': 'Max>2.5',
    'under25': 'Max<2.5',
  };
}
