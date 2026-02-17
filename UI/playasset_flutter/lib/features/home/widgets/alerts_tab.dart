import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/dashboard_models.dart';
import 'complementary_accent.dart';
import '../home_providers.dart';

class AlertsTab extends ConsumerStatefulWidget {
  const AlertsTab({super.key});

  @override
  ConsumerState<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends ConsumerState<AlertsTab> {
  bool _savingPreference = false;
  String? _preferenceError;

  Future<void> _updatePreference(
    AlertPreferenceData current, {
    bool? lowEnabled,
    bool? mediumEnabled,
    bool? highEnabled,
  }) async {
    final next = current.copyWith(
      lowEnabled: lowEnabled,
      mediumEnabled: mediumEnabled,
      highEnabled: highEnabled,
    );

    if (!next.lowEnabled && !next.mediumEnabled && !next.highEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('레벨은 최소 1개 이상 켜 주세요.')),
      );
      return;
    }

    setState(() {
      _savingPreference = true;
      _preferenceError = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final userId = ref.read(currentUserIdProvider);
      await api.updateAlertPreference(
        userId,
        lowEnabled: next.lowEnabled,
        mediumEnabled: next.mediumEnabled,
        highEnabled: next.highEnabled,
      );
      ref.invalidate(alertPreferenceProvider);
      ref.invalidate(alertsProvider);
      ref.invalidate(dashboardProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _preferenceError = '알림 레벨 저장에 실패했습니다: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _savingPreference = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(alertsProvider);
    final preferenceAsync = ref.watch(alertPreferenceProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(alertsProvider);
        ref.invalidate(alertPreferenceProvider);
        ref.invalidate(dashboardProvider);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '알림 센터',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              const ComplementaryAccent(
                icon: Icons.notifications_active_rounded,
                primary: Color(0xFFFF8F6B),
                secondary: Color(0xFF58E5C3),
              ),
            ],
          ),
          const SizedBox(height: 12),
          preferenceAsync.when(
            data: (pref) => _AlertPreferenceCard(
              preference: pref,
              saving: _savingPreference,
              errorText: _preferenceError,
              onToggleLow: () =>
                  _updatePreference(pref, lowEnabled: !pref.lowEnabled),
              onToggleMedium: () =>
                  _updatePreference(pref, mediumEnabled: !pref.mediumEnabled),
              onToggleHigh: () =>
                  _updatePreference(pref, highEnabled: !pref.highEnabled),
            ),
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                    height: 70,
                    child: Center(child: CircularProgressIndicator())),
              ),
            ),
            error: (error, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('알림 레벨 설정을 불러오지 못했습니다: $error'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          alertsAsync.when(
            data: (alerts) => _buildAlertList(alerts),
            loading: () => const SizedBox(
                height: 260, child: Center(child: CircularProgressIndicator())),
            error: (error, _) => Card(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('오류: $error'))),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertList(List<AlertData> alerts) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleText =
        isDark ? const Color(0xFFF3F6FF) : const Color(0xFF13233A);
    final bodyText = isDark ? const Color(0xFFD3DCF0) : const Color(0xFF28465C);
    final metaText = isDark ? const Color(0xFF91A0BC) : const Color(0xFF3E5A6E);
    if (alerts.isEmpty) {
      return const Card(
          child: Padding(
              padding: EdgeInsets.all(16), child: Text('표시할 알림이 없습니다.')));
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
                colors: [
                  severityColor.withValues(alpha: 0.09),
                  const Color(0x00000000)
                ],
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
                    decoration: BoxDecoration(
                        color: severityColor,
                        borderRadius: BorderRadius.circular(999)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                alert.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: titleText,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                color: severityColor.withValues(alpha: 0.2),
                              ),
                              child: Text(
                                alert.severity,
                                style: TextStyle(
                                    color: severityColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          alert.message,
                          style: TextStyle(height: 1.35, color: bodyText),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${alert.eventType} · ${alert.status} · ${alert.occurredAt}',
                          style: TextStyle(color: metaText, fontSize: 12),
                        ),
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

class _AlertPreferenceCard extends StatelessWidget {
  const _AlertPreferenceCard({
    required this.preference,
    required this.saving,
    required this.errorText,
    required this.onToggleLow,
    required this.onToggleMedium,
    required this.onToggleHigh,
  });

  final AlertPreferenceData preference;
  final bool saving;
  final String? errorText;
  final VoidCallback onToggleLow;
  final VoidCallback onToggleMedium;
  final VoidCallback onToggleHigh;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleText =
        isDark ? const Color(0xFFF3F6FF) : const Color(0xFF13233A);
    final subText = isDark ? const Color(0xFF91A0BC) : const Color(0xFF3E5A6E);
    final enabledCount = [
      preference.lowEnabled,
      preference.mediumEnabled,
      preference.highEnabled,
    ].where((e) => e).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '수신 레벨 설정',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: titleText,
                    ),
                  ),
                ),
                if (saving)
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '현재 $enabledCount개 레벨 수신 중',
              style: TextStyle(color: subText, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _levelChip(
                  label: 'HIGH',
                  enabled: preference.highEnabled,
                  color: const Color(0xFFFF6B81),
                  isDark: isDark,
                  onTap: saving ? null : onToggleHigh,
                ),
                _levelChip(
                  label: 'MEDIUM',
                  enabled: preference.mediumEnabled,
                  color: const Color(0xFFFFB468),
                  isDark: isDark,
                  onTap: saving ? null : onToggleMedium,
                ),
                _levelChip(
                  label: 'LOW',
                  enabled: preference.lowEnabled,
                  color: const Color(0xFF8EA1C2),
                  isDark: isDark,
                  onTap: saving ? null : onToggleLow,
                ),
              ],
            ),
            if (errorText != null) ...[
              const SizedBox(height: 8),
              Text(errorText!,
                  style:
                      const TextStyle(color: Color(0xFFFF7B87), fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _levelChip({
    required String label,
    required bool enabled,
    required Color color,
    required bool isDark,
    required VoidCallback? onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: enabled,
      onSelected: onTap == null ? null : (_) => onTap(),
      selectedColor: color.withValues(alpha: 0.24),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: enabled
            ? color
            : (isDark ? const Color(0xFFD3DCF0) : const Color(0xFF2F4D68)),
        fontWeight: FontWeight.w800,
      ),
      side: BorderSide(
        color: enabled
            ? color.withValues(alpha: 0.7)
            : (isDark ? const Color(0xFF2A3E63) : const Color(0xFF9DB8D7)),
      ),
      backgroundColor:
          isDark ? const Color(0xFF12213A) : const Color(0xFFF1F7FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}
