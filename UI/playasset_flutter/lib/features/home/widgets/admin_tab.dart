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
    final groupsAsync = ref.watch(adminGroupsProvider);

    return DefaultTabController(
      length: 4,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(paidServicePoliciesProvider);
          ref.invalidate(adminUsersProvider);
          ref.invalidate(adminGroupsProvider);
          ref.invalidate(runtimeConfigsProvider);
          await Future.wait([
            ref.read(paidServicePoliciesProvider.future),
            ref.read(adminUsersProvider.future),
            ref.read(adminGroupsProvider.future),
            ref.read(runtimeConfigsProvider('ADVISOR_RULE').future),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            const Text(
              '관리자 센터',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              '유료 호출 정책, 권한 그룹, 사용자 권한을 한 곳에서 관리해요.',
              style: TextStyle(fontSize: 13, color: Color(0xFF8A97B3)),
            ),
            const SizedBox(height: 16),
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: '호출 정책'),
                Tab(text: '권한 그룹'),
                Tab(text: '유저 관리'),
                Tab(text: '기준정보'),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 920,
              child: TabBarView(
                children: [
                  _PolicyPane(policyAsync: policyAsync),
                  _GroupPane(groupsAsync: groupsAsync),
                  _UserPane(usersAsync: usersAsync, groupsAsync: groupsAsync),
                  const _RuntimeConfigPane(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuntimeConfigPane extends ConsumerStatefulWidget {
  const _RuntimeConfigPane();

  @override
  ConsumerState<_RuntimeConfigPane> createState() => _RuntimeConfigPaneState();
}

class _RuntimeConfigPaneState extends ConsumerState<_RuntimeConfigPane> {
  static const _groups = [
    'ADVISOR_RULE',
    'ADVISOR_MESSAGE',
    'SIMULATION_MESSAGE',
  ];

  String _group = _groups.first;

  @override
  Widget build(BuildContext context) {
    final configsAsync = ref.watch(runtimeConfigsProvider(_group));
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _groups.map((group) {
              final selected = _group == group;
              return ChoiceChip(
                label: Text(group),
                selected: selected,
                onSelected: (_) => setState(() => _group = group),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: configsAsync.when(
            data: (configs) {
              if (configs.isEmpty) {
                return const _EmptyBox(message: '기준정보 데이터가 없습니다.');
              }
              return ListView.builder(
                itemCount: configs.length,
                itemBuilder: (context, index) => _RuntimeConfigCard(
                  groupCode: _group,
                  config: configs[index],
                ),
              );
            },
            loading: () => const _LoadingBox(),
            error: (e, _) => _ErrorBox(message: '기준정보 조회 실패: $e'),
          ),
        ),
      ],
    );
  }
}

class _RuntimeConfigCard extends ConsumerStatefulWidget {
  const _RuntimeConfigCard({
    required this.groupCode,
    required this.config,
  });

  final String groupCode;
  final RuntimeConfigData config;

  @override
  ConsumerState<_RuntimeConfigCard> createState() => _RuntimeConfigCardState();
}

class _RuntimeConfigCardState extends ConsumerState<_RuntimeConfigCard> {
  late final TextEditingController _nameController;
  late final TextEditingController _valueController;
  late final TextEditingController _descController;
  late String _valueTypeCd;
  late bool _enabled;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.config.configName);
    _valueController = TextEditingController(text: widget.config.configValue);
    _descController = TextEditingController(text: widget.config.configDesc);
    _valueTypeCd = widget.config.valueTypeCd;
    _enabled = widget.config.enabled;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!widget.config.editable) {
      return;
    }
    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.updateRuntimeConfig(
        groupCode: widget.groupCode,
        configKey: widget.config.configKey,
        configName: _nameController.text.trim(),
        valueTypeCd: _valueTypeCd,
        configValue: _valueController.text.trim(),
        configDesc: _descController.text.trim(),
        enabled: _enabled,
      );
      ref.invalidate(runtimeConfigsProvider(widget.groupCode));
      ref.invalidate(advisorProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.config.configKey} 값을 저장했어요.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('기준정보 저장 실패: $e')),
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
    final editable = widget.config.editable;
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
                  widget.config.configKey,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (!editable)
                const Text('읽기전용', style: TextStyle(color: Color(0xFFFFA3AE))),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: _enabled,
                onChanged: !editable || _saving
                    ? null
                    : (value) => setState(() => _enabled = value),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            enabled: editable && !_saving,
            decoration: const InputDecoration(
              labelText: '설정명',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _valueController,
                  enabled: editable && !_saving,
                  decoration: const InputDecoration(
                    labelText: '값',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: _valueTypeCd,
                  decoration: const InputDecoration(
                    labelText: '타입',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: const ['STRING', 'NUMBER', 'BOOLEAN', 'JSON']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: !editable || _saving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _valueTypeCd = value);
                          }
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descController,
            enabled: editable && !_saving,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: '설명',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: !editable || _saving ? null : _save,
              child: _saving ? const Text('저장 중...') : const Text('기준정보 저장'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyPane extends StatelessWidget {
  const _PolicyPane({required this.policyAsync});

  final AsyncValue<List<PaidServicePolicyData>> policyAsync;

  @override
  Widget build(BuildContext context) {
    return policyAsync.when(
      data: (list) {
        if (list.isEmpty) {
          return const _EmptyBox(message: '정책 데이터가 없습니다.');
        }
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) => _PolicyCard(policy: list[index]),
        );
      },
      loading: () => const _LoadingBox(),
      error: (e, _) => _ErrorBox(message: '정책 조회 실패: $e'),
    );
  }
}

class _GroupPane extends StatelessWidget {
  const _GroupPane({required this.groupsAsync});

  final AsyncValue<List<AdminGroupData>> groupsAsync;

  @override
  Widget build(BuildContext context) {
    return groupsAsync.when(
      data: (groups) {
        if (groups.isEmpty) {
          return const _EmptyBox(message: '권한 그룹 데이터가 없습니다.');
        }
        return ListView.builder(
          itemCount: groups.length,
          itemBuilder: (context, index) =>
              _GroupPermissionCard(group: groups[index]),
        );
      },
      loading: () => const _LoadingBox(),
      error: (e, _) => _ErrorBox(message: '권한 그룹 조회 실패: $e'),
    );
  }
}

class _UserPane extends StatelessWidget {
  const _UserPane({required this.usersAsync, required this.groupsAsync});

  final AsyncValue<List<AdminUserData>> usersAsync;
  final AsyncValue<List<AdminGroupData>> groupsAsync;

  @override
  Widget build(BuildContext context) {
    return groupsAsync.when(
      data: (groups) => usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const _EmptyBox(message: '사용자 데이터가 없습니다.');
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) => _UserManageCard(
              user: users[index],
              groups: groups,
            ),
          );
        },
        loading: () => const _LoadingBox(),
        error: (e, _) => _ErrorBox(message: '사용자 조회 실패: $e'),
      ),
      loading: () => const _LoadingBox(),
      error: (e, _) => _ErrorBox(message: '권한 그룹 조회 실패: $e'),
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
    _limitController =
        TextEditingController(text: widget.policy.dailyLimit.toString());
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
          const SnackBar(content: Text('일일 한도는 0 이상의 정수로 입력해 주세요.')),
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
          SnackBar(content: Text('${widget.policy.serviceKey} 정책을 저장했어요.')),
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
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _enabled = value),
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
                    labelText: '일일 최대 호출 수',
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
            '오늘 사용 ${policy.usedToday}건 / 잔여 ${policy.remainingToday}건',
            style: const TextStyle(color: Color(0xFFB8C9F1), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _GroupPermissionCard extends ConsumerStatefulWidget {
  const _GroupPermissionCard({required this.group});

  final AdminGroupData group;

  @override
  ConsumerState<_GroupPermissionCard> createState() =>
      _GroupPermissionCardState();
}

class _GroupPermissionCardState extends ConsumerState<_GroupPermissionCard> {
  static const _allPermissions = ['USER', 'OPERATOR', 'ADMIN'];

  late Set<String> _permissions;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _permissions = widget.group.permissions.toSet();
  }

  Future<void> _save() async {
    if (_permissions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소 1개 이상의 권한을 선택해 주세요.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.updateGroupPermissions(
        groupId: widget.group.groupId,
        permissions: _permissions.toList()..sort(),
      );
      ref.invalidate(adminGroupsProvider);
      ref.invalidate(adminUsersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.group.groupName} 권한을 저장했어요.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('권한 그룹 저장 실패: $e')),
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
    final group = widget.group;

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
                  group.groupName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                group.enabled ? '활성' : '비활성',
                style: TextStyle(
                  color: group.enabled
                      ? const Color(0xFF8CF0CA)
                      : const Color(0xFFFFA3AE),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${group.groupKey} · 멤버 ${group.memberCount}명',
            style: const TextStyle(color: Color(0xFF98A9CF), fontSize: 12),
          ),
          if (group.groupDesc.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              group.groupDesc,
              style: const TextStyle(color: Color(0xFFBED0F0), fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: _allPermissions.map((permission) {
              final selected = _permissions.contains(permission);
              return FilterChip(
                selected: selected,
                label: Text(permission),
                onSelected: _saving
                    ? null
                    : (value) {
                        setState(() {
                          if (value) {
                            _permissions.add(permission);
                          } else {
                            _permissions.remove(permission);
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
              onPressed: _saving ? null : _save,
              child: _saving ? const Text('저장 중...') : const Text('권한 저장'),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserManageCard extends ConsumerStatefulWidget {
  const _UserManageCard({required this.user, required this.groups});

  final AdminUserData user;
  final List<AdminGroupData> groups;

  @override
  ConsumerState<_UserManageCard> createState() => _UserManageCardState();
}

class _UserManageCardState extends ConsumerState<_UserManageCard> {
  static const _allRoles = ['USER', 'OPERATOR', 'ADMIN'];

  late Set<String> _roles;
  int? _groupId;
  bool _savingRoles = false;
  bool _savingGroup = false;

  @override
  void initState() {
    super.initState();
    _roles = widget.user.roles.toSet();
    _groupId = widget.user.groupId;
  }

  Future<void> _saveRoles() async {
    if (_roles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('역할은 최소 1개 이상 선택해 주세요.')),
      );
      return;
    }
    setState(() => _savingRoles = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.updateUserRoles(
          userId: widget.user.userId, roles: _roles.toList()..sort());
      ref.invalidate(adminUsersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.user.loginId} 역할을 저장했어요.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('역할 저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingRoles = false);
      }
    }
  }

  Future<void> _saveGroup() async {
    if (_groupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('권한 그룹을 선택해 주세요.')),
      );
      return;
    }
    setState(() => _savingGroup = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.updateUserGroup(userId: widget.user.userId, groupId: _groupId!);
      ref.invalidate(adminUsersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.user.loginId} 그룹을 저장했어요.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('그룹 저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingGroup = false);
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
          Text(user.displayName,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            '${user.loginId} · ${user.status}',
            style: const TextStyle(color: Color(0xFF98A9CF), fontSize: 12),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            initialValue: _groupId,
            items: widget.groups
                .map(
                  (group) => DropdownMenuItem<int>(
                    value: group.groupId,
                    child: Text('${group.groupName} (${group.groupKey})'),
                  ),
                )
                .toList(),
            onChanged: _savingGroup
                ? null
                : (value) => setState(() => _groupId = value),
            decoration: const InputDecoration(
              labelText: '권한 그룹',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: _savingGroup ? null : _saveGroup,
              child: _savingGroup ? const Text('저장 중...') : const Text('그룹 저장'),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: _allRoles.map((role) {
              final selected = _roles.contains(role);
              return FilterChip(
                selected: selected,
                label: Text(role),
                onSelected: _savingRoles
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
              onPressed: _savingRoles ? null : _saveRoles,
              child: _savingRoles ? const Text('저장 중...') : const Text('역할 저장'),
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
