import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

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
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
          children: [
            Text(
              '관리자 센터',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            const _TransactionUploadCard(),
            const SizedBox(height: 12),
            TabBar(
              isScrollable: true,
              labelColor: _adminTitleText(context),
              unselectedLabelColor: _adminMutedText(context),
              indicatorColor: _adminPrimaryAccent(context),
              tabs: [
                Tab(text: '호출 정책'),
                Tab(text: '권한 그룹'),
                Tab(text: '유저 관리'),
                Tab(text: '기준정보'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: _tabContentHeight(context),
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

class _TransactionUploadCard extends ConsumerStatefulWidget {
  const _TransactionUploadCard();

  @override
  ConsumerState<_TransactionUploadCard> createState() =>
      _TransactionUploadCardState();
}

class _TransactionUploadCardState
    extends ConsumerState<_TransactionUploadCard> {
  final _userIdController = TextEditingController();
  PlatformFile? _picked;
  bool _uploading = false;
  TransactionImportResultData? _result;

  @override
  void initState() {
    super.initState();
    final uid = ref.read(sessionControllerProvider).userId;
    if (uid != null) {
      _userIdController.text = uid.toString();
    }
  }

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      withData: true,
    );
    if (!mounted || result == null || result.files.isEmpty) return;
    setState(() => _picked = result.files.first);
  }

  Future<void> _upload() async {
    final userId = int.tryParse(_userIdController.text.trim());
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('userId를 숫자로 입력하세요.')),
      );
      return;
    }
    final picked = _picked;
    if (picked == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('xlsx 파일을 먼저 선택하세요.')),
      );
      return;
    }
    setState(() => _uploading = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.uploadTransactionExcel(
        userId: userId,
        fileName: picked.name,
        fileBytes: picked.bytes,
        filePath: picked.path,
      );
      ref.invalidate(dashboardProvider);
      ref.invalidate(positionsProvider);
      setState(() => _result = res);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('업로드 완료: ${res.importedRows}/${res.totalRows}건 반영')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('업로드 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _adminPanelBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _adminPanelBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '거래 엑셀 업로드 (.xlsx)',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _userIdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'userId',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _uploading ? null : _pickFile,
                icon: const Icon(Icons.attach_file_rounded),
                label: const Text('파일 선택'),
              ),
              FilledButton.icon(
                onPressed: _uploading ? null : _upload,
                icon: _uploading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_rounded),
                label: const Text('업로드'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _picked == null ? '선택된 파일 없음' : _picked!.name,
            style: TextStyle(color: _adminMutedText(context), fontSize: 12),
          ),
          if (_result != null) ...[
            const SizedBox(height: 8),
            Text(
              '결과: 총 ${_result!.totalRows}건 / 성공 ${_result!.importedRows}건 / 실패 ${_result!.failedRows}건',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            if (_result!.errors.isNotEmpty) ...[
              const SizedBox(height: 6),
              ..._result!.errors.take(5).map((e) => Text(
                    '- $e',
                    style: TextStyle(
                        color: _adminMutedText(context), fontSize: 11),
                  )),
            ],
          ],
        ],
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
        color: _adminPanelBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _adminPanelBorder(context)),
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
                Text(
                  '읽기전용',
                  style: TextStyle(color: _adminDanger(context)),
                ),
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
        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            if (!wide) {
              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, index) =>
                    _PolicyCard(policy: list[index]),
              );
            }
            return _PolicyTable(policyList: list);
          },
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
        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            if (!wide) {
              return ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, index) =>
                    _GroupPermissionCard(group: groups[index]),
              );
            }
            return _GroupTable(groups: groups);
          },
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
          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              if (!wide) {
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) => _UserManageCard(
                    user: users[index],
                    groups: groups,
                  ),
                );
              }
              return _UserTable(users: users, groups: groups);
            },
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

class _PolicyTable extends StatelessWidget {
  const _PolicyTable({required this.policyList});

  final List<PaidServicePolicyData> policyList;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 980),
          child: DataTable(
            headingRowHeight: 40,
            dataRowMinHeight: 48,
            dataRowMaxHeight: 56,
            columns: const [
              DataColumn(label: Text('서비스')),
              DataColumn(label: Text('키')),
              DataColumn(label: Text('일일한도')),
              DataColumn(label: Text('사용/잔여')),
              DataColumn(label: Text('상태')),
              DataColumn(label: Text('관리')),
            ],
            rows: policyList.map((policy) {
              return DataRow(
                cells: [
                  DataCell(Text(policy.displayName)),
                  DataCell(Text(policy.serviceKey)),
                  DataCell(Text('${policy.dailyLimit}')),
                  DataCell(
                      Text('${policy.usedToday} / ${policy.remainingToday}')),
                  DataCell(Text(policy.enabled ? '활성' : '비활성')),
                  DataCell(
                    TextButton(
                      onPressed: () => _openEditor(context, policy),
                      child: const Text('편집'),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, PaidServicePolicyData policy) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
          child: SingleChildScrollView(
            child: _PolicyCard(policy: policy),
          ),
        ),
      ),
    );
  }
}

class _GroupTable extends StatelessWidget {
  const _GroupTable({required this.groups});

  final List<AdminGroupData> groups;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 980),
          child: DataTable(
            headingRowHeight: 40,
            dataRowMinHeight: 50,
            dataRowMaxHeight: 60,
            columns: const [
              DataColumn(label: Text('그룹키')),
              DataColumn(label: Text('그룹명')),
              DataColumn(label: Text('멤버')),
              DataColumn(label: Text('권한')),
              DataColumn(label: Text('상태')),
              DataColumn(label: Text('관리')),
            ],
            rows: groups.map((group) {
              return DataRow(
                cells: [
                  DataCell(Text(group.groupKey)),
                  DataCell(Text(group.groupName)),
                  DataCell(Text('${group.memberCount}')),
                  DataCell(Text(group.permissions.join(', '))),
                  DataCell(Text(group.enabled ? '활성' : '비활성')),
                  DataCell(
                    TextButton(
                      onPressed: () => _openEditor(context, group),
                      child: const Text('편집'),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, AdminGroupData group) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
          child: SingleChildScrollView(
            child: _GroupPermissionCard(group: group),
          ),
        ),
      ),
    );
  }
}

class _UserTable extends StatelessWidget {
  const _UserTable({
    required this.users,
    required this.groups,
  });

  final List<AdminUserData> users;
  final List<AdminGroupData> groups;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 1080),
          child: DataTable(
            headingRowHeight: 40,
            dataRowMinHeight: 52,
            dataRowMaxHeight: 62,
            columns: const [
              DataColumn(label: Text('로그인ID')),
              DataColumn(label: Text('이름')),
              DataColumn(label: Text('상태')),
              DataColumn(label: Text('그룹')),
              DataColumn(label: Text('역할')),
              DataColumn(label: Text('관리')),
            ],
            rows: users.map((user) {
              return DataRow(
                cells: [
                  DataCell(Text(user.loginId)),
                  DataCell(Text(user.displayName)),
                  DataCell(Text(user.status)),
                  DataCell(Text(user.groupName ?? '-')),
                  DataCell(Text(user.roles.join(', '))),
                  DataCell(
                    TextButton(
                      onPressed: () => _openEditor(context, user),
                      child: const Text('편집'),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, AdminUserData user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
          child: SingleChildScrollView(
            child: _UserManageCard(user: user, groups: groups),
          ),
        ),
      ),
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
        color: _adminPanelBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _adminPanelBorder(context)),
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
            style: TextStyle(color: _adminMutedText(context), fontSize: 12),
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
            style: TextStyle(color: _adminBodyText(context), fontSize: 12),
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
        color: _adminPanelBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _adminPanelBorder(context)),
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
                      ? _adminSuccess(context)
                      : _adminDanger(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${group.groupKey} · 멤버 ${group.memberCount}명',
            style: TextStyle(color: _adminMutedText(context), fontSize: 12),
          ),
          if (group.groupDesc.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              group.groupDesc,
              style: TextStyle(color: _adminBodyText(context), fontSize: 12),
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
        color: _adminPanelBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _adminPanelBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.displayName,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            '${user.loginId} · ${user.status}',
            style: TextStyle(color: _adminMutedText(context), fontSize: 12),
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
    final isDark = _isDarkMode(context);
    final bg = isDark ? const Color(0x22FF6A86) : const Color(0x1FF74F6A);
    final border = isDark ? const Color(0x66FF6A86) : const Color(0x66F15B74);
    final text = isDark ? const Color(0xFFFFD8E0) : const Color(0xFF992B3F);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(message, style: TextStyle(color: text)),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode(context);
    final bg = isDark ? const Color(0x141C2A4F) : const Color(0xFFEAF3FF);
    final border = isDark ? const Color(0x333A5A92) : const Color(0xFFCDDDF7);
    final text = isDark ? const Color(0xFFA5B4D7) : const Color(0xFF4A6386);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(message, style: TextStyle(color: text)),
    );
  }
}

bool _isDarkMode(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _adminPanelBg(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF101E3E) : const Color(0xFFF7FBFF);

Color _adminPanelBorder(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF2D4F8C) : const Color(0xFFCADBF7);

Color _adminTitleText(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFFF3F6FF) : const Color(0xFF12243F);

Color _adminBodyText(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFFC7D7F3) : const Color(0xFF223A58);

Color _adminMutedText(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF8FA6CF) : const Color(0xFF355575);

Color _adminPrimaryAccent(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF5CA8FF) : const Color(0xFF3F77C7);

Color _adminSuccess(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF8CF0CA) : const Color(0xFF168A60);

Color _adminDanger(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFFFFA3AE) : const Color(0xFFB9354A);

double _tabContentHeight(BuildContext context) {
  final screen = MediaQuery.of(context).size.height;
  final candidate = screen - 250;
  return candidate.clamp(520.0, 1200.0);
}
