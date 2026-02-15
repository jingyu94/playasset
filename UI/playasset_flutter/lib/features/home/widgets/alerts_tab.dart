import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/dashboard_models.dart';
import 'complementary_accent.dart';
import '../home_providers.dart';

class AlertsTab extends ConsumerWidget {
  const AlertsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(alertsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(alertsProvider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('알림 센터', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              ),
              const ComplementaryAccent(
                icon: Icons.notifications_active_rounded,
                primary: Color(0xFFFF8F6B),
                secondary: Color(0xFF58E5C3),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('우선순위 높은 이벤트부터 확인하세요.', style: TextStyle(color: Color(0xFF91A0BC))),
          const SizedBox(height: 16),
          asyncData.when(
            data: (alerts) => _buildAlertList(alerts),
            loading: () => const SizedBox(height: 260, child: Center(child: CircularProgressIndicator())),
            error: (error, _) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('오류: $error'))),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertList(List<AlertData> alerts) {
    if (alerts.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('표시할 알림이 없습니다.')));
    }

    return Column(
      children: alerts.map((alert) {
        final severityColor = switch (alert.severity) {
          'HIGH' => const Color(0xFFFF6B81),
          'MEDIUM' => const Color(0xFFFFB468),
          _ => const Color(0xFF8EA1C2),
        };

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [severityColor.withOpacity(0.09), const Color(0x00000000)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 58,
                    margin: const EdgeInsets.only(right: 10, top: 2),
                    decoration: BoxDecoration(color: severityColor, borderRadius: BorderRadius.circular(999)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(alert.title, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFF3F6FF)))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: severityColor.withOpacity(0.2)),
                              child: Text(alert.severity, style: TextStyle(color: severityColor, fontWeight: FontWeight.w900, fontSize: 11)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(alert.message, style: const TextStyle(height: 1.35, color: Color(0xFFD3DCF0))),
                        const SizedBox(height: 8),
                        Text('${alert.eventType} · ${alert.status} · ${alert.occurredAt}', style: const TextStyle(color: Color(0xFF91A0BC), fontSize: 12)),
                      ],
                    ),
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
