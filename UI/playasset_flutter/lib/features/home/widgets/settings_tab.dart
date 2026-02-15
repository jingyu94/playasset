import 'package:flutter/material.dart';

import '../../../core/config/app_env.dart';
import 'complementary_accent.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('설정', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            ),
            const ComplementaryAccent(
              icon: Icons.tune_rounded,
              primary: Color(0xFF7BD88F),
              secondary: Color(0xFFFFC56B),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('외부 API 키는 비워둔 상태입니다. 배포 환경에서만 시크릿으로 주입하세요.', style: TextStyle(color: Color(0xFF91A0BC))),
        const SizedBox(height: 16),
        _KeyCard(title: '백엔드 API', value: AppEnv.apiBaseUrl, hint: 'dart-define: API_BASE_URL'),
        const SizedBox(height: 12),
        _KeyCard(title: 'Market API Key', value: AppEnv.externalMarketApiKey.isEmpty ? '미설정' : '설정됨', hint: 'EXTERNAL_MARKET_API_KEY'),
        const SizedBox(height: 12),
        _KeyCard(title: 'News API Key', value: AppEnv.externalNewsApiKey.isEmpty ? '미설정' : '설정됨', hint: 'EXTERNAL_NEWS_API_KEY'),
      ],
    );
  }
}

class _KeyCard extends StatelessWidget {
  const _KeyCard({required this.title, required this.value, required this.hint});

  final String title;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFF3F6FF))),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFD8E4FF))),
            const SizedBox(height: 4),
            Text(hint, style: const TextStyle(fontSize: 12, color: Color(0xFF91A0BC))),
          ],
        ),
      ),
    );
  }
}
