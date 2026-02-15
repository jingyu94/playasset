import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_providers.dart';
import 'widgets/admin_tab.dart';
import 'widgets/alerts_tab.dart';
import 'widgets/dashboard_tab.dart';
import 'widgets/fancy_background.dart';
import 'widgets/settings_tab.dart';
import 'widgets/watchlist_tab.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(sessionControllerProvider).isAdmin;

    final tabs = <Widget>[
      const DashboardTab(),
      const WatchlistTab(),
      const AlertsTab(),
      const SettingsTab(),
      if (isAdmin) const AdminTab(),
    ];

    final destinations = <NavigationDestination>[
      const NavigationDestination(icon: Icon(Icons.space_dashboard_rounded), label: '대시보드'),
      const NavigationDestination(icon: Icon(Icons.query_stats_rounded), label: '관심종목'),
      const NavigationDestination(icon: Icon(Icons.notifications_active_rounded), label: '알림'),
      const NavigationDestination(icon: Icon(Icons.tune_rounded), label: '설정'),
      if (isAdmin) const NavigationDestination(icon: Icon(Icons.admin_panel_settings_rounded), label: '관리자'),
    ];

    if (_index >= tabs.length) {
      _index = 0;
    }

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
        destinations: destinations,
      ),
    );
  }
}
