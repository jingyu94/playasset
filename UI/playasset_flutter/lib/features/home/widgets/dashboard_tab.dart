import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/dashboard_models.dart';
import 'complementary_accent.dart';
import '../home_providers.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final positionsAsync = ref.watch(positionsProvider);
    final watchlistAsync = ref.watch(watchlistProvider);
    final advisorAsync = ref.watch(advisorProvider);

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
          const SizedBox(height: 14),
          dashboardAsync.when(
            data: (data) => _HeroCard(data: data),
            loading: () => const _LoadingCard(height: 200),
            error: (e, _) => _ErrorCard(message: e.toString()),
          ),
          const SizedBox(height: 12),
          watchlistAsync.when(
            data: (watchlist) {
              final points = watchlist
                  .map((e) => _MarketBarPoint(assetName: e.assetName, ticker: _normalizeTicker(e.symbol), changeRate: e.changeRate))
                  .toList();
              return _TickerComparisonCard(points: points);
            },
            loading: () => dashboardAsync.when(
              data: (data) => _TickerComparisonCard(
                points: data.topMovers
                    .map((e) => _MarketBarPoint(assetName: e.assetName, ticker: _normalizeTicker(e.symbol), changeRate: e.changeRate))
                    .toList(),
              ),
              loading: () => const _LoadingCard(height: 280),
              error: (e, _) => _ErrorCard(message: e.toString()),
            ),
            error: (_, __) => dashboardAsync.when(
              data: (data) => _TickerComparisonCard(
                points: data.topMovers
                    .map((e) => _MarketBarPoint(assetName: e.assetName, ticker: _normalizeTicker(e.symbol), changeRate: e.changeRate))
                    .toList(),
              ),
              loading: () => const _LoadingCard(height: 280),
              error: (e, _) => _ErrorCard(message: e.toString()),
            ),
          ),
          const SizedBox(height: 12),
          positionsAsync.when(
            data: (positions) => dashboardAsync.when(
              data: (dashboard) => _InsightCard(positions: positions, dashboard: dashboard),
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
          const _PortfolioSimulationCard(),
          const SizedBox(height: 12),
          advisorAsync.when(
            data: (advice) => _RebalancingActionsCard(actions: advice.rebalancingActions),
            loading: () => const _LoadingCard(height: 220),
            error: (e, _) => _ErrorCard(message: e.toString()),
          ),
          const SizedBox(height: 12),
          advisorAsync.when(
            data: (advice) => _EtfRecommendationCard(recommendations: advice.etfRecommendations),
            loading: () => const _LoadingCard(height: 210),
            error: (e, _) => _ErrorCard(message: e.toString()),
          ),
          const SizedBox(height: 12),
          positionsAsync.when(
            data: (positions) => _HoldingAssetCard(positions: positions),
            loading: () => const _LoadingCard(height: 260),
            error: (e, _) => _ErrorCard(message: e.toString()),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
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
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.8),
              ),
              const SizedBox(height: 3),
              Text(
                '${formatter.format(now)} 기준 실시간 집계',
                style: const TextStyle(color: Color(0xFF9AA7C0), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        const ComplementaryAccent(
          icon: Icons.auto_graph_rounded,
          primary: Color(0xFF59D6FF),
          secondary: Color(0xFFFF7A8B),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final won = NumberFormat.currency(locale: 'ko_KR', symbol: '₩', decimalDigits: 0);
    final profit = data.dailyPnl >= 0;
    final pnlColor = profit ? const Color(0xFFFF5D73) : const Color(0xFF5CA8FF);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF172746), Color(0xFF101D35), Color(0xFF0D172A)],
        ),
        border: Border.all(color: const Color(0xFF2D436C)),
        boxShadow: [
          BoxShadow(color: const Color(0x664C8DFF).withOpacity(0.2), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: const Color(0x224C8DFF), borderRadius: BorderRadius.circular(999)),
                child: const Text('총 자산', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFDDE7FF))),
              ),
              const Spacer(),
              Icon(Icons.insights_rounded, color: pnlColor, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(won.format(data.portfolioValue), style: const TextStyle(fontSize: 33, fontWeight: FontWeight.w900, letterSpacing: -1)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(color: const Color(0xFF0F1B31), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2A3B5A))),
            child: Row(
              children: [
                const Text('당일 평가손익', style: TextStyle(color: Color(0xFF9AA7C0), fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(
                  '${profit ? '+' : ''}${won.format(data.dailyPnl)} (${profit ? '+' : ''}${data.dailyPnlRate.toStringAsFixed(2)}%)',
                  style: TextStyle(color: pnlColor, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _kpi('관심종목', '${data.watchlistCount}개')),
              const SizedBox(width: 8),
              Expanded(child: _kpi('미확인 알림', '${data.unreadAlertCount}건')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpi(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFF101D33), borderRadius: BorderRadius.circular(11), border: Border.all(color: const Color(0xFF273A58))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF8EA0C1), fontSize: 12)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
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
  static const int _expandStep = 4;

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
        _visibleCount = math.max(_initialCount(widget.points.length), math.min(_visibleCount, widget.points.length));
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
    final next = math.min(widget.points.length, _visibleCount + _expandStep);
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
    final sortedPoints = [...widget.points]..sort((a, b) => b.changeRate.abs().compareTo(a.changeRate.abs()));
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
    final selected = _selectedIndex != null && _selectedIndex! < points.length ? points[_selectedIndex!] : null;
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
                Text('종목별 당일 등락률 TOP ${points.length}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(width: 8),
                _TopCountBadge(label: '총 ${sortedPoints.length}종목'),
              ],
            ),
            const SizedBox(height: 4),
            const Text('세로축은 당일 등락률(%) 스케일이며, x축은 종목명(티커) 기준입니다.', style: TextStyle(color: Color(0xFF8EA0C1), fontSize: 12)),
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
                              tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              getTooltipItem: (group, _, rod, __) {
                                final point = points[group.x.toInt()];
                                final sign = point.changeRate >= 0 ? '+' : '';
                                return BarTooltipItem(
                                  '${point.assetName} (${point.ticker})\n$sign${point.changeRate.toStringAsFixed(2)}%',
                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                                );
                              },
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: scale.interval,
                            getDrawingHorizontalLine: (value) {
                              if (value == 0) {
                                return const FlLine(color: Color(0x554C8DFF), strokeWidth: 1.2);
                              }
                              return const FlLine(color: Color(0x202B3B58), strokeWidth: 1);
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 44,
                                getTitlesWidget: (value, meta) {
                                  final show = (value % scale.interval).abs() < 0.001 || (value % scale.interval).abs() > (scale.interval - 0.001);
                                  if (!show) return const SizedBox.shrink();
                                  return Text(_formatPercent(value, scale.interval), style: const TextStyle(color: Color(0xFF8EA0C1), fontSize: 11));
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 52,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                                  final selectedPoint = _selectedIndex != null && idx == _selectedIndex;
                                  final label = _shortName(points[idx].assetName);
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
                                              color: selectedPoint ? const Color(0xFFE8EEFF) : const Color(0xFF8EA0C1),
                                              fontWeight: selectedPoint ? FontWeight.w800 : FontWeight.w600,
                                              fontSize: 11,
                                            ),
                                          ),
                                          Text(
                                            '(${points[idx].ticker})',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: selectedPoint ? const Color(0xFFE8EEFF) : const Color(0xFF7E90B2),
                                              fontWeight: selectedPoint ? FontWeight.w700 : FontWeight.w500,
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
                                showingTooltipIndicators: _selectedIndex != null && i == _selectedIndex ? const [0] : const [],
                                barRods: [
                                  BarChartRodData(
                                    toY: points[i].changeRate,
                                    width: 16,
                                    borderRadius: BorderRadius.circular(4),
                                    color: points[i].changeRate >= 0 ? const Color(0xFFFF6B81) : const Color(0xFF5CA8FF),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      Positioned.fill(
                        child: MouseRegion(
                          onHover: (event) => _updateIndexByDx(event.localPosition.dx, constraints.maxWidth),
                          onExit: (_) => _clearSelection(),
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTapDown: (details) => _updateIndexByDx(details.localPosition.dx, constraints.maxWidth),
                            onHorizontalDragDown: (details) => _updateIndexByDx(details.localPosition.dx, constraints.maxWidth),
                            onHorizontalDragUpdate: (details) => _updateIndexByDx(details.localPosition.dx, constraints.maxWidth),
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
              decoration: BoxDecoration(color: const Color(0xFF14233E), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF2A3E63))),
              child: selected == null
                  ? const Text(
                      '차트 위에 마우스를 올리면 종목별 당일 등락률을 확인할 수 있습니다.',
                      style: TextStyle(color: Color(0xFF8EA0C1), fontWeight: FontWeight.w700),
                    )
                  : Text(
                      '선택 종목: ${selected.assetName} (${selected.ticker}) / 당일 등락률 ${selected.changeRate >= 0 ? '+' : ''}${selected.changeRate.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: selected.changeRate >= 0 ? const Color(0xFFFF6B81) : const Color(0xFF5CA8FF),
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
    final total = positions.fold<double>(0, (sum, p) => sum + p.valuation);
    final sorted = [...positions]..sort((a, b) => b.valuation.compareTo(a.valuation));
    final top = sorted.isNotEmpty ? sorted.first : null;
    final topRatio = total > 0 && top != null ? (top.valuation / total) * 100 : 0.0;

    final riskLevel = topRatio >= 45
        ? '한 종목 쏠림 높음'
        : topRatio >= 30
            ? '집중도 주의'
            : '분산 양호';

    final action1 = top == null ? '보유 종목이 없습니다.' : '최대 비중 종목 ${top.assetName} ${topRatio.toStringAsFixed(1)}%: 목표 비중을 정해 분할 조정';
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
            const Text('포트폴리오 리스크 진단', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _metric('최대 보유 종목 비중', top == null ? '-' : '${topRatio.toStringAsFixed(1)}%', topRatio >= 45 ? const Color(0xFFFF6B81) : const Color(0xFF4C8DFF))),
                const SizedBox(width: 8),
                Expanded(child: _metric('분산 투자 상태', riskLevel, _riskColor(riskLevel))),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFF12213A), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF2A3E63))),
              child: const Text('설명: 최대 비중이 45%를 넘으면 포트폴리오 변동성이 급격히 커질 수 있습니다.', style: TextStyle(color: Color(0xFFDDE7FF), fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 10),
            const Text('추천 액션', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFDDE7FF))),
            const SizedBox(height: 6),
            _action(action1),
            _action(action2),
            _action(action3),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFF12213A), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF2A3E63))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF8EA0C1), fontSize: 12)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Color _riskColor(String riskLevel) {
    if (riskLevel.contains('높음')) return const Color(0xFFFF6B81);
    if (riskLevel.contains('주의')) return const Color(0xFFFFC56B);
    return const Color(0xFF6FB0FF);
  }

  Widget _action(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.fiber_manual_record_rounded, size: 8, color: Color(0xFF7F95BA)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0xFFD3DCF0), height: 1.35))),
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
    final m = advice.metrics;
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
                  child: Text('AI 포트폴리오 진단', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: riskColor.withOpacity(0.45)),
                  ),
                  child: Text(
                    m.riskLevel,
                    style: TextStyle(color: riskColor, fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              advice.insight.headline,
              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFE8EEFF)),
            ),
            const SizedBox(height: 4),
            Text(
              advice.insight.summary,
              style: const TextStyle(color: Color(0xFF9AA7C0), height: 1.35),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _metric('샤프지수', m.sharpeRatio.toStringAsFixed(2), const Color(0xFF65D6A5))),
                const SizedBox(width: 8),
                Expanded(child: _metric('연환산 변동성', '${m.annualVolatilityPct.toStringAsFixed(1)}%', const Color(0xFFFFC56B))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _metric('최대 낙폭(MDD)', '${m.maxDrawdownPct.toStringAsFixed(1)}%', const Color(0xFFFF6B81))),
                const SizedBox(width: 8),
                Expanded(child: _metric('분산 점수', '${m.diversificationScore.toStringAsFixed(1)}점', const Color(0xFF5CA8FF))),
              ],
            ),
            const SizedBox(height: 10),
            ...advice.insight.keyPoints.take(3).map(_bullet),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF12213A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A3E63)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF8EA0C1), fontSize: 12)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.fiber_manual_record_rounded, size: 7, color: Color(0xFF7F95BA)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0xFFD3DCF0), height: 1.35))),
        ],
      ),
    );
  }
}

class _PortfolioSimulationCard extends ConsumerStatefulWidget {
  const _PortfolioSimulationCard();

  @override
  ConsumerState<_PortfolioSimulationCard> createState() => _PortfolioSimulationCardState();
}

class _PortfolioSimulationCardState extends ConsumerState<_PortfolioSimulationCard> {
  static const int _initialContributionLimit = 3;
  static const int _contributionStep = 3;

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
    final next = math.min(total, _visibleContributionCount + _contributionStep);
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
    final query = PortfolioSimulationQuery(startDate: _startDate, endDate: _endDate);
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
                  child: Text('기간 수익 시뮬레이터', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                ),
                _TopCountBadge(label: _startDate == null && _endDate == null ? '매수일 기준' : '커스텀 기간'),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              '현재 보유 수량을 과거 가격에 대입해 특정 기간 수익을 재현합니다.',
              style: TextStyle(color: Color(0xFF8EA0C1), fontSize: 12),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _presetButton('1개월', () => _applyPreset(const Duration(days: 30))),
                _presetButton('3개월', () => _applyPreset(const Duration(days: 90))),
                _presetButton('6개월', () => _applyPreset(const Duration(days: 180))),
                _presetButton('1년', () => _applyPreset(const Duration(days: 365))),
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
                final won = NumberFormat.currency(locale: 'ko_KR', symbol: '₩', decimalDigits: 0);
                final profit = data.pnlAmount >= 0;
                final pnlColor = profit ? const Color(0xFFFF6B81) : const Color(0xFF5CA8FF);

                final contributions = data.contributions;
                final visibleCount = math.min(_visibleContributionCount, contributions.length);
                final visibleContributions = contributions.take(visibleCount).toList();
                final canExpand = visibleCount < contributions.length;
                final canCollapse = visibleCount > _initialContributionLimit;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFF12213A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF2A3E63)),
                      ),
                      child: Text(
                        '시뮬레이션 기간: ${data.startDate} ~ ${data.endDate} (${data.simulationDays}일)',
                        style: const TextStyle(color: Color(0xFFD3DCF0), fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _metric('기간 손익률', '${profit ? '+' : ''}${data.pnlRate.toStringAsFixed(2)}%', pnlColor)),
                        const SizedBox(width: 8),
                        Expanded(child: _metric('손익 금액', '${profit ? '+' : ''}${won.format(data.pnlAmount)}', pnlColor)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _metric('연환산 수익률', '${data.annualizedReturnPct.toStringAsFixed(2)}%', const Color(0xFF65D6A5))),
                        const SizedBox(width: 8),
                        Expanded(child: _metric('최대 낙폭(MDD)', '${data.maxDrawdownPct.toStringAsFixed(2)}%', const Color(0xFFFFC56B))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (data.timeline.isNotEmpty) ...[
                      const Text('기간 누적 수익 곡선', style: TextStyle(color: Color(0xFFDDE7FF), fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      SizedBox(height: 176, child: _SimulationTrendChart(timeline: data.timeline)),
                    ],
                    const SizedBox(height: 10),
                    const Text('종목 기여도 TOP', style: TextStyle(color: Color(0xFFDDE7FF), fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    if (visibleContributions.isEmpty)
                      const Text('기여도 데이터가 없습니다.', style: TextStyle(color: Color(0xFF9AA7C0)))
                    else
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: Column(
                          children: visibleContributions.map((item) {
                            final up = item.pnlAmount >= 0;
                            final color = up ? const Color(0xFFFF6B81) : const Color(0xFF5CA8FF);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF12213A),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF2A3E63)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${item.assetName} (${_normalizeTicker(item.symbol)})',
                                          style: const TextStyle(color: Color(0xFFE8EEFF), fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                      Text(
                                        '${up ? '+' : ''}${item.pnlRate.toStringAsFixed(2)}%',
                                        style: TextStyle(color: color, fontWeight: FontWeight.w900),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '기여 손익 ${up ? '+' : ''}${won.format(item.pnlAmount)} / 시작 ${won.format(item.startPrice)} → 기준 ${won.format(item.endPrice)}',
                                    style: const TextStyle(color: Color(0xFFD3DCF0), fontSize: 12),
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
                        onExpand: () => _expandContributions(contributions.length),
                        onCollapse: _collapseContributions,
                      ),
                    const SizedBox(height: 4),
                    ...data.notes.map(_note),
                  ],
                );
              },
              loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text('시뮬레이터 로딩 실패: $e', style: const TextStyle(color: Color(0xFFFF7B87))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF12213A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A3E63)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF8EA0C1), fontSize: 12)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _presetButton(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        side: const BorderSide(color: Color(0xFF314A74)),
        foregroundColor: const Color(0xFFD5E0F5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      child: Text(label),
    );
  }

  Widget _note(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF90A8CF)),
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF9FB0CD), fontSize: 12, height: 1.35))),
        ],
      ),
    );
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

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (timeline.length - 1).toDouble(),
        minY: -yRange,
        maxY: yRange,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yRange / 4,
          getDrawingHorizontalLine: (value) {
            if (value.abs() < 0.0001) return const FlLine(color: Color(0x664C8DFF), strokeWidth: 1.2);
            return const FlLine(color: Color(0x202B3B58), strokeWidth: 1);
          },
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                if (idx != 0 && idx != timeline.length ~/ 2 && idx != timeline.length - 1) {
                  return const SizedBox.shrink();
                }
                final date = timeline[idx].date;
                return Text(
                  date.length >= 10 ? date.substring(5, 10) : date,
                  style: const TextStyle(color: Color(0xFF7E90B2), fontSize: 10),
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
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
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
  State<_RebalancingActionsCard> createState() => _RebalancingActionsCardState();
}

class _RebalancingActionsCardState extends State<_RebalancingActionsCard> {
  static const int _initialVisibleLimit = 3;
  static const int _expandStep = 3;
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
        _visibleCount = math.max(minCount, math.min(_visibleCount, widget.actions.length));
      }
    }
  }

  int _initialCount(int total) => math.min(_initialVisibleLimit, total);

  void _expand() {
    final next = math.min(widget.actions.length, _visibleCount + _expandStep);
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
    final won = NumberFormat.currency(locale: 'ko_KR', symbol: '₩', decimalDigits: 0);
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
                Text('리밸런싱 권장 TOP ${actions.length}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(width: 8),
                _TopCountBadge(label: '총 ${widget.actions.length}건'),
              ],
            ),
            const SizedBox(height: 6),
            const Text('목표 비중 대비 이탈 구간을 우선순위로 정렬했습니다.', style: TextStyle(color: Color(0xFF8EA0C1), fontSize: 12)),
            const SizedBox(height: 10),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: widget.actions.isEmpty
                  ? const Text('현재 비중 이탈이 작아 즉시 조정 필요 종목이 없습니다.', style: TextStyle(color: Color(0xFFD3DCF0)))
                  : Column(
                      children: actions.map((action) {
                        final buy = action.action == 'BUY';
                        final accent = buy ? const Color(0xFF5CA8FF) : const Color(0xFFFF6B81);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF12213A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF2A3E63)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${action.assetName} (${_normalizeTicker(action.symbol)})',
                                      style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFE8EEFF)),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: accent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      buy ? '비중 확대' : '비중 축소',
                                      style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '현재 ${action.currentWeightPct.toStringAsFixed(1)}% → 목표 ${action.targetWeightPct.toStringAsFixed(1)}% / 권장 ${won.format(action.suggestedAmount)}',
                                style: const TextStyle(color: Color(0xFFD3DCF0), fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                action.reason,
                                style: const TextStyle(color: Color(0xFF9AA7C0), fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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
  static const int _expandStep = 2;
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
        _visibleCount = math.max(minCount, math.min(_visibleCount, widget.recommendations.length));
      }
    }
  }

  int _initialCount(int total) => math.min(_initialVisibleLimit, total);

  void _expand() {
    final next = math.min(widget.recommendations.length, _visibleCount + _expandStep);
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
    final recommendations = widget.recommendations.take(_visibleCount).toList();
    final canExpand = _visibleCount < widget.recommendations.length;
    final canCollapse = _visibleCount > _initialCount(widget.recommendations.length);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('추천 ETF TOP ${recommendations.length}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(width: 8),
                _TopCountBadge(label: '총 ${widget.recommendations.length}종목'),
              ],
            ),
            const SizedBox(height: 6),
            const Text('위험수준과 집중도를 반영한 대체 포지션 제안입니다.', style: TextStyle(color: Color(0xFF8EA0C1), fontSize: 12)),
            const SizedBox(height: 10),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: widget.recommendations.isEmpty
                  ? const Text('추천 가능한 ETF 후보가 없습니다.', style: TextStyle(color: Color(0xFFD3DCF0)))
                  : Column(
                      children: recommendations.map((etf) {
                        final color = etf.riskBucket == 'LOW'
                            ? const Color(0xFF65D6A5)
                            : etf.riskBucket == 'MID'
                                ? const Color(0xFFFFC56B)
                                : const Color(0xFFFF6B81);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF12213A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF2A3E63)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${etf.symbol} ${etf.name}',
                                      style: const TextStyle(color: Color(0xFFE8EEFF), fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  Text(
                                    '${etf.matchScore}점',
                                    style: TextStyle(color: color, fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${etf.focusTheme} · 권장 비중 ${etf.suggestedWeightPct.toStringAsFixed(1)}% · 총보수 ${etf.expenseRatioPct.toStringAsFixed(4)}%',
                                style: const TextStyle(color: Color(0xFFD3DCF0), fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                etf.reason,
                                style: const TextStyle(color: Color(0xFF9AA7C0), fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            if (widget.recommendations.length > _initialCount(widget.recommendations.length))
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
  static const int _expandStep = 3;
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
        _visibleCount = math.max(minCount, math.min(_visibleCount, widget.positions.length));
      }
    }
  }

  int _initialCount(int total) => math.min(_initialVisibleLimit, total);

  void _expand() {
    final next = math.min(widget.positions.length, _visibleCount + _expandStep);
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
    final won = NumberFormat.currency(locale: 'ko_KR', symbol: '₩', decimalDigits: 0);
    final positions = widget.positions.take(_visibleCount).toList();

    final totalValuation = widget.positions.fold<double>(0, (sum, p) => sum + p.valuation);
    final totalCost = widget.positions.fold<double>(0, (sum, p) => sum + p.avgCost * p.quantity);
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
                Text('보유 자산 TOP ${positions.length}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                const Spacer(),
                _TopCountBadge(label: '총 ${widget.positions.length}종목'),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: Column(
                children: positions.map((p) {
              final up = p.pnlRate >= 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF182540),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2E446A)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 34,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: up ? const Color(0xFFFF6B81) : const Color(0xFF5CA8FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.assetName, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFF3F6FF))),
                          const SizedBox(height: 2),
                          Text('${_normalizeTicker(p.symbol)}', style: const TextStyle(color: Color(0xFF91A0BC), fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(won.format(p.valuation), style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFF3F6FF))),
                        Text(
                          '${up ? '+' : ''}${p.pnlRate.toStringAsFixed(2)}%',
                          style: TextStyle(color: up ? const Color(0xFFFF6B81) : const Color(0xFF5CA8FF), fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              );
                }).toList(),
              ),
            ),
            if (widget.positions.length > _initialCount(widget.positions.length))
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
              decoration: BoxDecoration(color: const Color(0xFF12213A), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF2A3E63))),
              child: Row(
                children: [
                  const Text('포트폴리오 합계', style: TextStyle(color: Color(0xFF8EA0C1), fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Text(won.format(totalValuation), style: const TextStyle(color: Color(0xFFF3F6FF), fontWeight: FontWeight.w800)),
                  const SizedBox(width: 12),
                  Text(
                    '${totalProfit ? '+' : ''}${won.format(totalPnl)} (${totalProfit ? '+' : ''}${totalPnlRate.toStringAsFixed(2)}%)',
                    style: TextStyle(color: totalProfit ? const Color(0xFFFF6B81) : const Color(0xFF5CA8FF), fontWeight: FontWeight.w800),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x1F5CA8FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x553E6CB0)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFBAD2FF),
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
              foregroundColor: const Color(0xFF9FB3D8),
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.remove_circle_outline_rounded, size: 16),
            label: const Text('접기'),
          ),
        if (canExpand)
          FilledButton.tonalIcon(
            onPressed: onExpand,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0x2237D6B6),
              foregroundColor: const Color(0xFFBFF8ED),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
            label: Text('더보기 +$remainingCount'),
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
    return Card(child: SizedBox(height: height, child: const Center(child: CircularProgressIndicator())));
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
        child: Text('데이터를 불러오지 못했습니다: $message', style: const TextStyle(color: Color(0xFFFF7B87), fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _MarketBarPoint {
  _MarketBarPoint({required this.assetName, required this.ticker, required this.changeRate});

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
