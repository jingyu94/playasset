import 'package:flutter/material.dart';

import 'widgets/alerts_tab.dart';
import 'widgets/dashboard_tab.dart';
import 'widgets/fancy_background.dart';
import 'widgets/settings_tab.dart';
import 'widgets/watchlist_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      DashboardTab(),
      WatchlistTab(),
      AlertsTab(),
      SettingsTab(),
    ];

    return Scaffold(
      body: FancyBackground(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: SafeArea(
            key: ValueKey(_index),
            child: tabs[_index],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.space_dashboard_rounded), label: '대시보드'),
          NavigationDestination(icon: Icon(Icons.query_stats_rounded), label: '관심종목'),
          NavigationDestination(icon: Icon(Icons.notifications_active_rounded), label: '알림'),
          NavigationDestination(icon: Icon(Icons.tune_rounded), label: '설정'),
        ],
      ),
    );
  }
}
