import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:matchday_picks/data/csv.dart';
import 'package:matchday_picks/data/match_record.dart';
import 'package:matchday_picks/data/uk_time.dart';
import 'package:matchday_picks/model/league_model.dart';
import 'package:matchday_picks/model/score_matrix.dart';

/// Reads a saved football-data file the way the app does (UTF-8 with a byte-order mark).
List<MatchRecord> readFixture(String name) =>
    parseCsv(utf8.decode(File('test/fixtures/$name').readAsBytesSync(), allowMalformed: true)).map(MatchRecord.fromRow).whereType<MatchRecord>().toList();

void main() {
  test('CSV reader strips the byte-order mark so the Div column is found', () {
    final rows = parseCsv('﻿Div,HomeTeam,FTHG\nE0,Arsenal,\n');
    expect(rows, [{'Div': 'E0', 'HomeTeam': 'Arsenal', 'FTHG': ''}]);
  });

  test('UK kick-off times convert to UTC in summer and winter time', () {
    expect(parseUkKickoff('19/10/2026', '20:00'), DateTime.utc(2026, 10, 19, 19));
    expect(parseUkKickoff('15/01/2026', '15:00'), DateTime.utc(2026, 1, 15, 15));
    // Clocks go back on Sunday 25 October 2026: an 8pm kick-off that evening is 20:00 UTC.
    expect(parseUkKickoff('25/10/2026', '20:00'), DateTime.utc(2026, 10, 25, 20));
  });

  test('score grid adds up to one and 1X2 covers every scoreline', () {
    final matrix = ScoreMatrix(1.6, 1.1, ModelSettings.dixonColesRho);
    final total = matrix.sumWhere((h, a) => h > a) + matrix.sumWhere((h, a) => h == a) + matrix.sumWhere((h, a) => h < a);
    expect(total, closeTo(1, 1e-9));
  });

  test('phone model matches the web dashboard (Galatasaray v Fenerbahce, Süper Lig)', () {
    // Same data and cut-off as the JavaScript reference run.
    final matches = ['T1-2425.csv', 'T1-2526.csv', 'T1-2627.csv'].expand(readFixture).toList();
    final model = LeagueModel.fit(matches, DateTime.utc(2026, 10, 26, 12));
    final expected = model.expectedGoals('Galatasaray', 'Fenerbahce');
    final matrix = ScoreMatrix(expected.home, expected.away, ModelSettings.dixonColesRho);
    // Reference values from bet-builder-lab's JS model.
    expect(expected.home, closeTo(2.030320435511877, 1e-9));
    expect(expected.away, closeTo(1.587560809141108, 1e-9));
    expect(matrix.sumWhere((h, a) => h + a > 2.5), closeTo(0.7004034518767065, 1e-9));
    expect(matrix.sumWhere((h, a) => h > 0 && a > 0), closeTo(0.6963119293062523, 1e-9));
    expect(matrix.sumWhere((h, a) => h > a), closeTo(0.4767646439454136, 1e-9));
  });

  test('this week\'s fixture file reads with Bet365 and best prices', () {
    final fixtures = readFixture('fixtures.csv');
    expect(fixtures, isNotEmpty);
    final derby = fixtures.firstWhere((f) => f.home == 'Galatasaray');
    expect(derby.bet365.over25, 1.48);
    expect(derby.best.over25, isNotNull);
  });
}
