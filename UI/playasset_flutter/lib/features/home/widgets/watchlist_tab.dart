import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/dashboard_models.dart';
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
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('관심종목', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              ),
              const ComplementaryAccent(
                icon: Icons.candlestick_chart_rounded,
                primary: Color(0xFFFFC15D),
                secondary: Color(0xFF5CA8FF),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('중요 자산의 흐름을 빠르게 추적하세요.', style: TextStyle(color: Color(0xFF91A0BC))),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: '종목명 또는 심볼 검색',
              prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF91A0BC)),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          asyncData.when(
            data: (data) => _buildList(context, data),
            loading: () => const SizedBox(height: 260, child: Center(child: CircularProgressIndicator())),
            error: (error, _) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('오류: $error'))),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<WatchlistItemData> items) {
    final won = NumberFormat.currency(locale: 'ko_KR', symbol: '원 ', decimalDigits: 0);
    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? items
        : items.where((e) => e.assetName.toLowerCase().contains(query) || e.symbol.toLowerCase().contains(query)).toList();

    if (filtered.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('검색 조건에 맞는 종목이 없습니다.')));
    }

    return Column(
      children: filtered.map((item) {
        final positive = item.changeRate >= 0;
        final accent = positive ? const Color(0xFFFF6B81) : const Color(0xFF5CA8FF);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [accent.withOpacity(0.08), const Color(0x00000000)],
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF1A2740),
                  border: Border.all(color: const Color(0xFF2E446A)),
                ),
                child: Center(
                  child: Text(
                    item.symbol.substring(item.symbol.length > 3 ? item.symbol.length - 3 : 0),
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFD8E4FF), fontSize: 12),
                  ),
                ),
              ),
              title: Text(item.assetName, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFF3F6FF))),
              subtitle: Text(item.note.isEmpty ? '메모 없음' : item.note, style: const TextStyle(color: Color(0xFF91A0BC))),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(won.format(item.lastPrice), style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFF3F6FF))),
                  Text(
                    '${positive ? '+' : ''}${item.changeRate.toStringAsFixed(2)}%',
                    style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
