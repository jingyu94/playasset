import 'dart:math' as math;
import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/dashboard_models.dart';
import 'complementary_accent.dart';
import '../home_providers.dart';

enum _DashboardGroup { status, diagnosis, recommendation }

class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> {
  _DashboardGroup _group = _DashboardGroup.status;

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final positionsAsync = ref.watch(positionsProvider);
    final watchlistAsync = ref.watch(watchlistProvider);
    final advisorAsync = ref.watch(advisorProvider);
    final watchlistSection = watchlistAsync.when(
      data: (watchlist) {
        final points = watchlist
            .map((e) => _MarketBarPoint(
                assetName: e.assetName,
                ticker: _normalizeTicker(e.symbol),
                changeRate: e.changeRate))
            .toList();
        return _TickerComparisonCard(points: points);
      },
      loading: () => dashboardAsync.when(
        data: (data) => _TickerComparisonCard(
          points: data.topMovers
              .map((e) => _MarketBarPoint(
                  assetName: e.assetName,
                  ticker: _normalizeTicker(e.symbol),
                  changeRate: e.changeRate))
              .toList(),
        ),
        loading: () => const _LoadingCard(height: 280),
        error: (e, _) => _ErrorCard(message: e.toString()),
      ),
      error: (_, __) => dashboardAsync.when(
        data: (data) => _TickerComparisonCard(
          points: data.topMovers
              .map((e) => _MarketBarPoint(
                  assetName: e.assetName,
                  ticker: _normalizeTicker(e.symbol),
                  changeRate: e.changeRate))
              .toList(),
        ),
        loading: () => const _LoadingCard(height: 280),
        error: (e, _) => _ErrorCard(message: e.toString()),
      ),
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardProvider);
        ref.invalidate(positionsProvider);
        ref.invalidate(watchlistProvider);
        ref.invalidate(advisorProvider);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
        children: [
          _Header(now: DateTime.now()),
          const SizedBox(height: 12),
          _ActionBriefCard(
            dashboardAsync: dashboardAsync,
            advisorAsync: advisorAsync,
          ),
          const SizedBox(height: 12),
          _DashboardGroupSelector(
            selected: _group,
            onChanged: (group) => setState(() => _group = group),
          ),
          const SizedBox(height: 14),
          ..._buildGroupSections(
            group: _group,
            dashboardAsync: dashboardAsync,
            positionsAsync: positionsAsync,
            advisorAsync: advisorAsync,
            watchlistSection: watchlistSection,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupSections({
    required _DashboardGroup group,
    required AsyncValue<DashboardData> dashboardAsync,
    required AsyncValue<List<PositionData>> positionsAsync,
    required AsyncValue<PortfolioAdviceData> advisorAsync,
    required Widget watchlistSection,
  }) {
    switch (group) {
      case _DashboardGroup.status:
        return [
          const _GroupIntroCard(
            title: '한눈에 보기',
            description: '총자산과 보유자산, 기간 수익 흐름부터 빠르게 확인해요.',
            icon: Icons.space_dashboard_rounded,
            accent: Color(0xFF5CA8FF),
          ),
          const SizedBox(height: 10),
          dashboardAsync.when(
            data: (data) => _HeroCard(data: data),
            loading: () => const _LoadingCard(height: 200),
            error: (e, _) => _ErrorCard(message: e.toString()),
          ),
          const SizedBox(height: 12),
          positionsAsync.when(
            data: (positions) => _HoldingAssetCard(positions: positions),
            loading: () => const _LoadingCard(height: 260),
            error: (e, _) => _ErrorCard(message: e.toString()),
          ),
          const SizedBox(height: 12),
          const _PortfolioSimulationCard(),
          const SizedBox(height: 12),
          watchlistSection,
        ];
      case _DashboardGroup.diagnosis:
        return [
          const _GroupIntroCard(
            title: '리스크 진단',
            description: '집중도와 변동성, 최대 낙폭을 기준으로 현재 상태를 읽어드려요.',
            icon: Icons.health_and_safety_rounded,
            accent: Color(0xFFFFC56B),
          ),
          const SizedBox(height: 10),
          positionsAsync.when(
            data: (positions) => dashboardAsync.when(
              data: (dashboard) =>
                  _InsightCard(positions: positions, dashboard: dashboard),
              loading: () => const _LoadingCard(height: 190),
              error: (e, _) => _ErrorCard(message: e.toString()),
            ),
            loading: () => const _LoadingCard(height: 190),
            error: (e, _) => _ErrorCard(message: e.toString()),
          ),
          const SizedBox(height: 12),
          advisorAsync.when(
            data: (advice) => _AdvisorSummaryCard(advice: advice),
            loading: () => const _LoadingCard(height: 210),
            error: (e, _) => _ErrorCard(message: e.toString()),
          ),
          const SizedBox(height: 12),
          positionsAsync.when(
            data: (positions) => advisorAsync.when(
              data: (advice) => _AdviceScenarioPreviewCard(
                  advice: advice, positions: positions),
              loading: () => const _LoadingCard(height: 280),
              error: (e, _) => _ErrorCard(message: e.toString()),
            ),
            loading: () => const _LoadingCard(height: 280),
            error: (e, _) => _ErrorCard(message: e.toString()),
          ),
        ];
      case _DashboardGroup.recommendation:
        return [
          const _GroupIntroCard(
            title: '실행 가이드',
            description: '리밸런싱과 ETF 대안을 비용/우선순위 중심으로 정리해드려요.',
            icon: Icons.bolt_rounded,
            accent: Color(0xFF65D6A5),
          ),
          const SizedBox(height: 10),
          advisorAsync.when(
            data: (advice) =>
                _RebalancingActionsCard(actions: advice.rebalancingActions),
            loading: () => const _LoadingCard(height: 220),
            error: (e, _) => _ErrorCard(message: e.toString()),
          ),
          const SizedBox(height: 12),
          advisorAsync.when(
            data: (advice) => _EtfRecommendationCard(
                recommendations: advice.etfRecommendations),
            loading: () => const _LoadingCard(height: 210),
            error: (e, _) => _ErrorCard(message: e.toString()),
          ),
        ];
    }
  }
}

class _DashboardGroupSelector extends StatelessWidget {
  const _DashboardGroupSelector({
    required this.selected,
    required this.onChanged,
  });

  final _DashboardGroup selected;
  final ValueChanged<_DashboardGroup> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background =
        isDark ? const Color(0xFF101B2F) : const Color(0xFFF4F8FF);
    final border = isDark ? const Color(0xFF233754) : const Color(0xFFD4DFEF);
    final selectedBg =
        isDark ? const Color(0x2A4C8DFF) : const Color(0x225E7FAF);
    final selectedBorder =
        isDark ? const Color(0xFF3A5F99) : const Color(0xFF90A7CA);
    final selectedText =
        isDark ? const Color(0xFFE8EEFF) : const Color(0xFF2B4369);
    final text = isDark ? const Color(0xFF90A0BE) : const Color(0xFF62738F);
    final subtleText =
        isDark ? const Color(0xFF6F83A8) : const Color(0xFF7687A2);

    Widget item({
      required _DashboardGroup value,
      required String label,
      required String caption,
      required IconData icon,
    }) {
      final active = selected == value;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              color: active ? selectedBg : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: active ? selectedBorder : Colors.transparent),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: active ? selectedText : text,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? selectedText : text,
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? selectedText.withOpacity(0.86) : subtleText,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          item(
            value: _DashboardGroup.status,
            label: '한눈에',
            caption: '요약',
            icon: Icons.stacked_line_chart_rounded,
          ),
          const SizedBox(width: 6),
          item(
            value: _DashboardGroup.diagnosis,
            label: '리스크',
            caption: '진단',
            icon: Icons.monitor_heart_rounded,
          ),
          const SizedBox(width: 6),
          item(
            value: _DashboardGroup.recommendation,
            label: '실행',
            caption: '추천',
            icon: Icons.auto_awesome_rounded,
          ),
        ],
      ),
    );
  }
}

class _ActionBriefCard extends StatelessWidget {
  const _ActionBriefCard({
    required this.dashboardAsync,
    required this.advisorAsync,
  });

  final AsyncValue<DashboardData> dashboardAsync;
  final AsyncValue<PortfolioAdviceData> advisorAsync;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? const Color(0xFFEAF1FF) : const Color(0xFF1A2A45);
    final subtitleColor =
        isDark ? const Color(0xFF9AA7C0) : const Color(0xFF5D6E89);

    final dashboard = dashboardAsync.valueOrNull;
    final advice = advisorAsync.valueOrNull;
    final briefLines = _buildBriefLines(dashboard: dashboard, advice: advice);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111E35) : const Color(0xFFF3F8FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF274065) : const Color(0xFFD2DEEE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0x224C8DFF)
                      : const Color(0x225E7FAF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '오늘 먼저 볼 내용',
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.bolt_rounded,
                  size: 16, color: Color(0xFFFFC56B)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '핵심 액션만 짧게 정리해뒀어요.',
            style: TextStyle(
              color: subtitleColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ...briefLines.map((line) => _BriefLine(text: line)),
        ],
      ),
    );
  }

  List<String> _buildBriefLines({
    required DashboardData? dashboard,
    required PortfolioAdviceData? advice,
  }) {
    final lines = <String>[];
    if (dashboard != null && dashboard.unreadAlertCount > 0) {
      lines.add('미확인 알림 ${dashboard.unreadAlertCount}건부터 확인해요.');
    }

    if (advice != null) {
      final concentration = advice.metrics.concentrationPct;
      if (concentration >= 40) {
        lines
            .add('상위 종목 비중이 ${concentration.toStringAsFixed(1)}%라 분할 조정이 좋아요.');
      } else if (advice.rebalancingActions.isNotEmpty) {
        lines.add('리밸런싱 ${advice.rebalancingActions.length}건 후보가 준비돼 있어요.');
      }
    }

    if (dashboard != null && dashboard.dailyPnlRate.abs() >= 2.0) {
      lines.add(
          '당일 변동이 ${dashboard.dailyPnlRate.toStringAsFixed(2)}%라 기준가 점검이 필요해요.');
    }

    if (lines.isEmpty) {
      lines.add('현재 지표는 안정 범위에 가까워요. 현 전략을 유지하면서 추세만 점검해요.');
    }
    return lines.take(3).toList();
  }
}

class _BriefLine extends StatelessWidget {
  const _BriefLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_rounded,
                size: 14, color: Color(0xFF65D6A5)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color:
                    isDark ? const Color(0xFFDDE7FF) : const Color(0xFF273956),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupIntroCard extends StatelessWidget {
  const _GroupIntroCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? const Color(0xFFE8EEFF) : const Color(0xFF1D2D4A);
    final descColor =
        isDark ? const Color(0xFF8EA0C1) : const Color(0xFF5E7291);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101A2E) : const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF263A5C) : const Color(0xFFD4DFEF),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  description,
                  style: TextStyle(
                    color: descColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mode = ref.watch(themeModeProvider);
    final formatter = DateFormat('M월 d일 (E) HH:mm', 'ko_KR');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '내 자산 대시보드',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8),
              ),
              const SizedBox(height: 3),
              Text(
                '${formatter.format(now)} 기준 실시간 집계',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF9AA7C0)
                      : const Color(0xFF5F6E88),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _ThemeModeMiniToggle(mode: mode),
        const SizedBox(width: 10),
        ComplementaryAccent(
          icon: Icons.auto_graph_rounded,
          primary: isDark ? const Color(0xFF59D6FF) : const Color(0xFF5E7FAF),
          secondary: isDark ? const Color(0xFFFF7A8B) : const Color(0xFF4AAE9B),
        ),
      ],
    );
  }
}

class _ThemeModeMiniToggle extends ConsumerWidget {
  const _ThemeModeMiniToggle({required this.mode});

  final ThemeMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDarkMode = mode == ThemeMode.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () async {
        await ref.read(themeModeProvider.notifier).setThemeMode(
              isDarkMode ? ThemeMode.light : ThemeMode.dark,
            );
      },
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF13233F) : const Color(0xFFE9F0FA),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isDark ? const Color(0xFF2A3D62) : const Color(0xFFD0DBEB),
          ),
        ),
        child: Icon(
          isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          size: 17,
          color: isDark ? const Color(0xFFEAF1FF) : const Color(0xFF2F4E79),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final won =
        NumberFormat.currency(locale: 'ko_KR', symbol: '₩', decimalDigits: 0);
    final profit = data.dailyPnl >= 0;
    final pnlColor = profit ? const Color(0xFFFF5D73) : const Color(0xFF5CA8FF);
    final titleColor =
        isDark ? const Color(0xFFF2F6FF) : const Color(0xFF111827);
    final subtleColor =
        isDark ? const Color(0xFF9AA7C0) : const Color(0xFF5B6C86);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF172746), Color(0xFF101D35), Color(0xFF0D172A)]
              : const [Color(0xFFF6FAFF), Color(0xFFECF3FC), Color(0xFFE4EDF8)],
        ),
        border: Border.all(
          color: isDark ? const Color(0xFF2D436C) : const Color(0xFFCBD7EA),
        ),
        boxShadow: [
          BoxShadow(
              color:
                  (isDark ? const Color(0x664C8DFF) : const Color(0x445E7FAF))
                      .withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0x224C8DFF)
                        : const Color(0x335E7FAF),
                    borderRadius: BorderRadius.circular(999)),
                child: Text(
                  '총 자산',
                  style:
                      TextStyle(fontWeight: FontWeight.w800, color: titleColor),
                ),
              ),
              const Spacer(),
              Icon(Icons.insights_rounded, color: pnlColor, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(won.format(data.portfolioValue),
              style: TextStyle(
                  fontSize: 33,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: titleColor)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF0F1B31) : const Color(0xFFF7FBFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark
                        ? const Color(0xFF2A3B5A)
                        : const Color(0xFFD1DDEE))),
            child: Row(
              children: [
                Text('당일 평가손익',
                    style: TextStyle(
                        color: subtleColor, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(
                  '${profit ? '+' : ''}${won.format(data.dailyPnl)} (${profit ? '+' : ''}${data.dailyPnlRate.toStringAsFixed(2)}%)',
                  style:
                      TextStyle(color: pnlColor, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _kpi('관심종목', '${data.watchlistCount}개', isDark)),
              const SizedBox(width: 8),
              Expanded(
                  child: _kpi('미확인 알림', '${data.unreadAlertCount}건', isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpi(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF101D33) : const Color(0xFFF7FBFF),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
              color:
                  isDark ? const Color(0xFF273A58) : const Color(0xFFD1DDEE))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Color(0xFF8EA0C1), fontSize: 12)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _TickerComparisonCard extends StatefulWidget {
  const _TickerComparisonCard({required this.points});

  final List<_MarketBarPoint> points;

  @override
  State<_TickerComparisonCard> createState() => _TickerComparisonCardState();
}

class _TickerComparisonCardState extends State<_TickerComparisonCard> {
  static const int _initialVisibleLimit = 4;

  int? _selectedIndex;
  int _visibleCount = 0;

  @override
  void initState() {
    super.initState();
    _visibleCount = _initialCount(widget.points.length);
  }

  @override
  void didUpdateWidget(covariant _TickerComparisonCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.points.length != oldWidget.points.length) {
      if (_visibleCount == 0) {
        _visibleCount = _initialCount(widget.points.length);
      } else {
        _visibleCount = math.max(_initialCount(widget.points.length),
            math.min(_visibleCount, widget.points.length));
      }
    }
    final activeCount = _activePointCount();
    if (_selectedIndex != null && _selectedIndex! >= activeCount) {
      _selectedIndex = activeCount == 0 ? null : activeCount - 1;
    }
  }

  void _updateIndexByDx(double dx, double width) {
    final activeCount = _activePointCount();
    if (activeCount == 0 || width <= 0) return;
    final ratio = (dx / width).clamp(0.0, 0.999999);
    final index = (ratio * activeCount).floor().clamp(0, activeCount - 1);
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
  }

  void _clearSelection() {
    if (_selectedIndex != null) {
      setState(() => _selectedIndex = null);
    }
  }

  void _expand() {
    final next = widget.points.length;
    if (next != _visibleCount) {
      setState(() => _visibleCount = next);
    }
  }

  void _collapse() {
    final initial = _initialCount(widget.points.length);
    if (_visibleCount != initial) {
      setState(() {
        _visibleCount = initial;
        if (_selectedIndex != null && _selectedIndex! >= _visibleCount) {
          _selectedIndex = null;
        }
      });
    }
  }

  int _initialCount(int total) => math.min(_initialVisibleLimit, total);

  int _activePointCount() => math.min(_visibleCount, widget.points.length);

  @override
  Widget build(BuildContext context) {
    final sortedPoints = [...widget.points]
      ..sort((a, b) => b.changeRate.abs().compareTo(a.changeRate.abs()));
    final points = sortedPoints.take(_activePointCount()).toList();
    if (points.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Text('등락률 비교 데이터가 없습니다.'),
        ),
      );
    }

    final scale = _buildScale(points);
    final selected = _selectedIndex != null && _selectedIndex! < points.length
        ? points[_selectedIndex!]
        : null;
    final canExpand = _visibleCount < sortedPoints.length;
    final canCollapse = _visibleCount > _initialCount(sortedPoints.length);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('관심종목 당일 변동 요약 TOP ${points.length}',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(width: 8),
                _TopCountBadge(label: '총 ${sortedPoints.length}종목'),
              ],
            ),
            const SizedBox(height: 4),
            const Text('보조 지표예요. 세로축은 당일 등락률(%)이고, 가로축은 종목명(티커) 기준이에요.',
                style: TextStyle(color: Color(0xFF8EA0C1), fontSize: 12)),
            const SizedBox(height: 10),
            SizedBox(
              height: 172,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          minY: -scale.bound,
                          maxY: scale.bound,
                          baselineY: 0,
                          barTouchData: BarTouchData(
                            enabled: true,
                            handleBuiltInTouches: false,
                            touchTooltipData: BarTouchTooltipData(
                              tooltipRoundedRadius: 10,
                              getTooltipColor: (_) => const Color(0xFF1A2740),
                              tooltipPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              getTooltipItem: (group, _, rod, __) {
                                final point = points[group.x.toInt()];
                                final sign = point.changeRate >= 0 ? '+' : '';
                                return BarTooltipItem(
                                  '${point.assetName} (${point.ticker})\n$sign${point.changeRate.toStringAsFixed(2)}%',
                                  const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12),
                                );
                              },
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            verticalInterval: 1,
                            horizontalInterval: scale.interval,
                            getDrawingHorizontalLine: (value) {
                              if (value == 0) {
                                return const FlLine(
                                    color: Color(0x554C8DFF), strokeWidth: 1.2);
                              }
                              return const FlLine(
                                  color: Color(0x202B3B58), strokeWidth: 1);
                            },
                            getDrawingVerticalLine: (value) {
                              return const FlLine(
                                color: Color(0x1E3E5B86),
                                strokeWidth: 1,
                                dashArray: [3, 6],
                              );
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 44,
                                getTitlesWidget: (value, meta) {
                                  final show =
                                      (value % scale.interval).abs() < 0.001 ||
                                          (value % scale.interval).abs() >
                                              (scale.interval - 0.001);
                                  if (!show) return const SizedBox.shrink();
                                  return Text(
                                      _formatPercent(value, scale.interval),
                                      style: const TextStyle(
                                          color: Color(0xFF8EA0C1),
                                          fontSize: 11));
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 52,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx < 0 || idx >= points.length)
                                    return const SizedBox.shrink();
                                  final selectedPoint =
                                      _selectedIndex != null &&
                                          idx == _selectedIndex;
                                  final label =
                                      _shortName(points[idx].assetName);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: SizedBox(
                                      width: 82,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: selectedPoint
                                                  ? const Color(0xFFE8EEFF)
                                                  : const Color(0xFF8EA0C1),
                                              fontWeight: selectedPoint
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              fontSize: 11,
                                            ),
                                          ),
                                          Text(
                                            '(${points[idx].ticker})',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: selectedPoint
                                                  ? const Color(0xFFE8EEFF)
                                                  : const Color(0xFF7E90B2),
                                              fontWeight: selectedPoint
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups: [
                            for (int i = 0; i < points.length; i++)
                              BarChartGroupData(
                                x: i,
                                showingTooltipIndicators:
                                    _selectedIndex != null &&
                                            i == _selectedIndex
                                        ? const [0]
                                        : const [],
                                barRods: [
                                  BarChartRodData(
                                    toY: points[i].changeRate,
                                    width: 16,
                                    borderRadius: BorderRadius.circular(4),
                                    color: points[i].changeRate >= 0
                                        ? const Color(0xFFFF6B81)
                                        : const Color(0xFF5CA8FF),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      Positioned.fill(
                        child: MouseRegion(
                          onHover: (event) => _updateIndexByDx(
                              event.localPosition.dx, constraints.maxWidth),
                          onExit: (_) => _clearSelection(),
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTapDown: (details) => _updateIndexByDx(
                                details.localPosition.dx, constraints.maxWidth),
                            onHorizontalDragDown: (details) => _updateIndexByDx(
                                details.localPosition.dx, constraints.maxWidth),
                            onHorizontalDragUpdate: (details) =>
                                _updateIndexByDx(details.localPosition.dx,
                                    constraints.maxWidth),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                  color: const Color(0xFF14233E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2A3E63))),
              child: selected == null
                  ? const Text(
                      '차트 위에 마우스를 올리면 종목별 당일 등락률을 확인할 수 있습니다.',
                      style: TextStyle(
                          color: Color(0xFF8EA0C1),
                          fontWeight: FontWeight.w700),
                    )
                  : Text(
                      '선택 종목: ${selected.assetName} (${selected.ticker}) / 당일 등락률 ${selected.changeRate >= 0 ? '+' : ''}${selected.changeRate.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: selected.changeRate >= 0
                            ? const Color(0xFFFF6B81)
                            : const Color(0xFF5CA8FF),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
            if (sortedPoints.length > _initialCount(sortedPoints.length))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _ProgressiveRevealControl(
                  canExpand: canExpand,
                  canCollapse: canCollapse,
                  remainingCount: sortedPoints.length - _visibleCount,
                  onExpand: _expand,
                  onCollapse: _collapse,
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _maxAbs(List<_MarketBarPoint> points) {
    double maxAbs = 0;
    for (final p in points) {
      final v = p.changeRate.abs();
      if (v > maxAbs) maxAbs = v;
    }
    return maxAbs;
  }

  _AxisScale _buildScale(List<_MarketBarPoint> points) {
    final maxAbs = _maxAbs(points).abs();
    if (maxAbs <= 0.2) {
      return const _AxisScale(bound: 1.0, interval: 0.5);
    }

    final rough = maxAbs / 2;
    final power = (math.log(rough) / math.ln10).floor();
    final exponent = math.pow(10, power).toDouble();
    final normalized = rough / exponent;
    double nice;
    if (normalized <= 1.5) {
      nice = 1;
    } else if (normalized <= 3) {
      nice = 2;
    } else if (normalized <= 7) {
      nice = 5;
    } else {
      nice = 10;
    }
    final interval = nice * exponent;
    final bound = interval * 3;
    return _AxisScale(bound: bound, interval: interval);
  }

  String _formatPercent(double value, double interval) {
    final decimals = interval < 1 ? 1 : 0;
    return '${value.toStringAsFixed(decimals)}%';
  }

  String _shortName(String name) {
    if (name.length <= 8) return name;
    return '${name.substring(0, 8)}…';
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.positions, required this.dashboard});

  final List<PositionData> positions;
  final DashboardData dashboard;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileBg = isDark ? const Color(0xFF12213A) : const Color(0xFFF7FCFA);
    final tileBorder =
        isDark ? const Color(0xFF2A3E63) : const Color(0xFFD0E4DE);
    final labelText =
        isDark ? const Color(0xFF8EA0C1) : const Color(0xFF5D7A7E);
    final bodyText = isDark ? const Color(0xFFE8EEFF) : const Color(0xFF1E3742);
    final hintText = isDark ? const Color(0xFFDCE5F8) : const Color(0xFF355056);
    final sectionTitle =
        isDark ? const Color(0xFFF2F6FF) : const Color(0xFF1E3742);
    final badgeBg = isDark ? const Color(0x22FFC56B) : const Color(0x26F3B54E);
    final badgeBorder =
        isDark ? const Color(0x66FFC56B) : const Color(0x66C9892A);
    final badgeText =
        isDark ? const Color(0xFFFFDFA2) : const Color(0xFF9A6008);

    final total = positions.fold<double>(0, (sum, p) => sum + p.valuation);
    final sorted = [...positions]
      ..sort((a, b) => b.valuation.compareTo(a.valuation));
    final top = sorted.isNotEmpty ? sorted.first : null;
    final topRatio =
        total > 0 && top != null ? (top.valuation / total) * 100 : 0.0;

    final riskLevel = topRatio >= 45
        ? '한 종목 쏠림 높음'
        : topRatio >= 30
            ? '집중도 주의'
            : '분산 양호';

    final action1 = top == null
        ? '보유 종목이 없습니다.'
        : '최대 비중 종목 ${top.assetName} ${topRatio.toStringAsFixed(1)}%: 목표 비중을 정해 분할 조정';
    final action2 = dashboard.unreadAlertCount > 0
        ? '미확인 알림 ${dashboard.unreadAlertCount}건 우선 처리'
        : '미확인 알림 없음, 상태 양호';
    final action3 = dashboard.dailyPnlRate.abs() >= 2
        ? '일중 변동폭 ${dashboard.dailyPnlRate.toStringAsFixed(2)}%: 익절/손절 기준 재점검'
        : '변동폭 안정 구간, 비중 리밸런싱 위주 점검';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('포트폴리오 리스크 진단',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _metric(
                        '최대 보유 종목 비중',
                        top == null ? '-' : '${topRatio.toStringAsFixed(1)}%',
                        topRatio >= 45
                            ? const Color(0xFFFF6B81)
                            : const Color(0xFF4C8DFF),
                        tileBg: tileBg,
                        tileBorder: tileBorder,
                        labelText: labelText)),
                const SizedBox(width: 8),
                Expanded(
                    child: _metric('분산 투자 상태', riskLevel, _riskColor(riskLevel),
                        tileBg: tileBg,
                        tileBorder: tileBorder,
                        labelText: labelText)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                  color: tileBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tileBorder)),
              child: Text('설명: 최대 비중이 45%를 넘으면 포트폴리오 변동성이 급격히 커질 수 있습니다.',
                  style:
                      TextStyle(color: bodyText, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.bolt_rounded,
                    color: Color(0xFFFFC56B), size: 18),
                const SizedBox(width: 6),
                Text('추천 액션',
                    style: TextStyle(
                        fontWeight: FontWeight.w900, color: sectionTitle)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: badgeBorder),
                  ),
                  child: Text(
                    '우선순위',
                    style: TextStyle(
                      color: badgeText,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _action(action1, priority: 0, isDark: isDark, bodyText: hintText),
            _action(action2, priority: 1, isDark: isDark, bodyText: hintText),
            _action(action3, priority: 2, isDark: isDark, bodyText: hintText),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, Color valueColor,
      {required Color tileBg,
      required Color tileBorder,
      required Color labelText}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
          color: tileBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tileBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: labelText, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(color: valueColor, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Color _riskColor(String riskLevel) {
    if (riskLevel.contains('높음')) return const Color(0xFFFF6B81);
    if (riskLevel.contains('주의')) return const Color(0xFFFFC56B);
    return const Color(0xFF6FB0FF);
  }

  Widget _action(String text,
      {required int priority, required bool isDark, required Color bodyText}) {
    final accent = switch (priority) {
      0 => const Color(0xFFFFC56B),
      1 => const Color(0xFF59D6FF),
      _ => const Color(0xFF7BD88F),
    };
    final icon = switch (priority) {
      0 => Icons.local_fire_department_rounded,
      1 => Icons.notifications_active_rounded,
      _ => Icons.check_circle_outline_rounded,
    };
    final label = switch (priority) {
      0 => '가장 먼저',
      1 => '다음으로',
      _ => '유지 점검',
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withOpacity(isDark ? 0.45 : 0.4)),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [accent.withOpacity(isDark ? 0.16 : 0.1), Colors.transparent],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 1),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 13, color: accent),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: TextStyle(color: bodyText, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvisorSummaryCard extends StatelessWidget {
  const _AdvisorSummaryCard({required this.advice});

  final PortfolioAdviceData advice;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleText =
        isDark ? const Color(0xFFE8EEFF) : const Color(0xFF1E3742);
    final summaryText =
        isDark ? const Color(0xFF9AA7C0) : const Color(0xFF5D7A7E);
    final tileBg = isDark ? const Color(0xFF12213A) : const Color(0xFFF7FCFA);
    final tileBorder =
        isDark ? const Color(0xFF2A3E63) : const Color(0xFFD0E4DE);
    final tileLabel =
        isDark ? const Color(0xFF8EA0C1) : const Color(0xFF5D7A7E);
    final sectionText =
        isDark ? const Color(0xFFDDE7FF) : const Color(0xFF1E3742);
    final bulletBody =
        isDark ? const Color(0xFFDCE5F8) : const Color(0xFF355056);

    final m = advice.metrics;
    final normalizedRisk = _normalizeRiskLabel(m.riskLevel);
    final isStableMode = advice.insight.headline.contains('안정') ||
        advice.insight.summary.contains('운영 전략') ||
        normalizedRisk.contains('낮음');
    final riskColor = m.riskLevel.contains('높음')
        ? const Color(0xFFFF6B81)
        : m.riskLevel.contains('보통')
            ? const Color(0xFFFFC56B)
            : const Color(0xFF65D6A5);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('AI 포트폴리오 진단',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: riskColor.withOpacity(0.45)),
                  ),
                  child: Text(
                    normalizedRisk,
                    style: TextStyle(
                        color: riskColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              advice.insight.headline,
              style: TextStyle(fontWeight: FontWeight.w800, color: titleText),
            ),
            const SizedBox(height: 4),
            Text(
              advice.insight.summary,
              style: TextStyle(color: summaryText, height: 1.35),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _metric(
                    '샤프지수',
                    m.sharpeRatio.toStringAsFixed(2),
                    const Color(0xFF65D6A5),
                    tileBg: tileBg,
                    tileBorder: tileBorder,
                    labelText: tileLabel,
                    helpText: '같은 위험에서 수익을 얼마나 효율적으로 냈는지 보여줘요.',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metric(
                    '연환산 변동성',
                    '${m.annualVolatilityPct.toStringAsFixed(1)}%',
                    const Color(0xFFFFC56B),
                    tileBg: tileBg,
                    tileBorder: tileBorder,
                    labelText: tileLabel,
                    helpText: '수익률이 얼마나 크게 흔들리는지 보여줘요.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _metric(
                    '최대 낙폭(MDD)',
                    '${m.maxDrawdownPct.toStringAsFixed(1)}%',
                    const Color(0xFFFF6B81),
                    tileBg: tileBg,
                    tileBorder: tileBorder,
                    labelText: tileLabel,
                    helpText:
                        '고점 대비 가장 크게 빠진 구간이에요. 위기 구간에서 버틸 수 있는지 보는 핵심 지표예요.',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metric(
                    '분산 점수',
                    '${m.diversificationScore.toStringAsFixed(1)}점',
                    const Color(0xFF5CA8FF),
                    tileBg: tileBg,
                    tileBorder: tileBorder,
                    labelText: tileLabel,
                    helpText: '자산이 한쪽에 몰리지 않았는지 보여주는 지표예요.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isStableMode
                    ? const Color(0x1A65D6A5)
                    : const Color(0x1A5CA8FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isStableMode
                        ? const Color(0x5565D6A5)
                        : const Color(0x553E6CB0)),
              ),
              child: Text(
                isStableMode
                    ? '지금은 구조 변경보다 운영 전략 중심이 더 효율적이에요.'
                    : '지금은 비중 조정/리스크 완화 액션을 먼저 보는 게 좋아요.',
                style: TextStyle(
                  color: isDark
                      ? (isStableMode
                          ? const Color(0xFFB9F5DD)
                          : const Color(0xFFBAD2FF))
                      : const Color(0xFF355056),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isStableMode ? '운영 전략' : '우선 액션',
              style: TextStyle(fontWeight: FontWeight.w800, color: sectionText),
            ),
            const SizedBox(height: 6),
            ...advice.insight.keyPoints.take(4).toList().asMap().entries.map(
                  (entry) => _bullet(entry.value,
                      order: entry.key,
                      isStableMode: isStableMode,
                      isDark: isDark,
                      bodyText: bulletBody),
                ),
            if (advice.insight.cautions.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: tileBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tileBorder),
                ),
                child: Text(
                  advice.insight.cautions.first,
                  style:
                      TextStyle(color: summaryText, height: 1.35, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, Color valueColor,
      {required Color tileBg,
      required Color tileBorder,
      required Color labelText,
      String? helpText}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tileBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: TextStyle(color: labelText, fontSize: 12)),
              ),
              if (helpText != null)
                _InfoBubbleIcon(
                  title: label,
                  message: helpText,
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(color: valueColor, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _bullet(String text,
      {required int order,
      required bool isStableMode,
      required bool isDark,
      required Color bodyText}) {
    final accent = isStableMode
        ? const [Color(0xFF65D6A5), Color(0xFF59D6FF), Color(0xFF8EC7FF)]
        : const [Color(0xFFFFC56B), Color(0xFFFF8A6B), Color(0xFF59D6FF)];
    final icon = isStableMode
        ? const [
            Icons.track_changes_rounded,
            Icons.show_chart_rounded,
            Icons.verified_rounded,
          ]
        : const [
            Icons.priority_high_rounded,
            Icons.tune_rounded,
            Icons.checklist_rounded,
          ];
    final idx = order.clamp(0, 2);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: accent[idx].withOpacity(isDark ? 0.44 : 0.36)),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            accent[idx].withOpacity(isDark ? 0.16 : 0.1),
            Colors.transparent
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon[idx], size: 15, color: accent[idx]),
          ),
          const SizedBox(width: 8),
          Expanded(
              child:
                  Text(text, style: TextStyle(color: bodyText, height: 1.35))),
        ],
      ),
    );
  }
}

enum _AdviceScenarioType { rebalancing, etf, combined }

class _AdviceScenarioProjection {
  const _AdviceScenarioProjection({
    required this.type,
    required this.label,
    required this.summary,
    required this.metrics,
    required this.accent,
    required this.badge,
  });

  final _AdviceScenarioType type;
  final String label;
  final String summary;
  final AdviceMetricsData metrics;
  final Color accent;
  final String badge;
}

class _AdviceMetricsDelta {
  const _AdviceMetricsDelta({
    this.expectedAnnualReturnPct = 0,
    this.annualVolatilityPct = 0,
    this.sharpeRatio = 0,
    this.maxDrawdownPct = 0,
    this.concentrationPct = 0,
    this.diversificationScore = 0,
  });

  final double expectedAnnualReturnPct;
  final double annualVolatilityPct;
  final double sharpeRatio;
  final double maxDrawdownPct;
  final double concentrationPct;
  final double diversificationScore;
}

class _AdviceScenarioPreviewCard extends StatefulWidget {
  const _AdviceScenarioPreviewCard({
    required this.advice,
    required this.positions,
  });

  final PortfolioAdviceData advice;
  final List<PositionData> positions;

  @override
  State<_AdviceScenarioPreviewCard> createState() =>
      _AdviceScenarioPreviewCardState();
}

class _AdviceScenarioPreviewCardState
    extends State<_AdviceScenarioPreviewCard> {
  static const int _initialHoldingLimit = 5;

  _AdviceScenarioType? _hoveredScenario;
  _AdviceScenarioType? _pinnedScenario;
  Timer? _hoverExitTimer;
  int _visibleHoldingCount = _initialHoldingLimit;

  _AdviceScenarioType? get _activeScenario =>
      _hoveredScenario ?? _pinnedScenario;

  bool get _preferHover {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  @override
  void dispose() {
    _hoverExitTimer?.cancel();
    super.dispose();
  }

  void _onEnterScenario(_AdviceScenarioType scenario) {
    if (!_preferHover) return;
    _hoverExitTimer?.cancel();
    if (_hoveredScenario != scenario) {
      setState(() {
        _hoveredScenario = scenario;
        _visibleHoldingCount = _initialHoldingLimit;
      });
    }
  }

  void _onExitScenario(_AdviceScenarioType scenario) {
    if (!_preferHover) return;
    _hoverExitTimer?.cancel();
    _hoverExitTimer = Timer(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      if (_hoveredScenario == scenario) {
        setState(() => _hoveredScenario = null);
      }
    });
  }

  void _togglePinnedScenario(_AdviceScenarioType scenario) {
    setState(() {
      _pinnedScenario = _pinnedScenario == scenario ? null : scenario;
      _visibleHoldingCount = _initialHoldingLimit;
    });
  }

  void _expandHoldings(int total) {
    if (_visibleHoldingCount != total) {
      setState(() => _visibleHoldingCount = total);
    }
  }

  void _collapseHoldings() {
    if (_visibleHoldingCount != _initialHoldingLimit) {
      setState(() => _visibleHoldingCount = _initialHoldingLimit);
    }
  }

  double _scenarioCardWidth(double maxWidth) {
    if (maxWidth >= 720) {
      return (maxWidth - 16) / 3;
    }
    if (maxWidth >= 460) {
      return (maxWidth - 8) / 2;
    }
    return maxWidth;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelBg = isDark ? const Color(0xFF112038) : const Color(0xFFF2FAF7);
    final panelInnerBg =
        isDark ? const Color(0xFF12213A) : const Color(0xFFF7FCFA);
    final panelActiveBg =
        isDark ? const Color(0xFF183058) : const Color(0xFFEAF5F4);
    final panelBorder =
        isDark ? const Color(0xFF2A3E63) : const Color(0xFFD0E4DE);
    final titleText =
        isDark ? const Color(0xFFEAF1FF) : const Color(0xFF18313B);
    final bodyText = isDark ? const Color(0xFFD3DCF0) : const Color(0xFF2D4850);
    final mutedText =
        isDark ? const Color(0xFF9AA7C0) : const Color(0xFF5F7A7B);
    final buttonText =
        isDark ? const Color(0xFF9FB3D8) : const Color(0xFF3D6775);

    final base = widget.advice.metrics;
    final projections = _buildAdviceScenarioProjections(widget.advice);
    final orderedProjections = [
      projections[_AdviceScenarioType.rebalancing]!,
      projections[_AdviceScenarioType.etf]!,
      projections[_AdviceScenarioType.combined]!,
    ];
    final activeScenario = _activeScenario;
    final activeProjection =
        activeScenario == null ? null : projections[activeScenario];
    final projected = activeProjection?.metrics ?? base;
    final projectionTitle = activeProjection?.label ?? '현재 포트폴리오 진단';
    final projectionSummary = activeProjection?.summary ??
        '카드에 마우스를 올리거나 탭하면 시나리오별 변화값을 미리 확인할 수 있습니다.';
    final actionBuyAmount = widget.advice.rebalancingActions
        .where((action) => action.action == 'BUY')
        .fold<double>(0, (sum, action) => sum + action.suggestedAmount);
    final actionSellAmount = widget.advice.rebalancingActions
        .where((action) => action.action != 'BUY')
        .fold<double>(0, (sum, action) => sum + action.suggestedAmount);
    final etfTradeAmount = base.totalValue *
        (widget.advice.etfRecommendations.fold<double>(
              0,
              (sum, etf) => sum + etf.suggestedWeightPct,
            ) /
            100);
    final double scenarioBuyAmount = switch (activeScenario) {
      _AdviceScenarioType.rebalancing => actionBuyAmount,
      _AdviceScenarioType.etf => etfTradeAmount,
      _AdviceScenarioType.combined => actionBuyAmount + etfTradeAmount,
      null => 0.0,
    };
    final double scenarioSellAmount = switch (activeScenario) {
      _AdviceScenarioType.rebalancing => actionSellAmount,
      _AdviceScenarioType.etf => etfTradeAmount,
      _AdviceScenarioType.combined => actionSellAmount + etfTradeAmount,
      null => 0.0,
    };
    final projectedHoldingsByScenario = _buildProjectedHoldingsByScenario(
      positions: widget.positions,
      advice: widget.advice,
      totalReferenceValue: base.totalValue,
    );
    final holdingPreview = activeScenario == null
        ? _buildHoldingPreviewFromPositions(widget.positions)
        : projectedHoldingsByScenario[activeScenario] ??
            const <_ScenarioHoldingPreview>[];
    final visibleHoldingCount =
        math.min(_visibleHoldingCount, holdingPreview.length);
    final displayedHolding = holdingPreview.take(visibleHoldingCount).toList();
    final canExpand = visibleHoldingCount < holdingPreview.length;
    final canCollapse = holdingPreview.length > _initialHoldingLimit &&
        visibleHoldingCount > _initialHoldingLimit;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('리밸런싱/ETF 반영 변화 미리보기',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                ),
                if (_pinnedScenario != null)
                  TextButton.icon(
                    onPressed: () => setState(() => _pinnedScenario = null),
                    style: TextButton.styleFrom(
                      foregroundColor: buttonText,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.lock_open_rounded, size: 16),
                    label: const Text('선택 해제'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 34),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: Text(
                  projectionSummary,
                  key: ValueKey(projectionSummary),
                  style:
                      TextStyle(color: mutedText, fontSize: 12, height: 1.35),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: panelBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: panelBorder),
              ),
              child: Row(
                children: [
                  Text(
                    '예상 주문',
                    style: TextStyle(
                      color: mutedText,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (scenarioBuyAmount == 0 && scenarioSellAmount == 0)
                    Text(
                      '현재 기준 주문 변동 없음',
                      style: TextStyle(
                        color: bodyText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else ...[
                    _tradeFlowChip(
                      label: '매수',
                      amount: scenarioBuyAmount,
                      color: const Color(0xFF5CA8FF),
                      icon: Icons.add_shopping_cart_rounded,
                    ),
                    const SizedBox(width: 6),
                    _tradeFlowChip(
                      label: '매도',
                      amount: scenarioSellAmount,
                      color: const Color(0xFFFF6B81),
                      icon: Icons.sell_rounded,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = _scenarioCardWidth(constraints.maxWidth);
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: orderedProjections.map((projection) {
                    final active = activeScenario == projection.type;
                    final pinned = _pinnedScenario == projection.type;
                    return SizedBox(
                      width: cardWidth,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        onEnter: (_) => _onEnterScenario(projection.type),
                        onExit: (_) => _onExitScenario(projection.type),
                        child: GestureDetector(
                          onTap: () => _togglePinnedScenario(projection.type),
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 9),
                            decoration: BoxDecoration(
                              color: active ? panelActiveBg : panelInnerBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: active
                                    ? projection.accent.withOpacity(0.86)
                                    : panelBorder,
                                width: 1,
                              ),
                              boxShadow: active
                                  ? [
                                      BoxShadow(
                                        color:
                                            projection.accent.withOpacity(0.18),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        projection.label,
                                        style: TextStyle(
                                          color: active ? titleText : bodyText,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    if (pinned)
                                      const Icon(Icons.push_pin_rounded,
                                          size: 14, color: Color(0xFF74A9C0)),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  projection.badge,
                                  style: TextStyle(
                                      color: projection.accent,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: panelBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: panelBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      projectionTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: activeProjection == null
                            ? bodyText
                            : activeProjection.accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _riskBadge(_normalizeRiskLabel(base.riskLevel)),
                  if (activeProjection != null) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward_rounded,
                          size: 16, color: Color(0xFF7A9CA1)),
                    ),
                    _riskBadge(_normalizeRiskLabel(projected.riskLevel)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _AdviceMetricDeltaTile(
                  title: '기대 연수익률',
                  before: base.expectedAnnualReturnPct,
                  after: projected.expectedAnnualReturnPct,
                  decimals: 2,
                  unit: '%',
                  helpText: '현재 구성으로 1년 운용 시 기대하는 평균 수익률이에요.',
                ),
                _AdviceMetricDeltaTile(
                  title: '연환산 변동성',
                  before: base.annualVolatilityPct,
                  after: projected.annualVolatilityPct,
                  decimals: 2,
                  unit: '%',
                  helpText: '수익률 변동 폭의 크기예요.',
                ),
                _AdviceMetricDeltaTile(
                  title: '샤프지수',
                  before: base.sharpeRatio,
                  after: projected.sharpeRatio,
                  decimals: 2,
                  unit: '',
                  helpText: '위험 대비 수익 효율을 보여줘요.',
                ),
                _AdviceMetricDeltaTile(
                  title: '최대 낙폭(MDD)',
                  before: base.maxDrawdownPct,
                  after: projected.maxDrawdownPct,
                  decimals: 2,
                  unit: '%',
                  helpText: '과거 가장 크게 빠졌던 구간의 하락률이에요.',
                ),
                _AdviceMetricDeltaTile(
                  title: '최대 종목 비중',
                  before: base.concentrationPct,
                  after: projected.concentrationPct,
                  decimals: 2,
                  unit: '%',
                  helpText: '포트에서 가장 큰 단일 종목 비중이에요.',
                ),
                _AdviceMetricDeltaTile(
                  title: '분산투자 점수',
                  before: base.diversificationScore,
                  after: projected.diversificationScore,
                  decimals: 1,
                  unit: '점',
                  helpText: '섹터/자산군이 얼마나 고르게 퍼졌는지 보여줘요.',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    activeScenario == null ? '현재 보유 구성' : '반영 후 보유 구성',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: isDark
                          ? const Color(0xFFEAF1FF)
                          : const Color(0xFF18313B),
                    ),
                  ),
                ),
                if (activeScenario != null)
                  Text(
                    '${activeProjection?.label ?? ''} 기준',
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (displayedHolding.isEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  color: panelBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: panelBorder),
                ),
                child: Text(
                  '표시할 종목 데이터가 아직 없어요.',
                  style: TextStyle(
                    color: mutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: panelBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: panelBorder),
                ),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: Column(
                    children: [
                      for (int i = 0; i < displayedHolding.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: panelBorder,
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 9),
                          child: _holdingPreviewTile(displayedHolding[i]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            if (holdingPreview.length > _initialHoldingLimit)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _ProgressiveRevealControl(
                  canExpand: canExpand,
                  canCollapse: canCollapse,
                  remainingCount: holdingPreview.length - visibleHoldingCount,
                  onExpand: () => _expandHoldings(holdingPreview.length),
                  onCollapse: _collapseHoldings,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _holdingPreviewTile(_ScenarioHoldingPreview item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleText =
        isDark ? const Color(0xFFE8EEFF) : const Color(0xFF18313B);
    final subText = isDark ? const Color(0xFF8EA0C1) : const Color(0xFF5D7A7E);
    final valueText =
        isDark ? const Color(0xFFF3F6FF) : const Color(0xFF1E3742);

    final won =
        NumberFormat.currency(locale: 'ko_KR', symbol: '₩', decimalDigits: 0);
    final delta = item.afterValue - item.beforeValue;
    final changeAbsText = won.format(delta.abs());
    final String actionLabel;
    final Color actionColor;
    final IconData actionIcon;

    if (item.beforeValue <= 1 && item.afterValue > 1) {
      actionLabel = '신규 편입';
      actionColor = const Color(0xFF65D6A5);
      actionIcon = Icons.playlist_add_rounded;
    } else if (item.afterValue <= 1 && item.beforeValue > 1) {
      actionLabel = '편출';
      actionColor = const Color(0xFFFF6B81);
      actionIcon = Icons.remove_circle_outline_rounded;
    } else if (delta > 0) {
      actionLabel = '매수 확대';
      actionColor = const Color(0xFF5CA8FF);
      actionIcon = Icons.trending_up_rounded;
    } else if (delta < 0) {
      actionLabel = '매도 조정';
      actionColor = const Color(0xFFFF6B81);
      actionIcon = Icons.trending_down_rounded;
    } else {
      actionLabel = '유지';
      actionColor = const Color(0xFF9AA7C0);
      actionIcon = Icons.drag_handle_rounded;
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.assetName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: titleText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    item.symbol,
                    style: TextStyle(
                      color: subText,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              won.format(item.afterValue),
              style: TextStyle(
                color: valueText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                '현재 ${won.format(item.beforeValue)} → 반영 ${won.format(item.afterValue)}',
                style: TextStyle(
                  color: subText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: actionColor.withOpacity(0.16),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: actionColor.withOpacity(0.44)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(actionIcon, size: 12, color: actionColor),
                  const SizedBox(width: 4),
                  Text(
                    '$actionLabel $changeAbsText',
                    style: TextStyle(
                      color: actionColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _riskBadge(String label) {
    final color = _riskBadgeColor(label);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(isDark ? 0.45 : 0.35)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11),
      ),
    );
  }

  Widget _tradeFlowChip({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final won =
        NumberFormat.currency(locale: 'ko_KR', symbol: '₩', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(isDark ? 0.45 : 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$label ${won.format(amount)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioHoldingPreview {
  const _ScenarioHoldingPreview({
    required this.assetName,
    required this.symbol,
    required this.beforeValue,
    required this.afterValue,
  });

  final String assetName;
  final String symbol;
  final double beforeValue;
  final double afterValue;
}

class _MutableHoldingState {
  _MutableHoldingState({
    required this.assetName,
    required this.symbol,
    required this.beforeValue,
    required this.afterValue,
  });

  String assetName;
  String symbol;
  double beforeValue;
  double afterValue;

  _MutableHoldingState copy() => _MutableHoldingState(
        assetName: assetName,
        symbol: symbol,
        beforeValue: beforeValue,
        afterValue: afterValue,
      );
}

List<_ScenarioHoldingPreview> _buildHoldingPreviewFromPositions(
    List<PositionData> positions) {
  final states = _buildHoldingStateMap(positions);
  return _toScenarioHoldingPreview(states);
}

Map<_AdviceScenarioType, List<_ScenarioHoldingPreview>>
    _buildProjectedHoldingsByScenario({
  required List<PositionData> positions,
  required PortfolioAdviceData advice,
  required double totalReferenceValue,
}) {
  final safeTotal = totalReferenceValue > 0
      ? totalReferenceValue
      : positions.fold<double>(0, (sum, p) => sum + p.valuation);
  final baseState = _buildHoldingStateMap(positions);
  final rebalancingState = _cloneHoldingStateMap(baseState);
  _applyRebalancingToHoldingState(rebalancingState, advice.rebalancingActions);
  _normalizeHoldingStateTotal(rebalancingState, safeTotal);

  final etfState = _cloneHoldingStateMap(baseState);
  _applyEtfToHoldingState(
    etfState,
    advice.etfRecommendations,
    safeTotal,
  );
  _normalizeHoldingStateTotal(etfState, safeTotal);

  final combinedState = _cloneHoldingStateMap(baseState);
  _applyRebalancingToHoldingState(combinedState, advice.rebalancingActions);
  _applyEtfToHoldingState(
    combinedState,
    advice.etfRecommendations,
    safeTotal,
  );
  _normalizeHoldingStateTotal(combinedState, safeTotal);

  return {
    _AdviceScenarioType.rebalancing:
        _toScenarioHoldingPreview(rebalancingState),
    _AdviceScenarioType.etf: _toScenarioHoldingPreview(etfState),
    _AdviceScenarioType.combined: _toScenarioHoldingPreview(combinedState),
  };
}

Map<String, _MutableHoldingState> _buildHoldingStateMap(
    List<PositionData> positions) {
  final map = <String, _MutableHoldingState>{};
  for (final position in positions) {
    final key = _normalizeTicker(position.symbol).toUpperCase();
    final state = map.putIfAbsent(
      key,
      () => _MutableHoldingState(
        assetName: position.assetName,
        symbol: key,
        beforeValue: 0,
        afterValue: 0,
      ),
    );
    state.assetName = position.assetName;
    state.beforeValue += position.valuation;
    state.afterValue += position.valuation;
  }
  return map;
}

Map<String, _MutableHoldingState> _cloneHoldingStateMap(
    Map<String, _MutableHoldingState> source) {
  return source.map((key, value) => MapEntry(key, value.copy()));
}

void _applyRebalancingToHoldingState(
  Map<String, _MutableHoldingState> map,
  List<RebalancingActionData> actions,
) {
  for (final action in actions) {
    final key = _normalizeTicker(action.symbol).toUpperCase();
    final state = map.putIfAbsent(
      key,
      () => _MutableHoldingState(
        assetName: action.assetName,
        symbol: key,
        beforeValue: 0,
        afterValue: 0,
      ),
    );
    final isBuy = action.action.toUpperCase() == 'BUY';
    final delta = isBuy ? action.suggestedAmount : -action.suggestedAmount;
    state.afterValue = math.max(0, state.afterValue + delta);
    if (state.assetName.isEmpty) {
      state.assetName = action.assetName;
    }
  }
}

void _applyEtfToHoldingState(
  Map<String, _MutableHoldingState> map,
  List<EtfRecommendationData> etfs,
  double totalReferenceValue,
) {
  if (etfs.isEmpty || totalReferenceValue <= 0) return;
  final requestedWeight =
      etfs.fold<double>(0, (sum, etf) => sum + etf.suggestedWeightPct);
  final cappedWeight = requestedWeight.clamp(0.0, 70.0);
  final existingScale = math.max(0.0, 1 - (cappedWeight / 100));

  for (final state in map.values) {
    state.afterValue = state.afterValue * existingScale;
  }

  for (final etf in etfs) {
    final key = _normalizeTicker(etf.symbol).toUpperCase();
    final state = map.putIfAbsent(
      key,
      () => _MutableHoldingState(
        assetName: etf.name,
        symbol: key,
        beforeValue: 0,
        afterValue: 0,
      ),
    );
    state.assetName = etf.name;
    final amount = totalReferenceValue * (etf.suggestedWeightPct / 100);
    state.afterValue += math.max(0, amount);
  }
}

void _normalizeHoldingStateTotal(
    Map<String, _MutableHoldingState> map, double targetTotal) {
  if (targetTotal <= 0) return;
  final currentTotal =
      map.values.fold<double>(0, (sum, item) => sum + item.afterValue);
  if (currentTotal <= 0) return;

  final ratio = targetTotal / currentTotal;
  for (final state in map.values) {
    state.afterValue = state.afterValue * ratio;
  }
}

List<_ScenarioHoldingPreview> _toScenarioHoldingPreview(
    Map<String, _MutableHoldingState> map) {
  final list = map.values
      .where((state) => state.beforeValue > 1 || state.afterValue > 1)
      .map((state) => _ScenarioHoldingPreview(
            assetName: state.assetName,
            symbol: state.symbol,
            beforeValue: state.beforeValue,
            afterValue: state.afterValue,
          ))
      .toList();
  list.sort((a, b) => b.afterValue.compareTo(a.afterValue));
  return list;
}

class _AdviceMetricDeltaTile extends StatelessWidget {
  const _AdviceMetricDeltaTile({
    required this.title,
    required this.before,
    required this.after,
    required this.decimals,
    required this.unit,
    this.helpText,
  });

  final String title;
  final double before;
  final double after;
  final int decimals;
  final String unit;
  final String? helpText;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileBg = isDark ? const Color(0xFF12213A) : const Color(0xFFF7FCFA);
    final tileBorder =
        isDark ? const Color(0xFF2A3E63) : const Color(0xFFD0E4DE);
    final titleText =
        isDark ? const Color(0xFF8EA0C1) : const Color(0xFF5D7A7E);
    final valueText =
        isDark ? const Color(0xFFF3F6FF) : const Color(0xFF1E3742);
    final beforeAfterText =
        isDark ? const Color(0xFFD3DCF0) : const Color(0xFF355056);
    final arrowText =
        isDark ? const Color(0xFF7E90B2) : const Color(0xFF7E9AA0);

    final delta = after - before;
    final deltaColor =
        delta >= 0 ? const Color(0xFFFF6B81) : const Color(0xFF5CA8FF);
    final beforeText = '${before.toStringAsFixed(decimals)}$unit';
    final afterText = '${after.toStringAsFixed(decimals)}$unit';
    final deltaText = delta == 0
        ? '변화 없음'
        : '${delta > 0 ? '상향' : '하향'} ${delta.abs().toStringAsFixed(decimals)}$unit';

    return Container(
      width: 232,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tileBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: TextStyle(color: titleText, fontSize: 12)),
              ),
              if (helpText != null)
                _InfoBubbleIcon(
                  title: title,
                  message: helpText!,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            afterText,
            style: TextStyle(
                color: valueText, fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Text(beforeText,
                  style: TextStyle(color: titleText, fontSize: 11)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 3),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 13, color: arrowText),
              ),
              Text(afterText,
                  style: TextStyle(
                      color: beforeAfterText,
                      fontWeight: FontWeight.w700,
                      fontSize: 11)),
              const Spacer(),
              Text(deltaText,
                  style: TextStyle(
                      color: deltaColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBubbleIcon extends StatefulWidget {
  const _InfoBubbleIcon({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  State<_InfoBubbleIcon> createState() => _InfoBubbleIconState();
}

class _InfoBubbleIconState extends State<_InfoBubbleIcon> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _entry;
  Timer? _hoverCloseTimer;
  bool _isIconHovered = false;
  bool _isBubbleHovered = false;

  bool get _isOpen => _entry != null;
  bool get _preferHover {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  @override
  void dispose() {
    _hoverCloseTimer?.cancel();
    _close();
    super.dispose();
  }

  void _toggle() {
    if (_isOpen) {
      _close();
      return;
    }
    _open();
  }

  void _open() {
    if (_isOpen) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    _entry = OverlayEntry(
      builder: (context) {
        final maxWidth = MediaQuery.of(context).size.width - 28;
        final bubbleWidth = maxWidth.clamp(220.0, 290.0);
        final guide = _guideForTitle(widget.title);
        return Stack(
          children: [
            if (!_preferHover)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _close,
                  child: const SizedBox.expand(),
                ),
              ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.topRight,
              followerAnchor: Alignment.bottomRight,
              offset: const Offset(0, -8),
              child: MouseRegion(
                onEnter: (_) {
                  if (!_preferHover) return;
                  _hoverCloseTimer?.cancel();
                  _isBubbleHovered = true;
                },
                onExit: (_) {
                  if (!_preferHover) return;
                  _isBubbleHovered = false;
                  _scheduleHoverClose();
                },
                child: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: bubbleWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
                          decoration: BoxDecoration(
                            color: const Color(0xFF182843),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF3A5585)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x55070C16),
                                blurRadius: 18,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.title,
                                      style: const TextStyle(
                                        color: Color(0xFFE9F0FF),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '설명',
                                    style: TextStyle(
                                      color: Color(0xFF8EA0C1),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.message,
                                style: const TextStyle(
                                  color: Color(0xFFD6E1F8),
                                  fontSize: 12,
                                  height: 1.36,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (guide != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F1D33),
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(
                                        color: const Color(0xFF2C4470)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _guideLine('보통 범위', guide.normalRange),
                                      const SizedBox(height: 3),
                                      _guideLine(
                                          '낮으면', guide.lowInterpretation),
                                      const SizedBox(height: 3),
                                      _guideLine(
                                          '높으면', guide.highInterpretation),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  '체크 포인트: ${guide.actionHint}',
                                  style: const TextStyle(
                                    color: Color(0xFF9FB4D8),
                                    fontSize: 11,
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: CustomPaint(
                            size: const Size(16, 8),
                            painter: const _InfoBubbleTailPainter(
                              fillColor: Color(0xFF182843),
                              borderColor: Color(0xFF3A5585),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_entry!);
  }

  void _close() {
    _hoverCloseTimer?.cancel();
    _isIconHovered = false;
    _isBubbleHovered = false;
    _entry?.remove();
    _entry = null;
  }

  void _scheduleHoverClose() {
    _hoverCloseTimer?.cancel();
    _hoverCloseTimer = Timer(const Duration(milliseconds: 80), () {
      if (!_isIconHovered && !_isBubbleHovered) {
        _close();
      }
    });
  }

  Widget _guideLine(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Color(0xFFD7E3FA),
          fontSize: 11.3,
          height: 1.34,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(
              color: Color(0xFFA9BDE1),
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }

  _MetricGuide? _guideForTitle(String title) {
    final t = title.toLowerCase();
    if (title.contains('샤프') || t.contains('sharpe')) {
      return const _MetricGuide(
        normalRange: '0.8~1.2 내외',
        lowInterpretation: '0.8 미만이면 같은 위험 대비 수익 효율이 낮아요.',
        highInterpretation: '1.5 이상이면 위험 대비 성과가 우수한 편이에요.',
        actionHint: '수익만 보지 말고 변동성·MDD도 같이 확인해요.',
      );
    }
    if (title.contains('변동성') || t.contains('volatility')) {
      return const _MetricGuide(
        normalRange: '연 10~20% 내외(자산군별 차이 있음)',
        lowInterpretation: '낮을수록 수익곡선이 비교적 안정적이에요.',
        highInterpretation: '높을수록 급등락 가능성이 커져요.',
        actionHint: '변동성이 높으면 비중 쏠림부터 점검해요.',
      );
    }
    if (title.contains('MDD') ||
        title.contains('낙폭') ||
        t.contains('drawdown')) {
      return const _MetricGuide(
        normalRange: '-10% ~ -25% 구간에서 많이 관리해요.',
        lowInterpretation: '절대값이 작을수록 큰 하락 방어가 좋아요.',
        highInterpretation: '절대값이 크면 하락 구간 체감 스트레스가 커져요.',
        actionHint: '급락 구간에 버틸 수 있는 비중인지 먼저 확인해요.',
      );
    }
    if (title.contains('분산') || t.contains('diversification')) {
      return const _MetricGuide(
        normalRange: '60~80점이면 분산이 비교적 양호해요.',
        lowInterpretation: '낮으면 특정 종목/섹터 쏠림 가능성이 커요.',
        highInterpretation: '높을수록 리스크가 고르게 분산된 상태예요.',
        actionHint: '비슷한 성격 자산만 겹쳐 들고 있는지 봐요.',
      );
    }
    if (title.contains('연수익') || title.contains('기대') || t.contains('return')) {
      return const _MetricGuide(
        normalRange: '연 5~12%를 현실적 범위로 많이 봐요.',
        lowInterpretation: '낮으면 안정적일 수 있지만 목표 달성이 느릴 수 있어요.',
        highInterpretation: '높으면 매력적이지만 변동성 확대 가능성도 커져요.',
        actionHint: '수익률 목표와 감당 가능한 변동성을 같이 맞춰요.',
      );
    }
    if (title.contains('최대 종목 비중') ||
        title.contains('집중') ||
        t.contains('concentration')) {
      return const _MetricGuide(
        normalRange: '단일 종목 20~35% 이하를 많이 권장해요.',
        lowInterpretation: '낮을수록 특정 종목 리스크 영향이 줄어요.',
        highInterpretation: '높을수록 한 종목 이벤트가 전체 수익률을 흔들어요.',
        actionHint: '상위 1~2개 종목 비중부터 먼저 낮춰요.',
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) {
          if (!_preferHover) return;
          _hoverCloseTimer?.cancel();
          _isIconHovered = true;
          _open();
        },
        onExit: (_) {
          if (!_preferHover) return;
          _isIconHovered = false;
          _scheduleHoverClose();
        },
        child: GestureDetector(
          onTap: _preferHover ? null : _toggle,
          behavior: HitTestBehavior.opaque,
          child: const Padding(
            padding: EdgeInsets.all(2),
            child: Icon(Icons.info_outline_rounded,
                size: 14, color: Color(0xFF8EA0C1)),
          ),
        ),
      ),
    );
  }
}

class _MetricGuide {
  const _MetricGuide({
    required this.normalRange,
    required this.lowInterpretation,
    required this.highInterpretation,
    required this.actionHint,
  });

  final String normalRange;
  final String lowInterpretation;
  final String highInterpretation;
  final String actionHint;
}

class _InfoBubbleTailPainter extends CustomPainter {
  const _InfoBubbleTailPainter({
    required this.fillColor,
    required this.borderColor,
  });

  final Color fillColor;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final fillPath = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    final fillPaint = Paint()..color = fillColor;
    canvas.drawPath(fillPath, fillPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final borderPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0);
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _InfoBubbleTailPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor;
  }
}

Map<_AdviceScenarioType, _AdviceScenarioProjection>
    _buildAdviceScenarioProjections(PortfolioAdviceData advice) {
  final base = advice.metrics;
  final rebalancingDelta = _estimateRebalancingDelta(advice.rebalancingActions);
  final etfDelta = _estimateEtfRecommendationDelta(advice.etfRecommendations);

  final rebalancingMetrics = _applyAdviceMetricsDelta(base, rebalancingDelta);
  final etfMetrics = _applyAdviceMetricsDelta(base, etfDelta);
  final combinedMetrics = _applyAdviceMetricsDelta(
    _applyAdviceMetricsDelta(base, rebalancingDelta),
    _mergeAdviceMetricsDelta(
      etfDelta,
      _combinedSynergyDelta(
        hasRebalancing: advice.rebalancingActions.isNotEmpty,
        hasEtfRecommendations: advice.etfRecommendations.isNotEmpty,
      ),
    ),
  );

  return {
    _AdviceScenarioType.rebalancing: _AdviceScenarioProjection(
      type: _AdviceScenarioType.rebalancing,
      label: '리밸런싱 반영',
      summary:
          '리밸런싱 권장 ${advice.rebalancingActions.length}건이 바로 체결됐다고 가정한 변화예요.',
      metrics: rebalancingMetrics,
      accent: const Color(0xFF6CB5FF),
      badge: '리밸런싱 ${advice.rebalancingActions.length}건',
    ),
    _AdviceScenarioType.etf: _AdviceScenarioProjection(
      type: _AdviceScenarioType.etf,
      label: '추천 ETF 반영',
      summary:
          '추천 ETF ${advice.etfRecommendations.length}종목 비중을 반영했을 때의 예상 변화예요.',
      metrics: etfMetrics,
      accent: const Color(0xFF65D6A5),
      badge: '추천 ETF ${advice.etfRecommendations.length}종목',
    ),
    _AdviceScenarioType.combined: _AdviceScenarioProjection(
      type: _AdviceScenarioType.combined,
      label: '리밸런싱 + ETF 종합',
      summary: '리밸런싱+ETF 대체안을 함께 반영해 최적화했을 때의 합산 예상값이에요.',
      metrics: combinedMetrics,
      accent: const Color(0xFFFFC56B),
      badge: '종합 시나리오',
    ),
  };
}

AdviceMetricsData _applyAdviceMetricsDelta(
    AdviceMetricsData base, _AdviceMetricsDelta delta) {
  final expectedAnnualReturnPct = _clampDouble(
      base.expectedAnnualReturnPct + delta.expectedAnnualReturnPct, -15, 55);
  final annualVolatilityPct =
      _clampDouble(base.annualVolatilityPct + delta.annualVolatilityPct, 2, 85);
  final sharpeRatio =
      _clampDouble(base.sharpeRatio + delta.sharpeRatio, -2.5, 5.5);
  final maxDrawdownPct =
      _clampDouble(base.maxDrawdownPct + delta.maxDrawdownPct, 1, 95);
  final concentrationPct =
      _clampDouble(base.concentrationPct + delta.concentrationPct, 2, 95);
  final diversificationScore = _clampDouble(
      base.diversificationScore + delta.diversificationScore, 0, 100);

  final provisional = AdviceMetricsData(
    userId: base.userId,
    asOfDate: base.asOfDate,
    totalValue: base.totalValue,
    expectedAnnualReturnPct: expectedAnnualReturnPct,
    annualVolatilityPct: annualVolatilityPct,
    sharpeRatio: sharpeRatio,
    maxDrawdownPct: maxDrawdownPct,
    concentrationPct: concentrationPct,
    diversificationScore: diversificationScore,
    riskLevel: base.riskLevel,
  );

  return AdviceMetricsData(
    userId: provisional.userId,
    asOfDate: provisional.asOfDate,
    totalValue: provisional.totalValue,
    expectedAnnualReturnPct: provisional.expectedAnnualReturnPct,
    annualVolatilityPct: provisional.annualVolatilityPct,
    sharpeRatio: provisional.sharpeRatio,
    maxDrawdownPct: provisional.maxDrawdownPct,
    concentrationPct: provisional.concentrationPct,
    diversificationScore: provisional.diversificationScore,
    riskLevel: _resolveProjectedRiskLevel(provisional),
  );
}

_AdviceMetricsDelta _mergeAdviceMetricsDelta(
    _AdviceMetricsDelta left, _AdviceMetricsDelta right) {
  return _AdviceMetricsDelta(
    expectedAnnualReturnPct:
        left.expectedAnnualReturnPct + right.expectedAnnualReturnPct,
    annualVolatilityPct: left.annualVolatilityPct + right.annualVolatilityPct,
    sharpeRatio: left.sharpeRatio + right.sharpeRatio,
    maxDrawdownPct: left.maxDrawdownPct + right.maxDrawdownPct,
    concentrationPct: left.concentrationPct + right.concentrationPct,
    diversificationScore:
        left.diversificationScore + right.diversificationScore,
  );
}

_AdviceMetricsDelta _estimateRebalancingDelta(
    List<RebalancingActionData> actions) {
  if (actions.isEmpty) return const _AdviceMetricsDelta();

  final gaps = actions.map((e) => e.gapPct.abs()).toList();
  final avgGap = gaps.reduce((a, b) => a + b) / gaps.length;
  final maxGap = gaps.reduce(math.max);
  final buyGapTotal = actions
      .where((e) => e.action == 'BUY')
      .fold<double>(0, (sum, e) => sum + e.gapPct.abs());
  final sellGapTotal = actions
      .where((e) => e.action == 'SELL')
      .fold<double>(0, (sum, e) => sum + e.gapPct.abs());
  final intensity = _clampDouble((avgGap / 6) + (actions.length / 10), 0, 1.8);

  final concentrationDrop =
      _clampDouble(sellGapTotal * 0.34 + maxGap * 0.28, 0, 12.5);
  final diversificationGain = _clampDouble(
      (buyGapTotal + sellGapTotal) * 0.52 + intensity * 1.1, 0, 19.0);
  final volatilityDrop = _clampDouble(avgGap * 0.22 + intensity * 0.8, 0, 4.8);
  final returnLift = _clampDouble(
      (buyGapTotal * 0.09) - (sellGapTotal * 0.04) + intensity * 0.35,
      -0.9,
      2.6);
  final sharpeLift =
      _clampDouble((returnLift / 7.5) + (volatilityDrop / 18.0), -0.25, 0.70);
  final mddDrop = _clampDouble(avgGap * 0.18 + sellGapTotal * 0.10, 0, 3.6);

  return _AdviceMetricsDelta(
    expectedAnnualReturnPct: returnLift,
    annualVolatilityPct: -volatilityDrop,
    sharpeRatio: sharpeLift,
    maxDrawdownPct: -mddDrop,
    concentrationPct: -concentrationDrop,
    diversificationScore: diversificationGain,
  );
}

_AdviceMetricsDelta _estimateEtfRecommendationDelta(
    List<EtfRecommendationData> recommendations) {
  if (recommendations.isEmpty) return const _AdviceMetricsDelta();

  final totalWeight =
      recommendations.fold<double>(0, (sum, e) => sum + e.suggestedWeightPct);
  final avgScore =
      recommendations.fold<double>(0, (sum, e) => sum + e.matchScore) /
          recommendations.length;
  final lowCount = recommendations.where((e) => e.riskBucket == 'LOW').length;
  final midCount = recommendations.where((e) => e.riskBucket == 'MID').length;
  final highCount = recommendations.where((e) => e.riskBucket == 'HIGH').length;
  final riskTilt = (highCount - lowCount) / recommendations.length;

  final concentrationDrop = _clampDouble(totalWeight * 0.42, 0, 13.0);
  final diversificationGain =
      _clampDouble(totalWeight * 0.62 + (avgScore - 60) * 0.08, 0, 23.0);
  final volatilityDelta = _clampDouble(
      (riskTilt * 1.5) - (lowCount * 0.45) + (midCount * 0.1), -3.8, 2.6);
  final returnLift = _clampDouble(
      (avgScore - 70) * 0.06 +
          totalWeight * 0.035 +
          highCount * 0.25 -
          lowCount * 0.06,
      -0.8,
      2.9);
  final sharpeLift =
      _clampDouble((returnLift / 8.0) - (volatilityDelta / 18.0), -0.30, 0.80);
  final mddDelta =
      _clampDouble(volatilityDelta * 0.55 - (lowCount * 0.18), -2.4, 1.8);

  return _AdviceMetricsDelta(
    expectedAnnualReturnPct: returnLift,
    annualVolatilityPct: volatilityDelta,
    sharpeRatio: sharpeLift,
    maxDrawdownPct: mddDelta,
    concentrationPct: -concentrationDrop,
    diversificationScore: diversificationGain,
  );
}

_AdviceMetricsDelta _combinedSynergyDelta({
  required bool hasRebalancing,
  required bool hasEtfRecommendations,
}) {
  if (!hasRebalancing || !hasEtfRecommendations) {
    return const _AdviceMetricsDelta();
  }
  return const _AdviceMetricsDelta(
    expectedAnnualReturnPct: 0.35,
    annualVolatilityPct: -0.55,
    sharpeRatio: 0.12,
    maxDrawdownPct: -0.70,
    concentrationPct: -1.80,
    diversificationScore: 2.40,
  );
}

String _resolveProjectedRiskLevel(AdviceMetricsData metrics) {
  final score = metrics.annualVolatilityPct * 0.45 +
      metrics.maxDrawdownPct * 0.35 +
      metrics.concentrationPct * 0.20;
  if (score >= 26 || metrics.sharpeRatio < 0.55) {
    return '리스크 높음';
  }
  if (score >= 17 || metrics.sharpeRatio < 1.05) {
    return '리스크 보통';
  }
  return '리스크 낮음';
}

String _normalizeRiskLabel(String value) {
  final lower = value.toLowerCase();
  if (value.contains('높음') || lower.contains('high')) return '리스크 높음';
  if (value.contains('보통') || lower.contains('mid') || lower.contains('medium'))
    return '리스크 보통';
  if (value.contains('낮음') || lower.contains('low')) return '리스크 낮음';
  return value;
}

Color _riskBadgeColor(String riskLevel) {
  if (riskLevel.contains('높음')) return const Color(0xFFFF6B81);
  if (riskLevel.contains('보통')) return const Color(0xFFFFC56B);
  return const Color(0xFF65D6A5);
}

double _clampDouble(double value, double min, double max) =>
    value.clamp(min, max).toDouble();

class _PortfolioSimulationCard extends ConsumerStatefulWidget {
  const _PortfolioSimulationCard();

  @override
  ConsumerState<_PortfolioSimulationCard> createState() =>
      _PortfolioSimulationCardState();
}

class _PortfolioSimulationCardState
    extends ConsumerState<_PortfolioSimulationCard> {
  static const int _initialContributionLimit = 3;

  DateTime? _startDate;
  DateTime? _endDate;
  int _visibleContributionCount = _initialContributionLimit;

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now.subtract(const Duration(days: 180)),
      firstDate: DateTime(now.year - 10, 1, 1),
      lastDate: _endDate ?? now,
      helpText: '시작일 선택',
    );
    if (picked == null) return;
    setState(() {
      _startDate = DateTime(picked.year, picked.month, picked.day);
      if (_endDate != null && _startDate!.isAfter(_endDate!)) {
        _endDate = _startDate;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now,
      firstDate: _startDate ?? DateTime(now.year - 10, 1, 1),
      lastDate: now,
      helpText: '기준일 선택',
    );
    if (picked == null) return;
    setState(() {
      _endDate = DateTime(picked.year, picked.month, picked.day);
      if (_startDate != null && _startDate!.isAfter(_endDate!)) {
        _startDate = _endDate;
      }
    });
  }

  void _applyPreset(Duration duration) {
    final end = _endDate ?? DateTime.now();
    final start = end.subtract(duration);
    setState(() {
      _startDate = DateTime(start.year, start.month, start.day);
      _endDate = DateTime(end.year, end.month, end.day);
    });
  }

  void _useBuyDateBase() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  void _expandContributions(int total) {
    final next = total;
    if (next != _visibleContributionCount) {
      setState(() => _visibleContributionCount = next);
    }
  }

  void _collapseContributions() {
    if (_visibleContributionCount != _initialContributionLimit) {
      setState(() => _visibleContributionCount = _initialContributionLimit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subText = isDark ? const Color(0xFF8EA0C1) : const Color(0xFF5E7A7D);
    final panelBg = isDark ? const Color(0xFF12213A) : const Color(0xFFF0F8F5);
    final panelBorder =
        isDark ? const Color(0xFF2A3E63) : const Color(0xFFD0E4DE);
    final panelText =
        isDark ? const Color(0xFFD3DCF0) : const Color(0xFF355056);
    final sectionTitle =
        isDark ? const Color(0xFFDDE7FF) : const Color(0xFF1E3742);
    final emptyText =
        isDark ? const Color(0xFF9AA7C0) : const Color(0xFF5D7A7E);
    final errorText =
        isDark ? const Color(0xFFFF7B87) : const Color(0xFFC7394A);

    final query =
        PortfolioSimulationQuery(startDate: _startDate, endDate: _endDate);
    final simulationAsync = ref.watch(portfolioSimulationProvider(query));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('기간 수익 시뮬레이터',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                ),
                _TopCountBadge(
                    label: _startDate == null && _endDate == null
                        ? '매수일 기준'
                        : '커스텀 기간'),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '현재 보유 수량을 과거 가격에 대입해 특정 기간 수익을 재현해요.',
              style: TextStyle(color: subText, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _presetButton(
                    '1개월', () => _applyPreset(const Duration(days: 30))),
                _presetButton(
                    '3개월', () => _applyPreset(const Duration(days: 90))),
                _presetButton(
                    '6개월', () => _applyPreset(const Duration(days: 180))),
                _presetButton(
                    '1년', () => _applyPreset(const Duration(days: 365))),
                _presetButton('매수일 기준', _useBuyDateBase),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickStartDate,
                    icon: const Icon(Icons.event_available_rounded, size: 16),
                    label: Text('시작일 ${_formatDate(_startDate)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickEndDate,
                    icon: const Icon(Icons.event_rounded, size: 16),
                    label: Text('기준일 ${_formatDate(_endDate)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            simulationAsync.when(
              data: (data) {
                final won = NumberFormat.currency(
                    locale: 'ko_KR', symbol: '₩', decimalDigits: 0);
                final profit = data.pnlAmount >= 0;
                final pnlColor =
                    profit ? const Color(0xFFFF6B81) : const Color(0xFF5CA8FF);

                final contributions = data.contributions;
                final visibleCount =
                    math.min(_visibleContributionCount, contributions.length);
                final visibleContributions =
                    contributions.take(visibleCount).toList();
                final canExpand = visibleCount < contributions.length;
                final canCollapse = visibleCount > _initialContributionLimit;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 9),
                      decoration: BoxDecoration(
                        color: panelBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: panelBorder),
                      ),
                      child: Text(
                        '시뮬레이션 기간: ${data.startDate} ~ ${data.endDate} (${data.simulationDays}일)',
                        style: TextStyle(
                            color: panelText, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                            child: _metric(
                                '기간 손익률',
                                '${profit ? '+' : ''}${data.pnlRate.toStringAsFixed(2)}%',
                                pnlColor)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _metric(
                                '손익 금액',
                                '${profit ? '+' : ''}${won.format(data.pnlAmount)}',
                                pnlColor)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                            child: _metric(
                                '연환산 수익률',
                                '${data.annualizedReturnPct.toStringAsFixed(2)}%',
                                const Color(0xFF65D6A5))),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _metric(
                                '최대 낙폭(MDD)',
                                '${data.maxDrawdownPct.toStringAsFixed(2)}%',
                                const Color(0xFFFFC56B))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (data.timeline.isNotEmpty) ...[
                      Text('기간 누적 수익 곡선',
                          style: TextStyle(
                              color: sectionTitle,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      SizedBox(
                          height: 176,
                          child:
                              _SimulationTrendChart(timeline: data.timeline)),
                    ],
                    const SizedBox(height: 10),
                    Text('종목 기여도 TOP',
                        style: TextStyle(
                            color: sectionTitle, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    if (visibleContributions.isEmpty)
                      Text('기여도 데이터가 없습니다.', style: TextStyle(color: emptyText))
                    else
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: Column(
                          children: visibleContributions.map((item) {
                            final up = item.pnlAmount >= 0;
                            final color = up
                                ? const Color(0xFFFF6B81)
                                : const Color(0xFF5CA8FF);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                color: panelBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: panelBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${item.assetName} (${_normalizeTicker(item.symbol)})',
                                          style: TextStyle(
                                              color: sectionTitle,
                                              fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                      Text(
                                        '${up ? '+' : ''}${item.pnlRate.toStringAsFixed(2)}%',
                                        style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.w900),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '기여 손익 ${up ? '+' : ''}${won.format(item.pnlAmount)} / 시작 ${won.format(item.startPrice)} → 기준 ${won.format(item.endPrice)}',
                                    style: TextStyle(
                                        color: panelText, fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    if (contributions.length > _initialContributionLimit)
                      _ProgressiveRevealControl(
                        canExpand: canExpand,
                        canCollapse: canCollapse,
                        remainingCount: contributions.length - visibleCount,
                        onExpand: () =>
                            _expandContributions(contributions.length),
                        onCollapse: _collapseContributions,
                      ),
                    const SizedBox(height: 4),
                    ..._resolvedSimulationNotes(data.notes).map(_note),
                  ],
                );
              },
              loading: () => const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator())),
              error: (e, _) =>
                  Text('시뮬레이터 로딩 실패: $e', style: TextStyle(color: errorText)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, Color valueColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileBg = isDark ? const Color(0xFF12213A) : const Color(0xFFF7FCFA);
    final tileBorder =
        isDark ? const Color(0xFF2A3E63) : const Color(0xFFD0E4DE);
    final labelColor =
        isDark ? const Color(0xFF8EA0C1) : const Color(0xFF5D7A7E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tileBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: labelColor, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(color: valueColor, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _presetButton(String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        side: BorderSide(
            color: isDark ? const Color(0xFF314A74) : const Color(0xFF7D94C8)),
        foregroundColor:
            isDark ? const Color(0xFFD5E0F5) : const Color(0xFF405F94),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      child: Text(label),
    );
  }

  Widget _note(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor =
        isDark ? const Color(0xFF90A8CF) : const Color(0xFF5A7FA0);
    final noteText = isDark ? const Color(0xFF9FB0CD) : const Color(0xFF4F6B71);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.info_outline_rounded, size: 14, color: iconColor),
          ),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text,
                  style:
                      TextStyle(color: noteText, fontSize: 12, height: 1.35))),
        ],
      ),
    );
  }

  List<String> _resolvedSimulationNotes(List<String> notes) {
    final filtered = notes.where((note) => !_looksMojibake(note)).toList();
    if (filtered.isNotEmpty) {
      return filtered;
    }
    return const [
      '실제 체결가, 수수료, 세금 반영 시 수익 결과가 달라질 수 있어요.',
      '연환산 수익률은 장기 비교용으로 보고, 단기 성과는 누적 수익률로 함께 확인해요.',
      '종목 기여도는 보유수량 기준 추정값이므로 리밸런싱 계획과 같이 봐 주세요.',
    ];
  }

  bool _looksMojibake(String text) {
    final hasHangul = RegExp(r'[가-힣]').hasMatch(text);
    if (hasHangul) {
      return false;
    }
    final hasSuspiciousMark = text.contains('??') || text.contains('\uFFFD');
    final nonAsciiCount = text.runes.where((r) => r > 127).length;
    return hasSuspiciousMark || nonAsciiCount >= 3;
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '(자동)';
    return '${value.month}/${value.day}';
  }
}

class _SimulationTrendChart extends StatelessWidget {
  const _SimulationTrendChart({required this.timeline});

  final List<SimulationPointData> timeline;

  @override
  Widget build(BuildContext context) {
    if (timeline.isEmpty) {
      return const SizedBox.shrink();
    }

    final values = timeline.map((e) => e.cumulativeReturnPct).toList();
    final minY = values.reduce(math.min);
    final maxY = values.reduce(math.max);
    final bound = math.max(maxY.abs(), minY.abs());
    final yRange = bound < 1 ? 2.0 : bound * 1.25;
    final verticalInterval = timeline.length <= 2
        ? 1.0
        : math.max(1.0, ((timeline.length - 1) / 6).roundToDouble());

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (timeline.length - 1).toDouble(),
        minY: -yRange,
        maxY: yRange,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          verticalInterval: verticalInterval,
          horizontalInterval: yRange / 4,
          getDrawingHorizontalLine: (value) {
            if (value.abs() < 0.0001)
              return const FlLine(color: Color(0x664C8DFF), strokeWidth: 1.2);
            return const FlLine(color: Color(0x202B3B58), strokeWidth: 1);
          },
          getDrawingVerticalLine: (value) {
            return const FlLine(
              color: Color(0x1E3E5B86),
              strokeWidth: 1,
              dashArray: [3, 6],
            );
          },
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                '${value.toStringAsFixed(0)}%',
                style: const TextStyle(color: Color(0xFF8EA0C1), fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx != 0 &&
                    idx != timeline.length ~/ 2 &&
                    idx != timeline.length - 1) {
                  return const SizedBox.shrink();
                }
                final date = timeline[idx].date;
                return Text(
                  date.length >= 10 ? date.substring(5, 10) : date,
                  style:
                      const TextStyle(color: Color(0xFF7E90B2), fontSize: 10),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1A2740),
            getTooltipItems: (spots) => spots.map((spot) {
              final i = spot.x.toInt();
              final point = timeline[i];
              final sign = point.cumulativeReturnPct >= 0 ? '+' : '';
              return LineTooltipItem(
                '${point.date}\n$sign${point.cumulativeReturnPct.toStringAsFixed(2)}%',
                const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (int i = 0; i < timeline.length; i++)
                FlSpot(i.toDouble(), timeline[i].cumulativeReturnPct),
            ],
            isCurved: true,
            color: const Color(0xFF59D6FF),
            barWidth: 2.2,
            belowBarData: BarAreaData(
              show: true,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x3359D6FF), Color(0x0059D6FF)],
              ),
            ),
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}

class _RebalancingActionsCard extends StatefulWidget {
  const _RebalancingActionsCard({required this.actions});

  final List<RebalancingActionData> actions;

  @override
  State<_RebalancingActionsCard> createState() =>
      _RebalancingActionsCardState();
}

class _RebalancingActionsCardState extends State<_RebalancingActionsCard> {
  static const int _initialVisibleLimit = 3;
  int _visibleCount = 0;

  @override
  void initState() {
    super.initState();
    _visibleCount = _initialCount(widget.actions.length);
  }

  @override
  void didUpdateWidget(covariant _RebalancingActionsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.actions.length != oldWidget.actions.length) {
      if (_visibleCount == 0) {
        _visibleCount = _initialCount(widget.actions.length);
      } else {
        final minCount = _initialCount(widget.actions.length);
        _visibleCount =
            math.max(minCount, math.min(_visibleCount, widget.actions.length));
      }
    }
  }

  int _initialCount(int total) => math.min(_initialVisibleLimit, total);

  void _expand() {
    final next = widget.actions.length;
    if (next != _visibleCount) {
      setState(() => _visibleCount = next);
    }
  }

  void _collapse() {
    final initial = _initialCount(widget.actions.length);
    if (_visibleCount != initial) {
      setState(() => _visibleCount = initial);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleText =
        isDark ? const Color(0xFF8EA0C1) : const Color(0xFF5E7A7D);
    final bodyText = isDark ? const Color(0xFFD3DCF0) : const Color(0xFF335055);
    final mutedText =
        isDark ? const Color(0xFF9AA7C0) : const Color(0xFF647E81);
    final tileBg = isDark ? const Color(0xFF12213A) : const Color(0xFFF7FCFA);
    final tileBorder =
        isDark ? const Color(0xFF2A3E63) : const Color(0xFFD0E4DE);
    final tileTitle =
        isDark ? const Color(0xFFE8EEFF) : const Color(0xFF1E3742);

    final won =
        NumberFormat.currency(locale: 'ko_KR', symbol: '₩', decimalDigits: 0);
    final actions = widget.actions.take(_visibleCount).toList();
    final canExpand = _visibleCount < widget.actions.length;
    final canCollapse = _visibleCount > _initialCount(widget.actions.length);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('리밸런싱 권장 TOP ${actions.length}',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(width: 8),
                _TopCountBadge(label: '총 ${widget.actions.length}건'),
              ],
            ),
            const SizedBox(height: 6),
            Text('목표 비중 대비 이탈 구간을 우선순위로 정렬했습니다.',
                style: TextStyle(color: titleText, fontSize: 12)),
            const SizedBox(height: 10),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: widget.actions.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0x1A65D6A5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0x5565D6A5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('현재 비중은 안정 구간이에요.',
                              style: TextStyle(
                                  color: Color(0xFFB9F5DD),
                                  fontWeight: FontWeight.w800)),
                          SizedBox(height: 4),
                          Text('운영전략 1) 월 1회만 점검하고 허용오차(±3%) 이탈 시에만 조정',
                              style: TextStyle(color: bodyText, fontSize: 12)),
                          Text('운영전략 2) 신규 자금 유입분으로만 목표 비중 보정',
                              style: TextStyle(color: bodyText, fontSize: 12)),
                          Text('운영전략 3) 과도한 매매 대신 리스크 임계치 알림 기반 대응',
                              style: TextStyle(color: bodyText, fontSize: 12)),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: tileBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: tileBorder),
                          ),
                          child: Column(
                            children: [
                              for (int i = 0; i < actions.length; i++) ...[
                                if (i > 0)
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: tileBorder,
                                  ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                  child: Builder(
                                    builder: (context) {
                                      final action = actions[i];
                                      final buy = action.action == 'BUY';
                                      final accent = buy
                                          ? const Color(0xFF5CA8FF)
                                          : const Color(0xFFFF6B81);
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '${action.assetName} (${_normalizeTicker(action.symbol)})',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: tileTitle),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                decoration: BoxDecoration(
                                                  color:
                                                      accent.withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          999),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      buy
                                                          ? Icons
                                                              .add_shopping_cart_rounded
                                                          : Icons.sell_rounded,
                                                      size: 12,
                                                      color: accent,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      buy ? '매수 제안' : '매도 제안',
                                                      style: TextStyle(
                                                          color: accent,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          fontSize: 11),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '현재 ${action.currentWeightPct.toStringAsFixed(1)}% → 목표 ${action.targetWeightPct.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                                color: bodyText, fontSize: 12),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${buy ? '매수' : '매도'} 금액 ${won.format(action.suggestedAmount)}',
                                            style: TextStyle(
                                              color: accent,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            action.reason,
                                            style: TextStyle(
                                                color: mutedText, fontSize: 12),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            if (widget.actions.length > _initialCount(widget.actions.length))
              _ProgressiveRevealControl(
                canExpand: canExpand,
                canCollapse: canCollapse,
                remainingCount: widget.actions.length - _visibleCount,
                onExpand: _expand,
                onCollapse: _collapse,
              ),
          ],
        ),
      ),
    );
  }
}

class _EtfRecommendationCard extends StatefulWidget {
  const _EtfRecommendationCard({required this.recommendations});

  final List<EtfRecommendationData> recommendations;

  @override
  State<_EtfRecommendationCard> createState() => _EtfRecommendationCardState();
}

class _EtfRecommendationCardState extends State<_EtfRecommendationCard> {
  static const int _initialVisibleLimit = 2;
  int _visibleCount = 0;

  @override
  void initState() {
    super.initState();
    _visibleCount = _initialCount(widget.recommendations.length);
  }

  @override
  void didUpdateWidget(covariant _EtfRecommendationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.recommendations.length != oldWidget.recommendations.length) {
      if (_visibleCount == 0) {
        _visibleCount = _initialCount(widget.recommendations.length);
      } else {
        final minCount = _initialCount(widget.recommendations.length);
        _visibleCount = math.max(
            minCount, math.min(_visibleCount, widget.recommendations.length));
      }
    }
  }

  int _initialCount(int total) => math.min(_initialVisibleLimit, total);

  void _expand() {
    final next = widget.recommendations.length;
    if (next != _visibleCount) {
      setState(() => _visibleCount = next);
    }
  }

  void _collapse() {
    final initial = _initialCount(widget.recommendations.length);
    if (_visibleCount != initial) {
      setState(() => _visibleCount = initial);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleText =
        isDark ? const Color(0xFF8EA0C1) : const Color(0xFF5E7A7D);
    final bodyText = isDark ? const Color(0xFFD3DCF0) : const Color(0xFF335055);
    final mutedText =
        isDark ? const Color(0xFF9AA7C0) : const Color(0xFF647E81);
    final tileBg = isDark ? const Color(0xFF12213A) : const Color(0xFFF7FCFA);
    final tileBorder =
        isDark ? const Color(0xFF2A3E63) : const Color(0xFFD0E4DE);
    final tileTitle =
        isDark ? const Color(0xFFE8EEFF) : const Color(0xFF1E3742);

    final recommendations = widget.recommendations.take(_visibleCount).toList();
    final canExpand = _visibleCount < widget.recommendations.length;
    final canCollapse =
        _visibleCount > _initialCount(widget.recommendations.length);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('추천 ETF TOP ${recommendations.length}',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(width: 8),
                _TopCountBadge(label: '총 ${widget.recommendations.length}종목'),
              ],
            ),
            const SizedBox(height: 6),
            Text('위험수준과 집중도를 반영한 대체 포지션 제안이에요.',
                style: TextStyle(color: titleText, fontSize: 12)),
            const SizedBox(height: 10),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: widget.recommendations.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0x1A5CA8FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0x553E6CB0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('현재 포트폴리오와 위험성향 기준으로 즉시 교체할 ETF는 없습니다.',
                              style: TextStyle(
                                  color: Color(0xFFBAD2FF),
                                  fontWeight: FontWeight.w800)),
                          SizedBox(height: 4),
                          Text('도움말) 신규 매수할 때는 저비용 광역지수 ETF를 먼저 비교해 보세요.',
                              style: TextStyle(color: bodyText, fontSize: 12)),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: tileBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: tileBorder),
                          ),
                          child: Column(
                            children: [
                              for (int i = 0;
                                  i < recommendations.length;
                                  i++) ...[
                                if (i > 0)
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: tileBorder,
                                  ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                  child: Builder(
                                    builder: (context) {
                                      final etf = recommendations[i];
                                      final color = etf.riskBucket == 'LOW'
                                          ? const Color(0xFF65D6A5)
                                          : etf.riskBucket == 'MID'
                                              ? const Color(0xFFFFC56B)
                                              : const Color(0xFFFF6B81);
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '${etf.symbol} ${etf.name}',
                                                  style: TextStyle(
                                                      color: tileTitle,
                                                      fontWeight:
                                                          FontWeight.w800),
                                                ),
                                              ),
                                              Text(
                                                '${etf.matchScore}점',
                                                style: TextStyle(
                                                    color: color,
                                                    fontWeight:
                                                        FontWeight.w900),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${etf.focusTheme} · 권장 비중 ${etf.suggestedWeightPct.toStringAsFixed(1)}% · 총보수 ${etf.expenseRatioPct.toStringAsFixed(4)}%',
                                            style: TextStyle(
                                                color: bodyText, fontSize: 12),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            etf.reason,
                                            style: TextStyle(
                                                color: mutedText, fontSize: 12),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            if (widget.recommendations.length >
                _initialCount(widget.recommendations.length))
              _ProgressiveRevealControl(
                canExpand: canExpand,
                canCollapse: canCollapse,
                remainingCount: widget.recommendations.length - _visibleCount,
                onExpand: _expand,
                onCollapse: _collapse,
              ),
          ],
        ),
      ),
    );
  }
}

class _HoldingAssetCard extends StatefulWidget {
  const _HoldingAssetCard({required this.positions});

  final List<PositionData> positions;

  @override
  State<_HoldingAssetCard> createState() => _HoldingAssetCardState();
}

class _HoldingAssetCardState extends State<_HoldingAssetCard> {
  static const int _initialVisibleLimit = 3;
  int _visibleCount = 0;

  @override
  void initState() {
    super.initState();
    _visibleCount = _initialCount(widget.positions.length);
  }

  @override
  void didUpdateWidget(covariant _HoldingAssetCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.positions.length != oldWidget.positions.length) {
      if (_visibleCount == 0) {
        _visibleCount = _initialCount(widget.positions.length);
      } else {
        final minCount = _initialCount(widget.positions.length);
        _visibleCount = math.max(
            minCount, math.min(_visibleCount, widget.positions.length));
      }
    }
  }

  int _initialCount(int total) => math.min(_initialVisibleLimit, total);

  void _expand() {
    final next = widget.positions.length;
    if (next != _visibleCount) {
      setState(() => _visibleCount = next);
    }
  }

  void _collapse() {
    final initial = _initialCount(widget.positions.length);
    if (_visibleCount != initial) {
      setState(() => _visibleCount = initial);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileBg = isDark ? const Color(0xFF182540) : const Color(0xFFF4FBF9);
    final tileBorder =
        isDark ? const Color(0xFF2E446A) : const Color(0xFFD2E6E0);
    final cardTitleText =
        isDark ? const Color(0xFFF3F6FF) : const Color(0xFF1F3842);
    final cardSubText =
        isDark ? const Color(0xFF91A0BC) : const Color(0xFF5D7A7E);
    final summaryBg =
        isDark ? const Color(0xFF12213A) : const Color(0xFFF0F8F5);
    final summaryBorder =
        isDark ? const Color(0xFF2A3E63) : const Color(0xFFD0E4DE);
    final summaryLabel =
        isDark ? const Color(0xFF8EA0C1) : const Color(0xFF567377);

    final won =
        NumberFormat.currency(locale: 'ko_KR', symbol: '₩', decimalDigits: 0);
    final positions = widget.positions.take(_visibleCount).toList();

    final totalValuation =
        widget.positions.fold<double>(0, (sum, p) => sum + p.valuation);
    final totalCost = widget.positions
        .fold<double>(0, (sum, p) => sum + p.avgCost * p.quantity);
    final totalPnl = totalValuation - totalCost;
    final totalPnlRate = totalCost > 0 ? (totalPnl / totalCost) * 100 : 0;
    final totalProfit = totalPnl >= 0;
    final canExpand = _visibleCount < widget.positions.length;
    final canCollapse = _visibleCount > _initialCount(widget.positions.length);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('보유 자산 TOP ${positions.length}',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900)),
                const Spacer(),
                _TopCountBadge(label: '총 ${widget.positions.length}종목'),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: Container(
                decoration: BoxDecoration(
                  color: tileBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tileBorder),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < positions.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: tileBorder,
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        child: Builder(
                          builder: (context) {
                            final p = positions[i];
                            final up = p.pnlRate >= 0;
                            return Row(
                              children: [
                                Container(
                                  width: 3,
                                  height: 34,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: up
                                        ? const Color(0xFFFF6B81)
                                        : const Color(0xFF5CA8FF),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(p.assetName,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: cardTitleText)),
                                      const SizedBox(height: 2),
                                      Text(_normalizeTicker(p.symbol),
                                          style: TextStyle(
                                              color: cardSubText,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(won.format(p.valuation),
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: cardTitleText)),
                                    Text(
                                      '${up ? '+' : ''}${p.pnlRate.toStringAsFixed(2)}%',
                                      style: TextStyle(
                                          color: up
                                              ? const Color(0xFFFF6B81)
                                              : const Color(0xFF5CA8FF),
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (widget.positions.length >
                _initialCount(widget.positions.length))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ProgressiveRevealControl(
                  canExpand: canExpand,
                  canCollapse: canCollapse,
                  remainingCount: widget.positions.length - _visibleCount,
                  onExpand: _expand,
                  onCollapse: _collapse,
                ),
              ),
            const SizedBox(height: 2),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                  color: summaryBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: summaryBorder)),
              child: Row(
                children: [
                  Text('포트폴리오 합계',
                      style: TextStyle(
                          color: summaryLabel, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Text(won.format(totalValuation),
                      style: TextStyle(
                          color: cardTitleText, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 12),
                  Text(
                    '${totalProfit ? '+' : ''}${won.format(totalPnl)} (${totalProfit ? '+' : ''}${totalPnlRate.toStringAsFixed(2)}%)',
                    style: TextStyle(
                        color: totalProfit
                            ? const Color(0xFFFF6B81)
                            : const Color(0xFF5CA8FF),
                        fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopCountBadge extends StatelessWidget {
  const _TopCountBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x1F5CA8FF) : const Color(0x1F4FAE9A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: isDark ? const Color(0x553E6CB0) : const Color(0x5567B6A8)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? const Color(0xFFBAD2FF) : const Color(0xFF2A6F66),
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _ProgressiveRevealControl extends StatelessWidget {
  const _ProgressiveRevealControl({
    required this.canExpand,
    required this.canCollapse,
    required this.remainingCount,
    required this.onExpand,
    required this.onCollapse,
  });

  final bool canExpand;
  final bool canCollapse;
  final int remainingCount;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!canExpand && !canCollapse) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (canCollapse)
          TextButton.icon(
            onPressed: onCollapse,
            style: TextButton.styleFrom(
              foregroundColor:
                  isDark ? const Color(0xFF9FB3D8) : const Color(0xFF3B6A76),
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.remove_circle_outline_rounded, size: 16),
            label: const Text('기본만 보기'),
          ),
        if (canExpand)
          FilledButton.tonalIcon(
            onPressed: onExpand,
            style: FilledButton.styleFrom(
              backgroundColor:
                  isDark ? const Color(0x2237D6B6) : const Color(0x224FAE9A),
              foregroundColor:
                  isDark ? const Color(0xFFBFF8ED) : const Color(0xFF1F665C),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
            label: Text('전체 보기 +$remainingCount'),
          ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Card(
        child: SizedBox(
            height: height,
            child: const Center(child: CircularProgressIndicator())));
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text('데이터를 불러오지 못했습니다: $message',
            style: const TextStyle(
                color: Color(0xFFFF7B87), fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _MarketBarPoint {
  _MarketBarPoint(
      {required this.assetName,
      required this.ticker,
      required this.changeRate});

  final String assetName;
  final String ticker;
  final double changeRate;
}

class _AxisScale {
  const _AxisScale({required this.bound, required this.interval});

  final double bound;
  final double interval;
}

String _normalizeTicker(String symbol) {
  final value = symbol.trim();
  final regex = RegExp(r'^A\\d{6}$');
  if (regex.hasMatch(value)) {
    return value.substring(1);
  }
  return value;
}
