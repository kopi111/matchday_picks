import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/themes.dart';
import '../../state/picks_repository.dart';
import '../../state/settings.dart';
import '../format.dart';

/// Opens Settings as a bottom sheet: theme, stake, price source, weak leagues, data refresh.
void showSettingsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // Transparent here: the sheet paints its own background so it recolours live when the theme changes.
    backgroundColor: Colors.transparent,
    builder: (_) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final settings = context.watch<Settings>();
    final repo = context.watch<PicksRepository>();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Settings',
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 19,
                  color: p.text,
                ),
              ),
              const SizedBox(height: 12),
              // Theme picker: five round swatches (background / accent).
              _label(context, 'Theme', 'Pick the look you like'),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final key in AppThemeKey.values)
                    Expanded(
                      child: _ThemeOption(
                        themeKey: key,
                        selected: settings.theme == key,
                        onTap: () => settings.setTheme(key),
                      ),
                    ),
                ],
              ),
              const Divider(height: 28),
              // Stake.
              Row(
                children: [
                  Expanded(
                    child: _label(
                      context,
                      'Stake per ticket',
                      'Used for every "pays" figure',
                    ),
                  ),
                  _Segmented(
                    options: [for (final s in Settings.stakeOptions) '\$$s'],
                    selected: Settings.stakeOptions.indexOf(settings.stake),
                    onSelect: (i) =>
                        settings.setStake(Settings.stakeOptions[i]),
                  ),
                ],
              ),
              const Divider(height: 28),
              // Price source.
              Row(
                children: [
                  Expanded(
                    child: _label(
                      context,
                      'Price to use',
                      'Best price across bookmakers, or Bet365',
                    ),
                  ),
                  _Segmented(
                    options: const ['Best', 'Bet365'],
                    selected: settings.useBestPrice ? 0 : 1,
                    onSelect: (i) => settings.setUseBestPrice(i == 0),
                  ),
                ],
              ),
              const Divider(height: 28),
              // Weak leagues.
              Row(
                children: [
                  Expanded(
                    child: _label(
                      context,
                      'Leave out weak leagues',
                      'Serie A/B, Ligue 1/2, Eredivisie, lower Scottish leagues',
                    ),
                  ),
                  Switch(
                    value: settings.hideWeakLeagues,
                    activeThumbColor: p.onAccent,
                    activeTrackColor: p.accent,
                    onChanged: settings.setHideWeakLeagues,
                  ),
                ],
              ),
              const Divider(height: 28),
              // Data.
              Row(
                children: [
                  Expanded(
                    child: _label(
                      context,
                      'Data',
                      'football-data.co.uk · ${repo.updatedAt == null ? 'not loaded yet' : 'updated ${Format.time(repo.updatedAt!)}'}${repo.offline ? ' (saved copy)' : ''}',
                    ),
                  ),
                  OutlinedButton(
                    onPressed: repo.status == LoadStatus.loading
                        ? null
                        : () => repo.load(force: true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: p.text,
                      side: BorderSide(color: p.line),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Refresh'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Research tool, not betting advice. Nothing in this app places a bet.',
                style: TextStyle(color: p.faint, fontSize: 11.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String title, String sub) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: context.palette.text,
          fontSize: 14.5,
        ),
      ),
      Text(sub, style: TextStyle(color: context.palette.muted, fontSize: 12)),
    ],
  );
}

/// A round swatch split diagonally into the theme's background and accent.
class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.themeKey,
    required this.selected,
    required this.onTap,
  });
  final AppThemeKey themeKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final swatch = AppPalette.of(themeKey);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? p.accent : p.line, width: 2),
        ),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.5, 0.5],
                  colors: [swatch.background, swatch.accent],
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              themeKey.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: p.text,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact segmented buttons, e.g. $10 / $20 / $50.
class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.options,
    required this.selected,
    required this.onSelect,
  });
  final List<String> options;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.raised,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (index, option) in options.indexed)
            GestureDetector(
              onTap: () => onSelect(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: index == selected ? p.text : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontFamily: AppFonts.mono,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: index == selected ? p.background : p.muted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
