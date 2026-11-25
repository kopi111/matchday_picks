import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/themes.dart';

/// The user's choices, saved on the phone so they survive restarts.
class Settings extends ChangeNotifier {
  AppThemeKey theme = AppThemeKey.matchday;
  int stake = 20;
  bool useBestPrice = true;
  bool hideWeakLeagues = true;

  static const stakeOptions = [10, 20, 50, 100];

  /// Reads saved choices (defaults on first launch).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    theme = AppThemeKey.values.firstWhere(
      (t) => t.name == prefs.getString('theme'),
      orElse: () => AppThemeKey.matchday,
    );
    stake = prefs.getInt('stake') ?? 20;
    useBestPrice = prefs.getBool('useBestPrice') ?? true;
    hideWeakLeagues = prefs.getBool('hideWeakLeagues') ?? true;
    notifyListeners();
  }

  void setTheme(AppThemeKey value) => _update(() => theme = value);
  void setStake(int value) => _update(() => stake = value);
  void setUseBestPrice(bool value) => _update(() => useBestPrice = value);
  void setHideWeakLeagues(bool value) => _update(() => hideWeakLeagues = value);

  /// Applies a change, redraws the app, and saves everything.
  void _update(void Function() change) {
    change();
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('theme', theme.name);
      prefs.setInt('stake', stake);
      prefs.setBool('useBestPrice', useBestPrice);
      prefs.setBool('hideWeakLeagues', hideWeakLeagues);
    });
  }
}
