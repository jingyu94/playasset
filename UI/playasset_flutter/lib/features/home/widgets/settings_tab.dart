import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_env.dart';
import '../../../core/models/dashboard_models.dart';
import '../home_providers.dart';
import 'complementary_accent.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sectionTitle =
        isDark ? const Color(0xFFEAF1FF) : const Color(0xFF0E2034);
    final session = ref.watch(sessionControllerProvider).session;
    final profile = ref.watch(investmentProfileProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '설정',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            const ComplementaryAccent(
              icon: Icons.tune_rounded,
              primary: Color(0xFF7BD88F),
              secondary: Color(0xFFFFC56B),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _InvestmentProfileCard(profile: profile),
        const SizedBox(height: 12),
        if (session != null) ...[
          _InfoCard(
            title: '로그인 사용자',
            value: '${session.displayName} (${session.loginId})',
            hint: '권한: ${session.roles.join(', ')}',
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              await ref.read(sessionControllerProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('로그아웃'),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          '환경 정보',
          style: TextStyle(
            color: sectionTitle,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        _InfoCard(
          title: '백엔드 API',
          value: AppEnv.apiBaseUrl,
          hint: 'dart-define: API_BASE_URL',
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Market API Key',
          value: AppEnv.externalMarketApiKey.isEmpty ? '미설정' : '설정됨',
          hint: 'EXTERNAL_MARKET_API_KEY',
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'News API Key',
          value: AppEnv.externalNewsApiKey.isEmpty ? '미설정' : '설정됨',
          hint: 'EXTERNAL_NEWS_API_KEY',
        ),
      ],
    );
  }
}

class _InvestmentProfileCard extends ConsumerWidget {
  const _InvestmentProfileCard({required this.profile});

  final InvestmentProfileData? profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleText =
        isDark ? const Color(0xFFF3F6FF) : const Color(0xFF132231);
    final bodyText = isDark ? const Color(0xFFD8E4FF) : const Color(0xFF1F334D);
    final panelBg = isDark ? const Color(0xFF12213A) : const Color(0xFFEFF5FF);
    final panelBorder =
        isDark ? const Color(0xFF2A3E63) : const Color(0xFFC6D8F3);
    final panelTitle =
        isDark ? const Color(0xFFEAF1FF) : const Color(0xFF1A3254);
    final panelHint =
        isDark ? const Color(0xFFABC0E3) : const Color(0xFF345372);
    final panelSubHint =
        isDark ? const Color(0xFF8EA0C1) : const Color(0xFF425E7E);
    final dateFmt = DateFormat('M월 d일 HH:mm', 'ko_KR');
    final updatedAt = profile == null
        ? null
        : DateTime.tryParse(profile!.updatedAt)?.toLocal();

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
                    '투자 성향 진단',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: titleText,
                    ),
                  ),
                ),
                if (profile != null)
                  _RiskTierBadge(
                    label: profile!.shortLabel,
                    tier: profile!.riskTier,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (profile == null)
              Text(
                '아직 성향 진단이 없어요. 1분 설문만 하면 내 포트 기준으로 개선 방향을 바로 보여줘요.',
                style: TextStyle(color: bodyText, height: 1.35),
              )
            else ...[
              Text(
                profile!.profileName,
                style: TextStyle(
                  color: titleText,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                profile!.summary,
                style: TextStyle(color: bodyText, height: 1.35),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  color: panelBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: panelBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '리스크 점수 ${profile!.score}점 / 24점',
                      style: TextStyle(
                        color: panelTitle,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '권장 운용 힌트: ${profile!.targetAllocationHint}',
                      style: TextStyle(
                        color: panelHint,
                        fontSize: 12,
                      ),
                    ),
                    if (updatedAt != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        '최근 진단: ${dateFmt.format(updatedAt)}',
                        style: TextStyle(
                          color: panelSubHint,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const InvestmentProfileSurveyPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.quiz_rounded),
                    label: Text(profile == null ? '설문 시작' : '설문 다시 하기'),
                  ),
                ),
                if (profile != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref
                          .read(investmentProfileProvider.notifier)
                          .clear();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('초기화'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class InvestmentProfileSurveyPage extends ConsumerStatefulWidget {
  const InvestmentProfileSurveyPage({super.key});

  @override
  ConsumerState<InvestmentProfileSurveyPage> createState() =>
      _InvestmentProfileSurveyPageState();
}

class _InvestmentProfileSurveyPageState
    extends ConsumerState<InvestmentProfileSurveyPage> {
  late final Map<String, int> _answers;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(investmentProfileProvider);
    _answers = {...?saved?.answers};
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final infoBg = isDark ? const Color(0xFF12213A) : const Color(0xFFEFF5FF);
    final infoBorder =
        isDark ? const Color(0xFF2A3E63) : const Color(0xFFC6D8F3);
    final infoText = isDark ? const Color(0xFFD8E4FF) : const Color(0xFF213852);
    final allAnswered =
        _riskQuestions.every((question) => _answers.containsKey(question.id));
    final preview = allAnswered ? _evaluateRiskProfile(_answers) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('투자 성향 설문'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: infoBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: infoBorder),
            ),
            child: Text(
              '표준 성향 진단 기준(투자기간, 손실 감내, 유동성, 투자경험)을 바탕으로 분류해요.\n'
              '마지막 구간에 초고위험형(리스크 매드맥스형)을 추가해서 선택 폭을 넓혔어요.',
              style: TextStyle(color: infoText, height: 1.35),
            ),
          ),
          const SizedBox(height: 12),
          ..._riskQuestions.map((question) {
            final selected = _answers[question.id];
            return _QuestionCard(
              question: question,
              selectedScore: selected,
              onSelected: (score) {
                setState(() {
                  _answers[question.id] = score;
                });
              },
            );
          }),
          const SizedBox(height: 10),
          if (preview != null) _PreviewCard(profile: preview),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: allAnswered
                ? () async {
                    final profile = _evaluateRiskProfile(_answers);
                    await ref
                        .read(investmentProfileProvider.notifier)
                        .save(profile);
                    if (!mounted) return;
                    Navigator.of(context).pop();
                  }
                : null,
            icon: const Icon(Icons.task_alt_rounded),
            label: const Text('성향 저장하고 적용'),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.selectedScore,
    required this.onSelected,
  });

  final _RiskQuestion question;
  final int? selectedScore;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleText =
        isDark ? const Color(0xFFF3F6FF) : const Color(0xFF132231);
    final guideText =
        isDark ? const Color(0xFF9FB1CF) : const Color(0xFF385571);
    final optionBg = isDark ? const Color(0xFF12213A) : const Color(0xFFF2F7FF);
    final optionBorder =
        isDark ? const Color(0xFF2A3E63) : const Color(0xFFC9D9F0);
    final optionTitle =
        isDark ? const Color(0xFFEAF1FF) : const Color(0xFF1C3558);
    final optionDetail =
        isDark ? const Color(0xFFA9BDE1) : const Color(0xFF3E5F84);
    final unselectedRadio =
        isDark ? const Color(0xFF7E90B2) : const Color(0xFF6C84A7);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.title,
              style: TextStyle(
                color: titleText,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              question.guide,
              style: TextStyle(color: guideText, fontSize: 12),
            ),
            const SizedBox(height: 10),
            ...question.options.map((option) {
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onSelected(option.score),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 7),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  decoration: BoxDecoration(
                    color: selectedScore == option.score
                        ? const Color(0x1E4C8DFF)
                        : optionBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selectedScore == option.score
                          ? const Color(0xFF4C8DFF)
                          : optionBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedScore == option.score
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: selectedScore == option.score
                            ? const Color(0xFF7FB1FF)
                            : unselectedRadio,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option.label,
                              style: TextStyle(
                                color: optionTitle,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              option.detail,
                              style: TextStyle(
                                color: optionDetail,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.profile});

  final InvestmentProfileData profile;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelBg = isDark ? const Color(0xFF112038) : const Color(0xFFEFF5FF);
    final panelBorder =
        isDark ? const Color(0xFF2D456E) : const Color(0xFFC7D9F2);
    final titleText =
        isDark ? const Color(0xFFF3F6FF) : const Color(0xFF132231);
    final bodyText = isDark ? const Color(0xFFD3DCF0) : const Color(0xFF203B59);
    final hintText = isDark ? const Color(0xFF9FB4D8) : const Color(0xFF3D5E82);
    final scoreText =
        isDark ? const Color(0xFF7FD6B2) : const Color(0xFF1E8C63);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '예상 결과: ${profile.profileName}',
                  style: TextStyle(
                    color: titleText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _RiskTierBadge(label: profile.shortLabel, tier: profile.riskTier),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            profile.summary,
            style: TextStyle(color: bodyText, height: 1.33),
          ),
          const SizedBox(height: 6),
          Text(
            '권장 운용 힌트: ${profile.targetAllocationHint}',
            style: TextStyle(color: hintText, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            '리스크 점수 ${profile.score} / 24',
            style: TextStyle(color: scoreText, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RiskTierBadge extends StatelessWidget {
  const _RiskTierBadge({
    required this.label,
    required this.tier,
  });

  final String label;
  final int tier;

  @override
  Widget build(BuildContext context) {
    final color = switch (tier) {
      1 => const Color(0xFF65D6A5),
      2 => const Color(0xFF89DA9A),
      3 => const Color(0xFF8EC7FF),
      4 => const Color(0xFFFFC56B),
      5 => const Color(0xFFFF8E66),
      _ => const Color(0xFFFF5D73),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.value,
    required this.hint,
  });

  final String title;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleText =
        isDark ? const Color(0xFFF3F6FF) : const Color(0xFF132231);
    final valueText =
        isDark ? const Color(0xFFD8E4FF) : const Color(0xFF253A54);
    final hintText = isDark ? const Color(0xFF91A0BC) : const Color(0xFF3F5B74);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: titleText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: valueText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hint,
              style: TextStyle(fontSize: 12, color: hintText),
            ),
          ],
        ),
      ),
    );
  }
}

InvestmentProfileData _evaluateRiskProfile(Map<String, int> answers) {
  final score = answers.values.fold<int>(0, (sum, value) => sum + value);
  final template = _profileFromScore(score);
  return InvestmentProfileData(
    profileKey: template.key,
    profileName: template.name,
    shortLabel: template.shortLabel,
    summary: template.summary,
    score: score,
    riskTier: template.riskTier,
    targetAllocationHint: template.targetAllocationHint,
    updatedAt: DateTime.now().toUtc().toIso8601String(),
    answers: {...answers},
  );
}

_RiskProfileTemplate _profileFromScore(int score) {
  if (score <= 5) return _riskProfiles[0];
  if (score <= 9) return _riskProfiles[1];
  if (score <= 13) return _riskProfiles[2];
  if (score <= 17) return _riskProfiles[3];
  if (score <= 21) return _riskProfiles[4];
  return _riskProfiles[5];
}

const _riskQuestions = <_RiskQuestion>[
  _RiskQuestion(
    id: 'horizon',
    title: '1. 투자기간은 어느 정도를 생각해요?',
    guide: '일반적으로 기간이 길수록 변동성을 감내하기 쉬워요.',
    options: [
      _RiskOption(label: '1년 미만', detail: '단기 자금 중심', score: 0),
      _RiskOption(label: '1~3년', detail: '중단기 목표 자금', score: 1),
      _RiskOption(label: '3~7년', detail: '중기 성장 목표', score: 3),
      _RiskOption(label: '7년 이상', detail: '장기 복리 중심', score: 4),
    ],
  ),
  _RiskQuestion(
    id: 'drawdown',
    title: '2. 한 달 만에 -15%가 나면 어떤가요?',
    guide: '손실 감내 성향은 핵심 분류 기준이에요.',
    options: [
      _RiskOption(label: '즉시 대부분 매도', detail: '원금 보전 최우선', score: 0),
      _RiskOption(label: '일부 줄인다', detail: '손실 제한 우선', score: 1),
      _RiskOption(label: '그대로 유지', detail: '기준 전략 유지', score: 3),
      _RiskOption(label: '추가 매수 고려', detail: '하락 구간 분할매수', score: 4),
    ],
  ),
  _RiskQuestion(
    id: 'goal',
    title: '3. 더 중요한 목표는 무엇인가요?',
    guide: '수익/안정 우선순위를 물어보는 항목이에요.',
    options: [
      _RiskOption(label: '원금 보전', detail: '수익보다 안정', score: 0),
      _RiskOption(label: '물가+α 수익', detail: '안정+완만한 성장', score: 1),
      _RiskOption(label: '시장 평균 수익', detail: '균형 추구', score: 3),
      _RiskOption(label: '고수익 최대화', detail: '변동성 감수', score: 4),
    ],
  ),
  _RiskQuestion(
    id: 'liquidity',
    title: '4. 이 자금을 중간에 꺼낼 가능성은?',
    guide: '유동성 필요가 높으면 위험자산 비중을 낮추는 게 일반적이에요.',
    options: [
      _RiskOption(label: '높다', detail: '1년 내 사용할 수 있어요', score: 0),
      _RiskOption(label: '보통', detail: '상황 따라 일부 인출 가능', score: 2),
      _RiskOption(label: '낮다', detail: '장기 묶어둘 수 있어요', score: 4),
    ],
  ),
  _RiskQuestion(
    id: 'experience',
    title: '5. 투자 경험은 어느 정도예요?',
    guide: '경험 수준은 전략 복잡도와 직결돼요.',
    options: [
      _RiskOption(label: '입문', detail: '예금/적금 위주', score: 0),
      _RiskOption(label: '초중급', detail: 'ETF/주식 기본 운용', score: 2),
      _RiskOption(label: '중상급', detail: '리밸런싱/자산배분 경험', score: 3),
      _RiskOption(label: '고급', detail: '옵션/레버리지도 이해', score: 4),
    ],
  ),
  _RiskQuestion(
    id: 'volatility_behavior',
    title: '6. 변동성이 커질 때 보통 어떻게 하나요?',
    guide: '실제 행동 패턴이 성향 진단 정확도를 높여요.',
    options: [
      _RiskOption(label: '뉴스 보고 자주 매매', detail: '감정 영향 큼', score: 0),
      _RiskOption(label: '비중 소폭 조절', detail: '리스크 관리 중심', score: 2),
      _RiskOption(label: '기준 전략 유지', detail: '계획형 운용', score: 3),
      _RiskOption(label: '공격적으로 기회 포착', detail: '고변동성 적극 활용', score: 4),
    ],
  ),
];

const _riskProfiles = <_RiskProfileTemplate>[
  _RiskProfileTemplate(
    key: 'capital_preserver',
    name: '안정형',
    shortLabel: '안정형',
    riskTier: 1,
    summary: '원금 보전과 변동성 최소화를 우선해요.',
    targetAllocationHint: '채권/현금성 비중 높게, 주식은 보조로 운용',
  ),
  _RiskProfileTemplate(
    key: 'income_focused',
    name: '안정추구형',
    shortLabel: '안정추구',
    riskTier: 2,
    summary: '수익은 챙기되 큰 손실은 피하고 싶어해요.',
    targetAllocationHint: '배당/우량채권 중심 + 주식 비중 제한',
  ),
  _RiskProfileTemplate(
    key: 'balanced',
    name: '균형형',
    shortLabel: '균형형',
    riskTier: 3,
    summary: '수익과 안정의 균형을 동시에 노려요.',
    targetAllocationHint: '주식/채권 균형 배분 + 정기 리밸런싱',
  ),
  _RiskProfileTemplate(
    key: 'growth',
    name: '성장형',
    shortLabel: '성장형',
    riskTier: 4,
    summary: '중장기 수익 성장에 더 무게를 둬요.',
    targetAllocationHint: '주식 비중 확대 + 섹터/지역 분산',
  ),
  _RiskProfileTemplate(
    key: 'aggressive',
    name: '공격형',
    shortLabel: '공격형',
    riskTier: 5,
    summary: '단기 변동을 감수하고 고수익 기회를 선호해요.',
    targetAllocationHint: '성장자산 중심 + 변동성 관리 룰 필수',
  ),
  _RiskProfileTemplate(
    key: 'mad_max',
    name: '리스크 매드맥스형',
    shortLabel: 'MAD MAX',
    riskTier: 6,
    summary: '초고위험/초고변동 전략도 감수하는 하이리스크 성향이에요.',
    targetAllocationHint: '고위험 자산 비중 높음, 손실 한도/현금버퍼 강제 설정',
  ),
];

class _RiskQuestion {
  const _RiskQuestion({
    required this.id,
    required this.title,
    required this.guide,
    required this.options,
  });

  final String id;
  final String title;
  final String guide;
  final List<_RiskOption> options;
}

class _RiskOption {
  const _RiskOption({
    required this.label,
    required this.detail,
    required this.score,
  });

  final String label;
  final String detail;
  final int score;
}

class _RiskProfileTemplate {
  const _RiskProfileTemplate({
    required this.key,
    required this.name,
    required this.shortLabel,
    required this.riskTier,
    required this.summary,
    required this.targetAllocationHint,
  });

  final String key;
  final String name;
  final String shortLabel;
  final int riskTier;
  final String summary;
  final String targetAllocationHint;
}
