import 'dart:convert';

import 'package:flutter/services.dart';

/// How picks at one confidence level did in the five-season walk-forward study.
class ConfidenceBand {
  ConfidenceBand.fromJson(Map<String, dynamic> json)
    : from = (json['from'] as num).toDouble(),
      to = (json['to'] as num).toDouble(),
      bets = json['bets'] as int,
      hitRate = (json['hitRate'] as num).toDouble(),
      roi = (json['roi'] as num?)?.toDouble();

  final double from;
  final double to;
  final int bets;
  final double hitRate;
  final double? roi;
}

/// A league's record for strong picks over five seasons, with the app's tag (good / average / weak).
class LeagueRecord {
  LeagueRecord.fromJson(Map<String, dynamic> json)
    : code = json['code'] as String,
      country = json['country'] as String,
      name = json['name'] as String,
      tag = json['tag'] as String,
      bets = json['bets'] as int,
      hitRate = (json['hitRate'] as num).toDouble(),
      roiBet365 = (json['roiBet365'] as num).toDouble(),
      roiBest = (json['roiBest'] as num).toDouble();

  final String code;
  final String country;
  final String name;
  final String tag;
  final int bets;
  final double hitRate;
  final double roiBet365;
  final double roiBest;

  bool get isWeak => tag == 'weak';
  bool get isGood => tag == 'good';
}

/// One staking strategy replayed over every weekend (singles, 2-, 3-, 5-, 10-match tickets).
class StrategyResult {
  StrategyResult.fromJson(Map<String, dynamic> json)
    : source = json['source'] as String,
      size = json['size'] as int,
      every = json['every'] as bool,
      roi = (json['roi'] as num).toDouble(),
      profitableWeekends = (json['profitableWeekends'] as num).toDouble();

  final String source;
  final int size;
  final bool every;
  final double roi;
  final double profitableWeekends;
}

/// Everything the app learned from the five-season study, bundled in assets/data/study.json.
class Study {
  Study._(this._json)
    : bands = {
        for (final market in ['result', 'btts', 'goals'])
          market: (_json['bands'][market] as List)
              .map((b) => ConfidenceBand.fromJson(b))
              .toList(),
      },
      leagues = {
        for (final league in (_json['leagues'] as List).map(
          (l) => LeagueRecord.fromJson(l),
        ))
          league.code: league,
      },
      strategies = (_json['strategies'] as List)
          .map((s) => StrategyResult.fromJson(s))
          .toList();

  final Map<String, dynamic> _json;
  final Map<String, List<ConfidenceBand>> bands;
  final Map<String, LeagueRecord> leagues;
  final List<StrategyResult> strategies;

  /// A pick is "strong" when picks with the same confidence historically won this often.
  static const strongHitRate = 0.6;

  int get matches => _json['matches'] as int;
  Map<String, dynamic> get legValue =>
      _json['legValue'] as Map<String, dynamic>;
  Map<String, dynamic> get lastWeekend =>
      _json['lastWeekend'] as Map<String, dynamic>;

  /// Loads the bundled study file.
  static Future<Study> load() async => Study._(
    jsonDecode(await rootBundle.loadString('assets/data/study.json')),
  );

  /// The band a model probability falls into for a market ('result', 'btts' or 'goals').
  ConfidenceBand bandFor(String market, double probability) {
    final list = bands[market]!;
    return list.firstWhere(
      (band) => probability >= band.from && probability < band.to,
      orElse: () => list.last,
    );
  }

  /// Strategy result for a price source ('bet365' / 'best') and ticket size, strong picks only.
  StrategyResult strategy(String source, int size) => strategies.firstWhere(
    (s) => s.source == source && s.size == size && !s.every,
  );
}
