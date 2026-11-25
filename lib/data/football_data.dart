import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'csv.dart';
import 'match_record.dart';

/// Downloads football-data.co.uk files and keeps a copy on the phone,
/// so the app still works (with a warning) when the site is slow or there is no internet.
class FootballDataClient {
  FootballDataClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _origin = 'https://www.football-data.co.uk';
  static const _timeout = Duration(seconds: 25);

  /// Set to true when any file came from the saved copy instead of the internet.
  bool usedSavedCopy = false;

  /// This week's fixtures (all leagues) with Bet365 and best prices. Refreshed after an hour.
  Future<List<MatchRecord>> fixtures({bool force = false}) async {
    final text = await _download(
      'fixtures.csv',
      maxAge: force ? Duration.zero : const Duration(hours: 1),
    );
    return _records(text);
  }

  /// One league's results for the last [seasonCount] seasons, oldest first.
  Future<List<MatchRecord>> leagueHistory(
    String league, {
    int seasonCount = 3,
    bool force = false,
  }) async {
    final seasons = seasonCodes(DateTime.now(), seasonCount);
    final files = await Future.wait(
      seasons.map((season) {
        // Finished seasons never change, so they are kept for a week; the current one for three hours.
        final current = season == seasons.first;
        final maxAge = force && current
            ? Duration.zero
            : current
            ? const Duration(hours: 3)
            : const Duration(days: 7);
        return _download(
          'mmz4281/$season/$league.csv',
          maxAge: maxAge,
        ).catchError((_) => '');
      }),
    );
    final matches = files.expand(_records).toList()
      ..sort((a, b) => a.kickoff.compareTo(b.kickoff));
    return matches;
  }

  /// Season codes like "2627", "2526", ... starting with the current season (seasons start in July).
  static List<String> seasonCodes(DateTime today, int count) {
    final startYear = today.month >= 7 ? today.year : today.year - 1;
    String twoDigits(int year) => (year % 100).toString().padLeft(2, '0');
    return List.generate(
      count,
      (index) =>
          '${twoDigits(startYear - index)}${twoDigits(startYear - index + 1)}',
    );
  }

  /// Parses CSV text into match records, skipping padding rows.
  List<MatchRecord> _records(String text) =>
      parseCsv(text).map(MatchRecord.fromRow).whereType<MatchRecord>().toList();

  /// Returns the file's text: the saved copy if it is fresh enough, otherwise a new download;
  /// if the download fails, falls back to any saved copy and remembers that it did.
  Future<String> _download(String path, {required Duration maxAge}) async {
    final saved = await _savedFile(path);
    // Use the saved copy when it is younger than maxAge.
    if (await saved.exists() &&
        DateTime.now().difference(await saved.lastModified()) < maxAge) {
      return saved.readAsString();
    }
    try {
      final response = await _client
          .get(Uri.parse('$_origin/$path'))
          .timeout(_timeout);
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode} for $path');
      }
      // The files are UTF-8 and start with a byte-order mark; decode as UTF-8 (parseCsv strips the mark).
      final text = utf8.decode(response.bodyBytes, allowMalformed: true);
      await saved.writeAsString(text);
      return text;
    } catch (error) {
      // No internet or the site timed out: use the old copy if there is one.
      if (await saved.exists()) {
        usedSavedCopy = true;
        return saved.readAsString();
      }
      rethrow;
    }
  }

  /// Where a downloaded file is kept on the phone.
  Future<File> _savedFile(String path) async {
    final directory = await getApplicationSupportDirectory();
    final file = File(
      '${directory.path}/football-data/${path.replaceAll('/', '_')}',
    );
    await file.parent.create(recursive: true);
    return file;
  }
}
