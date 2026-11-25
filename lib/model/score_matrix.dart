import 'dart:math' as math;

/// Probability of every scoreline from 0-0 to 10-10, from two Poisson goal counts
/// with the Dixon-Coles correction for low scores (0-0, 1-0, 0-1, 1-1).
class ScoreMatrix {
  ScoreMatrix(double homeMean, double awayMean, double rho)
    : _cells = _build(homeMean, awayMean, rho);

  static const maxGoals = 10;
  static const size = maxGoals + 1;
  final List<double> _cells;

  /// Probability of exactly [home]-[away].
  double probabilityOf(int home, int away) => _cells[home * size + away];

  /// Adds up the probability of every scoreline where [test] is true.
  double sumWhere(bool Function(int home, int away) test) {
    var total = 0.0;
    for (var home = 0; home < size; home++) {
      for (var away = 0; away < size; away++) {
        if (test(home, away)) total += probabilityOf(home, away);
      }
    }
    return total;
  }

  /// The [count] most likely scorelines, most likely first.
  List<({int home, int away, double probability})> mostLikely(int count) {
    final scores = [
      for (var home = 0; home < size; home++)
        for (var away = 0; away < size; away++)
          (home: home, away: away, probability: probabilityOf(home, away)),
    ]..sort((a, b) => b.probability.compareTo(a.probability));
    return scores.take(count).toList();
  }

  static List<double> _build(double homeMean, double awayMean, double rho) {
    // Poisson chance of each goal count for each side.
    final homeTable = _poisson(homeMean);
    final awayTable = _poisson(awayMean);
    final cells = List<double>.filled(size * size, 0);
    var total = 0.0;
    for (var home = 0; home < size; home++) {
      for (var away = 0; away < size; away++) {
        // Independent chance × low-score correction, never below zero.
        final value =
            homeTable[home] *
            awayTable[away] *
            _lowScoreAdjustment(home, away, homeMean, awayMean, rho);
        cells[home * size + away] = math.max(0, value);
        total += cells[home * size + away];
      }
    }
    // Rescale so all scorelines add up to exactly 1.
    return cells.map((value) => value / total).toList();
  }

  static List<double> _poisson(double mean) {
    final table = List<double>.filled(size, 0);
    table[0] = math.exp(-mean);
    for (var k = 1; k < size; k++) {
      table[k] = table[k - 1] * mean / k;
    }
    return table;
  }

  static double _lowScoreAdjustment(
    int home,
    int away,
    double homeMean,
    double awayMean,
    double rho,
  ) {
    if (home == 0 && away == 0) return 1 - homeMean * awayMean * rho;
    if (home == 0 && away == 1) return 1 + homeMean * rho;
    if (home == 1 && away == 0) return 1 + awayMean * rho;
    if (home == 1 && away == 1) return 1 - rho;
    return 1;
  }
}
