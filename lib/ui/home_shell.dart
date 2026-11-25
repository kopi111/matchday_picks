import 'dart:ui';

import 'package:flutter/material.dart';

import '../app/themes.dart';
import 'screens/learn_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/record_screen.dart';
import 'screens/today_screen.dart';

/// The four tabs with a floating, frosted bottom bar.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  static const _tabs = [
    (Icons.event_available_rounded, 'Today'),
    (Icons.sports_soccer_rounded, 'Matches'),
    (Icons.insights_rounded, 'Record'),
    (Icons.school_rounded, 'Learn'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      extendBody: true,
      // Keep each tab alive so scroll position and filters survive switching.
      body: IndexedStack(
        index: _tab,
        children: const [
          TodayScreen(),
          MatchesScreen(),
          RecordScreen(),
          LearnScreen(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: p.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: p.line),
              ),
              child: Row(
                children: [
                  for (final (index, tab) in _tabs.indexed)
                    Expanded(
                      child: InkResponse(
                        onTap: () => setState(() => _tab = index),
                        radius: 40,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // The selected tab gets a soft accent pill behind its icon.
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: index == _tab
                                    ? p.accent.withValues(alpha: 0.16)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Icon(
                                tab.$1,
                                size: 22,
                                color: index == _tab ? p.accent : p.faint,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              tab.$2,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: index == _tab ? p.accent : p.faint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
