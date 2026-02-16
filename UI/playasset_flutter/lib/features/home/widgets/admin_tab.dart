import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/dashboard_models.dart';
import '../home_providers.dart';

class AdminTab extends ConsumerWidget {
  const AdminTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policyAsync = ref.watch(paidServicePoliciesProvider);
    final usersAsync = ref.watch(adminUsersProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(paidServicePoliciesProvider);
        ref.invalidate(adminUsersProvider);
        await Future.wait([
          ref.read(paidServicePoliciesProvider.future),
          ref.read(adminUsersProvider.future),
        ]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          const Text(
            '운영 관리자',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            '유료 호출 정책과 사용자 권한을 실시간으로 제어해요.',
            style: TextStyle(fontSize: 13, color: Color(0xFF8A97B3)),
          ),
          const SizedBox(height: 20),
          _sectionTitle('일일 호출 한도 정책'),
          const SizedBox(height: 10),
          policyAsync.when(
            data: (list) {
              if (list.isEmpty) {
                return const _EmptyBox(message: '정책 데이터가 없습니다.');
              }
              return Column(
                children: list.map((item) => _PolicyCard(policy: item)).toList(),
              );
            },
            loading: () => const _LoadingBox(),
            error: (e, _) => _ErrorBox(message: '정책 조회 실패: $e'),
          ),
          const SizedBox(height: 24),
          _sectionTitle('관리자 권한 설정'),
          const SizedBox(height: 10),
          usersAsync.when(
            data: (list) {
              if (list.isEmpty) {
                return const _EmptyBox(message: '사용자 데이터가 없습니다.');
              }
              return Column(
                children: list.map((user) => _UserRoleCard(user: user)).toList(),
              );
            },
            loading: () => const _LoadingBox(),
            error: (e, _) => _ErrorBox(message: '사용자 조회 실패: $e'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    );
  }
}

class _PolicyCard extends ConsumerStatefulWidget {
  const _PolicyCard({required this.policy});

  final PaidServicePolicyData policy;

  @override
  ConsumerState<_PolicyCard> createState() => _PolicyCardState();
}

class _PolicyCardState extends ConsumerState<_PolicyCard> {
  late final TextEditingController _limitController;
  late bool _enabled;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(text: widget.policy.dailyLimit.toString());
    _enabled = widget.policy.enabled;
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = int.tryParse(_limitController.text.trim());
    if (value == null || value < 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('일일 한도는 0 이상 정수로 입력해 주세요.')),
        );
      }
      return;
    }

    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.updatePaidServicePolicy(
        serviceKey: widget.policy.serviceKey,
        displayName: widget.policy.displayName,
        dailyLimit: value,
        enabled: _enabled,
      );
      ref.invalidate(paidServicePoliciesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.policy.serviceKey} 정책을 저장했습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('정책 저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final policy = widget.policy;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF101E3E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2D4F8C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  policy.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Switch.adaptive(
                value: _enabled,
                onChanged: _saving ? null : (value) => setState(() => _enabled = value),
              ),
            ],
          ),
          Text(
            policy.serviceKey,
            style: const TextStyle(color: Color(0xFF98A9CF), fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _limitController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '일일 최대 호출수',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving ? const Text('저장 중...') : const Text('저장'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '오늘 사용 ${policy.usedToday}회 / 잔여 ${policy.remainingToday}회',
            style: const TextStyle(color: Color(0xFFB8C9F1), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _UserRoleCard extends ConsumerStatefulWidget {
  const _UserRoleCard({required this.user});

  final AdminUserData user;

  @override
  ConsumerState<_UserRoleCard> createState() => _UserRoleCardState();
}

class _UserRoleCardState extends ConsumerState<_UserRoleCard> {
  late Set<String> _roles;
  bool _saving = false;
  static const _allRoles = ['USER', 'OPERATOR', 'ADMIN'];

  @override
  void initState() {
    super.initState();
    _roles = widget.user.roles.toSet();
  }

  Future<void> _saveRoles() async {
    if (_roles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('역할은 최소 1개 이상 선택해 주세요.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.updateUserRoles(userId: widget.user.userId, roles: _roles.toList()..sort());
      ref.invalidate(adminUsersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.user.loginId} 권한을 저장했습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('권한 저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF101E3E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2D4F8C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('${user.loginId} · ${user.status}', style: const TextStyle(color: Color(0xFF98A9CF), fontSize: 12)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: _allRoles.map((role) {
              final selected = _roles.contains(role);
              return FilterChip(
                selected: selected,
                label: Text(role),
                onSelected: _saving
                    ? null
                    : (value) {
                        setState(() {
                          if (value) {
                            _roles.add(role);
                          } else {
                            _roles.remove(role);
                          }
                        });
                      },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _saving ? null : _saveRoles,
              child: _saving ? const Text('저장 중...') : const Text('권한 저장'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingBox extends StatelessWidget {
  const _LoadingBox();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x22FF6A86),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x66FF6A86)),
      ),
      child: Text(message, style: const TextStyle(color: Color(0xFFFFD8E0))),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x141C2A4F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x333A5A92)),
      ),
      child: Text(message, style: const TextStyle(color: Color(0xFFA5B4D7))),
    );
  }
}
