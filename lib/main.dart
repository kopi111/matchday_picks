import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app/themes.dart';
import 'data/study.dart';
import 'state/picks_repository.dart';
import 'state/settings.dart';
import 'ui/home_shell.dart';

/// Matchday Picks: football picks for 1X2, both teams to score and Over/Under 2.5,
/// written from a goals model and a five-season study. Research tool; it never places bets.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the bundled study and the saved settings before the first frame.
  final study = await Study.load();
  final settings = Settings();
  await settings.load();

  // Start downloading and pricing straight away; screens show progress while it runs.
  final repository = PicksRepository(study)..load();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: study),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: repository),
      ],
      child: const MatchdayPicksApp(),
    ),
  );
}

class MatchdayPicksApp extends StatelessWidget {
  const MatchdayPicksApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();
    final palette = AppPalette.of(settings.theme);

    // Status-bar icons follow the theme (dark icons on light themes).
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: palette.isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: palette.background,
      ),
    );

    return MaterialApp(
      title: 'Matchday Picks',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(settings.theme),
      themeAnimationDuration: const Duration(milliseconds: 250),
      home: const HomeShell(),
    );
  }
}
