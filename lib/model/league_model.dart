import 'dart:math' as math;

import '../data/match_record.dart';

/// Model settings, identical to the web dashboard's defaults.
class ModelSettings {
  static const halfLifeDays =
      180.0; // older matches count half as much every 180 days
  static const shrinkageMatches =
      4.0; // pull small samples toward the league average
  static const shotsOnTargetBlend =
      0.35; // 35% of each score comes from shots on target
  static const dixonColesRho = -0.06; // low-score correction
  static const minimumTeamMatches =
      6; // fewer league matches than this = "insufficient evidence"
  static const minimumCoverage =
      0.6; // shots data must cover 60% of matches to be used
  static const iterations = 40;
}

/// A team's attack ("for") and defence ("against") strength relative to the league average (1.0).
class TeamRating {
  double attack = 1;
  double defence = 1;
  double weightedMatches = 0;
  int matches = 0;
}

/// One past match seen by the fit: who played, the (blended) goals, and how much it counts.
class _Observation {
  _Observation(
    this.home,
    this.away,
    this.homeValue,
    this.awayValue,
    this.weight,
  );
  final String home;
  final String away;
  final double homeValue;
  final double awayValue;
  final double weight;
}

/// Attack/defence ratings for a league fitted on its earlier results (Poisson goals model).
class LeagueModel {
  LeagueModel._(this.baseHome, this.baseAway, this.teams, this.asOf);

  final double baseHome; // average home goals per match
  final double baseAway; // average away goals per match
  final Map<String, TeamRating> teams;
  final DateTime asOf;

  /// Fits the league using only matches played before [asOf].
  static LeagueModel fit(List<MatchRecord> matches, DateTime asOf) {
    // Keep played matches before the cut-off; the model never sees the future.
    final history = matches
        .where((m) => m.played && m.kickoff.isBefore(asOf))
        .toList();
    if (history.length < 30) {
      throw StateError(
        'Only ${history.length} completed matches; at least 30 are needed',
      );
    }

    // Shots on target per goal in this league, used to smooth out lucky or unlucky scorelines.
    final conversion = _goalsPerShotOnTarget(history);
    final blend = conversion == null ? 0.0 : ModelSettings.shotsOnTargetBlend;
    final rate = conversion ?? 0;

    // Turn each match into an observation with a time-decay weight.
    final observations = history.map((m) {
      final ageDays = asOf.difference(m.kickoff).inMinutes / 1440;
      final weight = math
          .pow(0.5, ageDays / ModelSettings.halfLifeDays)
          .toDouble();
      var homeValue = m.homeGoals!.toDouble();
      var awayValue = m.awayGoals!.toDouble();
      if (blend > 0 &&
          m.homeShotsOnTarget != null &&
          m.awayShotsOnTarget != null) {
        homeValue =
            (1 - blend) * homeValue + blend * m.homeShotsOnTarget! * rate;
        awayValue =
            (1 - blend) * awayValue + blend * m.awayShotsOnTarget! * rate;
      }
      return _Observation(m.home, m.away, homeValue, awayValue, weight);
    }).toList();

    return _fitRatings(observations, asOf);
  }

  /// Goals per shot on target across the league, or null when too few matches have shots data.
  static double? _goalsPerShotOnTarget(List<MatchRecord> history) {
    final withShots = history
        .where(
          (m) => m.homeShotsOnTarget != null && m.awayShotsOnTarget != null,
        )
        .toList();
    if (withShots.length < history.length * ModelSettings.minimumCoverage) {
      return null;
    }
    final goals = withShots.fold<int>(
      0,
      (sum, m) => sum + m.homeGoals! + m.awayGoals!,
    );
    final onTarget = withShots.fold<int>(
      0,
      (sum, m) => sum + m.homeShotsOnTarget! + m.awayShotsOnTarget!,
    );
    return onTarget == 0 ? null : goals / onTarget;
  }

  /// Iteratively solves attack and defence ratings so expected goals match actual goals (with shrinkage).
  static LeagueModel _fitRatings(
    List<_Observation> observations,
    DateTime asOf,
  ) {
    // League baselines: weighted average home and away goals.
    final totalWeight = observations.fold<double>(0, (s, o) => s + o.weight);
    final baseHome =
        observations.fold<double>(0, (s, o) => s + o.weight * o.homeValue) /
        totalWeight;
    final baseAway =
        observations.fold<double>(0, (s, o) => s + o.weight * o.awayValue) /
        totalWeight;

    // Every team starts at average (1.0) and counts its matches.
    final teams = <String, TeamRating>{};
    for (final o in observations) {
      for (final name in [o.home, o.away]) {
        final team = teams.putIfAbsent(name, TeamRating.new);
        team.weightedMatches += o.weight;
        team.matches += 1;
      }
    }

    // The shrinkage prior acts like a few extra average matches for every team.
    final prior = ModelSettings.shrinkageMatches * (baseHome + baseAway) / 2;

    for (var step = 0; step < ModelSettings.iterations; step++) {
      // Attack: goals a team scored versus what average attackers would score against those defences.
      final attack = <String, List<double>>{};
      for (final o in observations) {
        _add(
          attack,
          o.home,
          o.weight * o.homeValue,
          o.weight * baseHome * teams[o.away]!.defence,
        );
        _add(
          attack,
          o.away,
          o.weight * o.awayValue,
          o.weight * baseAway * teams[o.home]!.defence,
        );
      }
      attack.forEach(
        (name, sum) =>
            teams[name]!.attack = (sum[0] + prior) / (sum[1] + prior),
      );

      // Defence: goals a team conceded versus what those attacks would score against an average defence.
      final defence = <String, List<double>>{};
      for (final o in observations) {
        _add(
          defence,
          o.home,
          o.weight * o.awayValue,
          o.weight * baseAway * teams[o.away]!.attack,
        );
        _add(
          defence,
          o.away,
          o.weight * o.homeValue,
          o.weight * baseHome * teams[o.home]!.attack,
        );
      }
      defence.forEach(
        (name, sum) =>
            teams[name]!.defence = (sum[0] + prior) / (sum[1] + prior),
      );

      // Keep the league average at exactly 1.0 (geometric mean).
      _normalise(teams);
    }
    return LeagueModel._(baseHome, baseAway, teams, asOf);
  }

  static void _add(
    Map<String, List<double>> totals,
    String name,
    double actual,
    double expected,
  ) {
    final sum = totals.putIfAbsent(name, () => [0, 0]);
    sum[0] += actual;
    sum[1] += expected;
  }

  static void _normalise(Map<String, TeamRating> teams) {
    final count = teams.length;
    final attackScale = math.exp(
      teams.values.fold<double>(0, (s, t) => s + math.log(t.attack)) / count,
    );
    final defenceScale = math.exp(
      teams.values.fold<double>(0, (s, t) => s + math.log(t.defence)) / count,
    );
    for (final team in teams.values) {
      team.attack /= attackScale;
      team.defence /= defenceScale;
    }
  }

  /// A team's rating, or an average team with no matches if it is new to the data.
  TeamRating team(String name) => teams[name] ?? TeamRating();

  /// Expected goals for each side: league baseline × attack × the opponent's defence.
  ({double home, double away}) expectedGoals(String home, String away) {
    final h = team(home);
    final a = team(away);
    return (
      home: baseHome * h.attack * a.defence,
      away: baseAway * a.attack * h.defence,
    );
  }

  /// True when both teams have enough league matches for the ratings to mean something.
  bool covers(String home, String away) =>
      math.min(team(home).matches, team(away).matches) >=
      ModelSettings.minimumTeamMatches;
}
