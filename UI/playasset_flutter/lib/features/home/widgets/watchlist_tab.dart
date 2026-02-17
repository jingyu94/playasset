import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/dashboard_models.dart';
import 'asset_detail_sheet.dart';
import 'complementary_accent.dart';
import '../home_providers.dart';

class WatchlistTab extends ConsumerStatefulWidget {
  const WatchlistTab({super.key});

  @override
  ConsumerState<WatchlistTab> createState() => _WatchlistTabState();
}

class _WatchlistTabState extends ConsumerState<WatchlistTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(watchlistProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(watchlistProvider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '관심 종목',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              const ComplementaryAccent(
                icon: Icons.candlestick_chart_rounded,
                primary: Color(0xFFFFC15D),
                secondary: Color(0xFF5CA8FF),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '종목명 또는 티커 검색',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: '검색어 지우기',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          asyncData.when(
            data: (data) => _buildList(context, data),
            loading: () => const SizedBox(
              height: 260,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('조회에 실패했어요: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<WatchlistItemData> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final won =
        NumberFormat.currency(locale: 'ko_KR', symbol: '₩ ', decimalDigits: 0);
    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? items
        : items
            .where(
              (e) =>
                  e.assetName.toLowerCase().contains(query) ||
                  e.symbol.toLowerCase().contains(query),
            )
            .toList();

    if (filtered.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '검색 조건에 맞는 종목이 없어요.',
            style: TextStyle(
              color: isDark ? const Color(0xFF9AACCA) : const Color(0xFF45607A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    final domestic = <WatchlistItemData>[];
    final overseas = <WatchlistItemData>[];
    for (final item in filtered) {
      if (_isDomesticTicker(item.symbol)) {
        domestic.add(item);
      } else {
        overseas.add(item);
      }
    }

    return Column(
      children: [
        _MarketSection(
          title: '국내주식',
          items: domestic,
          won: won,
          emptyText: '국내주식 관심 종목이 없어요.',
          onTapItem: _showWatchlistDetail,
        ),
        const SizedBox(height: 10),
        _MarketSection(
          title: '해외주식',
          items: overseas,
          won: won,
          emptyText: '해외주식 관심 종목이 없어요.',
          onTapItem: _showWatchlistDetail,
        ),
      ],
    );
  }

  void _showWatchlistDetail(WatchlistItemData item) {
    showAssetDetailSheet(
      context,
      data: AssetDetailSheetData(
        assetName: item.assetName,
        symbol: item.symbol,
        price: item.lastPrice,
        changeRate: item.changeRate,
        note: item.note,
      ),
    );
  }

  bool _isDomesticTicker(String symbol) {
    final normalized = symbol.trim().toUpperCase();
    return RegExp(r'^\d{5,6}$').hasMatch(normalized) ||
        RegExp(r'^A\d{6}$').hasMatch(normalized);
  }
}

class _MarketSection extends StatelessWidget {
  const _MarketSection({
    required this.title,
    required this.items,
    required this.won,
    required this.emptyText,
    required this.onTapItem,
  });

  final String title;
  final List<WatchlistItemData> items;
  final NumberFormat won;
  final String emptyText;
  final ValueChanged<WatchlistItemData> onTapItem;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sectionBg =
        isDark ? const Color(0xFF0A1322) : const Color(0xFFF5F8FD);
    final sectionBorder =
        isDark ? const Color(0xFF24334A) : const Color(0xFFD6E1EF);
    final titleText =
        isDark ? const Color(0xFFEAF1FF) : const Color(0xFF1A2D45);
    final subText = isDark ? const Color(0xFF92A4C3) : const Color(0xFF4B6682);

    return Container(
      decoration: BoxDecoration(
        color: sectionBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sectionBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleText,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF12243E)
                        : const Color(0xFFE7F0FC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${items.length}종목',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFB8CCF0)
                          : const Color(0xFF35577A),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: subText.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    emptyText,
                    style: TextStyle(
                      color: subText,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              itemCount: items.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: sectionBorder.withValues(alpha: isDark ? 0.85 : 0.9),
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return _WatchlistRow(
                  item: item,
                  won: won,
                  onTap: () => onTapItem(item),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _WatchlistRow extends StatelessWidget {
  const _WatchlistRow({
    required this.item,
    required this.won,
    required this.onTap,
  });

  final WatchlistItemData item;
  final NumberFormat won;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final positive = item.changeRate >= 0;
    final changeColor =
        positive ? const Color(0xFFFF6B81) : const Color(0xFF5CA8FF);
    final titleText =
        isDark ? const Color(0xFFF2F7FF) : const Color(0xFF1A2D45);
    final subText = isDark ? const Color(0xFF8FA1C0) : const Color(0xFF4A6581);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            _TickerAvatar(symbol: item.symbol),
            const SizedBox(width: 10),
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
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.symbol,
                    style: TextStyle(
                      color: subText,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  won.format(item.lastPrice),
                  style: TextStyle(
                    color: titleText,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${positive ? '+' : ''}${item.changeRate.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: changeColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TickerAvatar extends StatelessWidget {
  const _TickerAvatar({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context) {
    final seed = symbol.codeUnits.fold<int>(0, (acc, c) => acc + c);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = <Color>[
      const Color(0xFF2A5EA8),
      const Color(0xFF2E7A9B),
      const Color(0xFF356E60),
      const Color(0xFF775A9A),
      const Color(0xFF8A5B5B),
    ];
    final base = palette[seed % palette.length];
    final bg =
        isDark ? base.withValues(alpha: 0.26) : base.withValues(alpha: 0.16);
    final border =
        isDark ? base.withValues(alpha: 0.52) : base.withValues(alpha: 0.34);

    final label = symbol.length <= 4
        ? symbol.toUpperCase()
        : symbol.substring(0, 4).toUpperCase();

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? const Color(0xFFEAF1FF) : const Color(0xFF173A55),
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}
